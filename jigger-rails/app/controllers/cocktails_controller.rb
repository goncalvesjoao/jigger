class CocktailsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  before_action :set_cocktail, only: :show
  before_action { authorize @cocktail || Cocktail }
  after_action :verify_authorized

  def index
    @groups = matching_recipes.includes(cocktail: :translations).group_by { |recipe| recipe.cocktail || recipe }
  end

  def show
    @recipes = matching_recipes.where(cocktail: @cocktail)
  end

  private
    def set_cocktail
      @cocktail = Cocktail.find(params.expect(:id))
    end

    def matching_recipes
      recipes = if params.key?(:ingredient_ids) || params.key?(:utensil_ids)
        Recipe.makeable_with(ingredient_ids: Array(params[:ingredient_ids]).reject(&:blank?), utensil_ids: Array(params[:utensil_ids]).reject(&:blank?))
      else
        Recipe.marketplace
      end
      recipes.search(params[:q]).with_attached_image.includes(:translations, :recipe_steps)
    end
end
