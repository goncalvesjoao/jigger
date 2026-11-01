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
    @recipes = matching_recipes.where(cocktail: @cocktail)
    @filtered = params[:q].present? || params[:makeable] == "1" || Array(params[:ingredient_ids]).reject(&:blank?).any? || Array(params[:utensil_ids]).reject(&:blank?).any?
    if @filtered
      @other_recipes = Recipe.marketplace.where(cocktail: @cocktail)
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

    def matching_recipes
      recipes = if params[:makeable] == "1"
        Recipe.makeable_with(ingredient_ids: Array(params[:ingredient_ids]).reject(&:blank?), utensil_ids: Array(params[:utensil_ids]).reject(&:blank?))
      else
        Recipe.marketplace
      end
      unless params[:makeable] == "1"
        Array(params[:ingredient_ids]).reject(&:blank?).uniq.each do |id|
          recipes = recipes.where(id: RecipeIngredient.where(ingredient_id: id).select(:recipe_id))
        end
        Array(params[:utensil_ids]).reject(&:blank?).uniq.each do |id|
          recipes = recipes.where(id: RecipeUtensil.where(utensil_id: id).select(:recipe_id))
        end
      end
      recipes.search(params[:q]).with_attached_image.includes(:translations, :recipe_steps)
    end
end
