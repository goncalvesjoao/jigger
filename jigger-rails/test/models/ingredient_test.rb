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

  test "lookup supports canonical names, translations and ambiguous aliases without changing prose" do
    [ [ Ingredient, ingredients(:one), :ingredient_aliases ],
      [ Utensil, utensils(:jigger), :utensil_aliases ],
      [ Cocktail, cocktails(:margarita), :cocktail_aliases ] ].each do |type, identity, association|
      identity.public_send(association).create!(name: "  ジガー  ", language: "ja")
      other = type.create!(image: photo_upload, name: "Other")
      other.public_send(association).create!(name: "ジガー", language: "ja")
      assert_equal [ identity.id, other.id ].sort, type.lookup("ジガー", language: "ja").ids.sort
      assert_equal [ identity.id ], type.lookup(identity.display_name.upcase, language: "en").ids
      assert_empty type.lookup("ジガー", language: "en")
      Globalize.with_locale(:ja) do
        identity.update!(name: "同じ名前")
        other.update!(name: "同じ名前")
      end
      identity.public_send(association).create!(name: "同じ名前", language: "ja")
      assert_equal [ identity.id, other.id ].sort, type.lookup("同じ名前", language: "ja").ids.sort
      assert_empty type.lookup("同じ名前", language: "en")
      assert_equal "  ジガー  ", identity.public_send(association).find_by!(language: "ja", name: "  ジガー  ").name
      assert_not identity.public_send(association).build(name: "ジガー", language: "ja").valid?
    end
  end
end
