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

  test "lookup supports normalized translated names without changing prose" do
    [ [ Ingredient, ingredients(:one) ], [ Utensil, utensils(:jigger) ], [ Recipe, recipes(:margarita) ] ].each do |type, identity|
      original_name = identity.display_name
      attributes = { image: photo_upload, name: "Other" }
      attributes[:user] = users(:one) if type == Recipe
      other = type.create!(attributes)
      assert_equal [ identity.id ], type.lookup(original_name.upcase, language: "en").ids
      assert_empty type.lookup("ジガー", language: "ja")
      Globalize.with_locale(:ja) do
        identity.update!(name: "  ジガー  ")
        other.update!(name: "ジガー")
      end
      assert_equal [ identity.id, other.id ].sort, type.lookup("ジガー", language: "ja").ids.sort
      assert_empty type.lookup("ジガー", language: "en")
      assert_equal original_name, identity.reload.display_name
      assert_equal "  ジガー  ", identity.translations.find_by!(locale: "ja").name
    end
  end
end
