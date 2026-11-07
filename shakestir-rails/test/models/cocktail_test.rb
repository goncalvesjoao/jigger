require "test_helper"

class CocktailTest < ActiveSupport::TestCase
  test "canonical identity has names and history independent of recipes" do
    cocktail = Cocktail.create!(name: "Margarita", history: "A classic sour")
    cocktail.update!(name: "マルガリータ")
    recipe = recipes(:one)
    submitted_name = recipe.name
    recipe.update!(cocktail: cocktail)
    assert_equal submitted_name, recipe.reload.name
    assert_equal [ cocktail.id ], Cocktail.search("マルガリータ").ids
    assert_equal [ recipe.id ], Recipe.marketplace.search("マルガリータ").ids
    assert_equal "A classic sour", cocktail.reload.history
    assert_not Cocktail.new(name: " ").valid?
  end
  test "variants have optional parents, reject cycles and survive parent deletion" do
    parent = Cocktail.create!(name: "Sidecar")
    child = Cocktail.create!(name: "Boston Sidecar", parent_cocktail: parent)
    assert_equal [ child ], parent.variants.to_a
    parent.parent_cocktail = child
    assert_not parent.valid?
    child.parent_cocktail = child
    assert_not child.valid?
    parent.reload.destroy!
    assert_nil child.reload.parent_cocktail
  end

  test "cocktail source URLs accept only HTTP links" do
    cocktail = Cocktail.new(name: "Margarita", source_url: "javascript:alert(1)")
    assert_not cocktail.valid?
    cocktail.source_url = "https://example.com/history"
    assert cocktail.valid?
  end
end
