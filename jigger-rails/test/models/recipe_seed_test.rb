require "test_helper"

class RecipeSeedTest < ActiveSupport::TestCase
  test "cached imports publish complete system recipes and repeat without duplication or endorsement" do
    load Rails.root.join("db/seeds.rb")
    imported = Recipe.where(source_reference: "TheCocktailDB")
    assert_operator imported.marketplace.count, :>, 0
    assert imported.all? { |recipe| recipe.user_id.nil? && !recipe.official? }
    recipe = imported.marketplace.first
    assert recipe.cocktail.present?
    assert recipe.recipe_steps.any?
    assert recipe.recipe_ingredients.any?
    assert recipe.source_url.start_with?("https://www.thecocktaildb.com/drink/")
    published_at = recipe.published_at
    counts = [ Cocktail.count, Recipe.count, RecipeIngredient.count, RecipeStep.count, ActiveStorage::Attachment.count ]
    TheCocktailDbSeeder.seed!
    assert_equal counts, [ Cocktail.count, Recipe.count, RecipeIngredient.count, RecipeStep.count, ActiveStorage::Attachment.count ]
    assert_equal published_at, recipe.reload.published_at
    recipe.update!(official: true, name: "Curated recipe")
    TheCocktailDbSeeder.seed!
    assert_equal "Curated recipe", recipe.reload.name
  end
end
