require "test_helper"
require_relative "../test_helpers/photo_test_helper"

class IngredientTest < ActiveSupport::TestCase
  include PhotoTestHelper

  test "category and alcohol status enums are string-backed and alcohol_by_volume stays in range" do
    ingredient = ingredients(:one)

    ingredient.assign_attributes(category: :spirit, alcohol_status: :alcoholic, alcohol_by_volume: 40.0)
    assert ingredient.valid?, ingredient.errors.full_messages.join(", ")
    assert_equal "spirit", ingredient.category
    assert_equal "alcoholic", ingredient.alcohol_status

    ingredient.alcohol_by_volume = 100.01
    assert_not ingredient.valid?
    assert_includes ingredient.errors[:alcohol_by_volume], "must be less than or equal to 100"

    ingredient.alcohol_by_volume = -0.01
    assert_not ingredient.valid?
    assert_includes ingredient.errors[:alcohol_by_volume], "must be greater than or equal to 0"
  end

  test "lookup normalizes names without changing stored prose" do
    [ [ Ingredient, ingredients(:one) ], [ Utensil, utensils(:jigger) ], [ Recipe, recipes(:margarita) ] ].each do |type, record|
      assert_equal [ record.id ], type.lookup(record.name.upcase).ids
      record.update!(name: "  ジガー  ")
      assert_includes type.lookup("ジガー"), record
      assert_empty type.lookup(" ")
      assert_equal "  ジガー  ", record.reload.name
    end
  end
end
