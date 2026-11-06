module RecipesHelper
  def recipe_author(recipe)
    "@#{recipe.user.handle}"
  end

  def recipe_heading(recipe)
    "#{recipe_author(recipe)} / #{recipe.display_name.presence || 'Untitled recipe'}"
  end

  def recipe_photo(recipe)
    return recipe if recipe.image.attached?
    cocktail = recipe.cocktail
    cocktail && policy(cocktail).show? && cocktail.image.attached? ? cocktail : recipe
  end
end
