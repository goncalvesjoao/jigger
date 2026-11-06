class RecipeStarsController < ApplicationController
  include RecipeStarring

  def create
    recipe = Recipe.readable_by(Current.user).find(params[:recipe_id])
    Current.user.favorites_collection.collection_recipes.find_or_create_by!(recipe: recipe)
    respond_with_star(recipe, "Recipe starred in your private Favorites.")
  end

  def destroy
    recipe = Recipe.readable_by(Current.user).find(params[:recipe_id])
    Current.user.favorites_collection.collection_recipes.find_by(recipe: recipe)&.destroy!
    respond_with_star(recipe, "Recipe unstarred.")
  end

  private
    def respond_with_star(recipe, message)
      respond_to do |format|
        format.json { render json: recipe_star_payload(recipe) }
        format.html { redirect_back_or_to recipe, allow_other_host: false, notice: message, status: :see_other }
      end
    end
end
