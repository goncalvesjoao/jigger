require "test_helper"

class IngredientTest < ActiveSupport::TestCase
  test "lookup supports canonical names, translations and ambiguous aliases without changing prose" do
    [ [ Ingredient, ingredients(:one), :ingredient_aliases ],
      [ Utensil, utensils(:jigger), :utensil_aliases ],
      [ Cocktail, cocktails(:margarita), :cocktail_aliases ] ].each do |type, identity, association|
      identity.public_send(association).create!(name: "  ジガー  ", language: "ja")
      other = type.create!(name: "Other")
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
