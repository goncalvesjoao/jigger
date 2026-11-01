module RecipesHelper
  def matching_recipe_count(identity, recipes)
    identity.is_a?(Cocktail) ? recipes.count { |recipe| !recipe.official? } : recipes.size
  end
end
