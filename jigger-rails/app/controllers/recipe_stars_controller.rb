class RecipeStarsController < ApplicationController
  def create
    recipe = Recipe.readable_by(Current.user).find(params[:recipe_id])
    Current.user.favorites_collection.collection_recipes.find_or_create_by!(recipe: recipe)
    redirect_to recipe, notice: "Recipe starred in your private Favorites.", status: :see_other
  end

  def destroy
    recipe = Recipe.readable_by(Current.user).find(params[:recipe_id])
    Current.user.favorites_collection.collection_recipes.find_by(recipe: recipe)&.destroy!
    redirect_to recipe, notice: "Recipe unstarred.", status: :see_other
  end
end
