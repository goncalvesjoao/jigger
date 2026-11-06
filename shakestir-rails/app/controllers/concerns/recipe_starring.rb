module RecipeStarring
  private
    def recipe_star_payload(recipe)
      favorites = Current.user.favorites_collection
      {
        recipe_id: recipe.id,
        starred: favorites.collection_recipes.exists?(recipe: recipe),
        star_count: recipe.reload.stars_count,
        favorites_collection_id: favorites.id
      }
    end
end
