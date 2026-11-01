require "test_helper"

class CocktailTest < ActiveSupport::TestCase
  test "canonical identity has translated names history and aliases independent of recipes" do
    cocktail = Cocktail.create!(name: "Margarita", history: "A classic sour")
    Globalize.with_locale(:ja) { cocktail.update!(name: "マルガリータ") }
    cocktail.cocktail_aliases.create!(name: "Daisy", language: "en")
    recipe = recipes(:one)
    submitted_name = recipe.name
    recipe.update!(cocktail: cocktail)
    assert_equal submitted_name, recipe.reload.name
    assert_equal [ cocktail.id ], Cocktail.search("マルガリータ").ids
    assert_equal [ recipe.id ], Recipe.marketplace.search("daisy").ids
    assert_equal "A classic sour", cocktail.reload.history
    assert_not Cocktail.new(name: " ").valid?
  end
  test "cocktail source URLs accept only HTTP links" do
    cocktail = Cocktail.new(name: "Margarita", source_url: "javascript:alert(1)")
    assert_not cocktail.valid?
    cocktail.source_url = "https://example.com/history"
    assert cocktail.valid?
  end
end
