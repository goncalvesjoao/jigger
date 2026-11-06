class CocktailsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  before_action :set_cocktail, only: :show
  before_action { authorize @cocktail || Cocktail }
  after_action :verify_authorized

  def index
    @pagination = matching_recipes.reorder(published_at: :desc, created_at: :desc, id: :desc)
      .includes(:user, cocktail: [ :translations, { image_attachment: :blob } ])
      .page(params[:page]).per(24)
  end

  def show
    @recipes = matching_recipes.where(cocktail: @cocktail)
    @filtered = params[:q].present? || makeable_filter? || Array(params[:ingredient_ids]).reject(&:blank?).any? || Array(params[:utensil_ids]).reject(&:blank?).any?
    if @filtered
      @other_recipes = Recipe.marketplace.where(cocktail: @cocktail)
        .where.not(id: @recipes.except(:includes, :order).select(:id))
        .with_attached_image.includes(:translations, :user, cocktail: [ :translations, { image_attachment: :blob } ])
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
      recipes.search(params[:q]).with_attached_image.includes(:translations, :recipe_steps, :user, cocktail: [ :translations, { image_attachment: :blob } ])
    end
end
