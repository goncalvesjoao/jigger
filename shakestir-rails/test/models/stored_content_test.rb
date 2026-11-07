require "test_helper"
require_relative "../test_helpers/photo_test_helper"

class StoredContentTest < ActiveSupport::TestCase
  include PhotoTestHelper

  test "all content is stored directly and preserves submitted writing" do
    [ Cocktail, Recipe, Ingredient, Utensil, Technique ].each do |type|
      attributes = { name: "  Ｇｉｎ ジン  " }
      attributes[:image] = photo_upload if [ Ingredient, Utensil ].include?(type)
      attributes[:user] = users(:one) if type == Recipe
      attributes.merge!(slug: "test-guide", description: "説明", instructions: "混ぜる。") if type == Technique
      record = type.create!(attributes)
      assert_equal "  Ｇｉｎ ジン  ", record.reload.name
      assert_equal "gin ジン", record.normalized_name
      assert_not_includes type.column_names, "language"
      assert_not record.respond_to?(:translations)
      record.update!(name: "  Novo nome  ")
      assert_equal "  Novo nome  ", record.reload.name
      assert_equal "novo nome", record.normalized_name
    end
  end

  test "catalog name changes preserve authored recipe and requirement text" do
    recipe = recipes(:one)
    ingredient = recipe.recipe_ingredients.sole
    utensil = recipe.recipe_utensils.sole
    submitted = [ recipe.name, ingredient.submitted_text, utensil.submitted_text ]
    ingredient.ingredient.update!(name: "ジン")
    utensil.utensil.update!(name: "計量カップ")
    assert_equal submitted, [ recipe.reload.name, ingredient.reload.submitted_text, utensil.reload.submitted_text ]
    [ RecipeIngredient, RecipeUtensil ].each { |type| assert_not_includes type.column_names, "language" }
  end
end
