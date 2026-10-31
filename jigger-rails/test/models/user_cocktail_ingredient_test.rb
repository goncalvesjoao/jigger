require "test_helper"

class UserCocktailIngredientTest < ActiveSupport::TestCase
  test "ingredient lines retain original spelling and support fractional amounts and repeated identities" do
    recipe = user_cocktails(:one)
    line = recipe.user_cocktail_ingredients.create!(ingredient: ingredients(:one), submitted_text: "  ジンn ", language: "ja", quantity: "0.125", measuring_unit: "oz")
    assert_equal "  ジンn ", line.reload.submitted_text
    assert_equal "ja", line.language
    assert_equal BigDecimal("0.125"), line.quantity
    assert_equal 2, recipe.user_cocktail_ingredients.where(ingredient: ingredients(:one)).count
    assert_not line.update(quantity: -1)
    assert_not line.update(quantity: 1, measuring_unit: nil)
  end

  test "utensil requirements are unique in models and database" do
    row = user_cocktail_utensils(:one)
    duplicate = row.dup
    assert_not duplicate.valid?
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end
end
