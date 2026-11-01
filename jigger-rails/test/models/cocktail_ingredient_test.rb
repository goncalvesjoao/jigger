require "test_helper"

class CocktailIngredientTest < ActiveSupport::TestCase
  test "ingredient lines retain spelling, keep order, and support optional role metadata" do
    recipe = cocktails(:one)
    line = recipe.cocktail_ingredients.create!(
      ingredient: ingredients(:one),
      submitted_text: "  ジンn ",
      language: "ja",
      quantity: "0.125",
      measuring_unit: "oz",
      role: :garnish,
      optional: true,
      preparation_note: "freshly squeezed"
    )
    assert_equal "  ジンn ", line.reload.submitted_text
    assert_equal "ja", line.language
    assert_equal 1, line.position
    assert_equal "garnish", line.role
    assert line.optional
    assert_equal "freshly squeezed", line.preparation_note
    assert_equal BigDecimal("0.125"), line.quantity
    assert_equal 2, recipe.cocktail_ingredients.where(ingredient: ingredients(:one)).count
    assert_not line.update(quantity: -1)
    assert_not line.update(quantity: 1, measuring_unit: nil)
  end

  test "utensil requirements are unique and role distinguishes usage" do
    row = cocktail_utensils(:one)
    assert row.update(role: :serving)
    duplicate = row.dup
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:utensil_id], "has already been taken"
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end
end
