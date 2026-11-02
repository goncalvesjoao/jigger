class CocktailsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  before_action :set_cocktail, only: :show
  before_action { authorize @cocktail || Cocktail }
  after_action :verify_authorized

  def index
    matches = matching_recipes
    @pagination = matches.except(:includes, :order)
      .select("MIN(recipes.id) AS id, recipes.cocktail_id")
      .group(:cocktail_id, Arel.sql("CASE WHEN recipes.cocktail_id IS NULL THEN recipes.id END"))
      .order(Arel.sql("MAX(recipes.published_at) DESC, MAX(recipes.created_at) DESC, MIN(recipes.id) DESC"))
      .page(params[:page]).per(24)
    groups = @pagination.to_a
    cocktail_ids = groups.filter_map(&:cocktail_id)
    standalone_ids = groups.reject(&:cocktail_id).map(&:id)
    @groups = matches.where(cocktail_id: cocktail_ids).or(matches.where(id: standalone_ids))
      .order(id: :desc).includes(cocktail: [ :translations, { image_attachment: :blob } ]).group_by { |recipe| recipe.cocktail || recipe }
    @groups = @groups.sort_by { |identity, _| groups.index { |group| identity.is_a?(Cocktail) ? group.cocktail_id == identity.id : group.cocktail_id.nil? && group.id == identity.id } }.to_h
  end

  def show
    @recipes = matching_recipes.where(cocktail: @cocktail, official: false)
    @official_recipes = Recipe.marketplace.where(cocktail: @cocktail, official: true)
      .with_attached_image.includes(:translations, :recipe_steps).to_a
    ActiveRecord::Associations::Preloader.new(records: @official_recipes, associations: {
      recipe_ingredients: { ingredient: [ :translations, { image_attachment: :blob } ] },
      recipe_utensils: { utensil: [ :translations, { image_attachment: :blob } ] }
    }).call
    @filtered = params[:q].present? || makeable_filter? || Array(params[:ingredient_ids]).reject(&:blank?).any? || Array(params[:utensil_ids]).reject(&:blank?).any?
    if @filtered
      @other_recipes = Recipe.marketplace.where(cocktail: @cocktail, official: false)
        .where.not(id: @recipes.except(:includes, :order).select(:id))
        .with_attached_image.includes(:translations)
      if params.key?(:ingredient_ids) || params.key?(:utensil_ids)
        @available_ingredients = Ingredient.usable.where(id: Array(params[:ingredient_ids]).reject(&:blank?)).includes(:translations)
        @available_utensils = Utensil.usable.where(id: Array(params[:utensil_ids]).reject(&:blank?)).includes(:translations)
      end
    end
  end

  private
    def set_cocktail
      @cocktail = Cocktail.find(params.expect(:id))
    end

    def makeable_filter?
      params[:makeable] == "1" &&
        (Array(params[:ingredient_ids]).reject(&:blank?).any? || Array(params[:utensil_ids]).reject(&:blank?).any?)
    end

    def matching_recipes
      recipes = Recipe.marketplace
      legacy_makeable = makeable_filter?
      { ingredient_ids: [ RecipeIngredient, :ingredient_id, :ingredient_mode ],
        utensil_ids: [ RecipeUtensil, :utensil_id, :utensil_mode ] }.each do |key, (model, column, mode)|
        ids = Array(params[key]).reject(&:blank?).uniq
        only_available = params[mode] == "only" || (!params.key?(mode) && legacy_makeable)
        if only_available && (ids.any? || legacy_makeable)
          missing = model.where.not(column => ids)
          missing = missing.where(optional: false) if model == RecipeIngredient
          recipes = recipes.where.not(id: missing.select(:recipe_id))
        else
          ids.each { |id| recipes = recipes.where(id: model.where(column => id).select(:recipe_id)) }
        end
      end
      recipes.search(params[:q]).with_attached_image.includes(:translations, :recipe_steps)
    end
end
