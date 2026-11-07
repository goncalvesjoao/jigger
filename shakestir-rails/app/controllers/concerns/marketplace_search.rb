module MarketplaceSearch
  extend ActiveSupport::Concern

  private
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
      recipes.search(params[:q]).with_attached_image.includes(:recipe_steps, :user, cocktail: { image_attachment: :blob })
    end
end
