require "test_helper"
require_relative "../../db/seeds/techniques"

class TechniqueSeedTest < ActiveSupport::TestCase
  test "catalog is repeatable and preserves curated content" do
    technique = techniques(:shake)
    technique.update!(description: "Curated description")
    TechniquesSeeder.seed!
    assert_equal 17, Technique.count
    assert Technique.all.all?(&:valid?)
    counts = [ Technique.count, RecipeTechnique.count ]
    TechniquesSeeder.seed!
    assert_equal counts, [ Technique.count, RecipeTechnique.count ]
    assert_equal "Curated description", technique.reload.description
    technique.update!(tip: nil)
    TechniquesSeeder.seed!
    assert_equal JSON.parse(TechniquesSeeder::ROOT.join("catalog.json").read).first.fetch("tip"), technique.reload.tip
  end

  test "reviewed links apply only to untouched system imports and preserve assignments" do
    drink = JSON.parse(Rails.root.join("db/seeds/thecocktaildb/cocktails.json").read).fetch("drinks").find { |entry| entry["strDrink"] == "Daiquiri" }
    recipe = recipes(:one)
    recipe.update!(user: users(:shakestir), source_url: "https://www.thecocktaildb.com/drink/#{drink.fetch("idDrink")}")
    recipe.recipe_steps.sole.update!(body: drink.fetch("strInstructions").strip)
    TechniquesSeeder.seed!
    assert_equal %w[shake strain], recipe.techniques.pluck(:slug)
    recipe.techniques = [ techniques(:stir) ]
    TechniquesSeeder.seed!
    assert_equal [ "stir" ], recipe.reload.techniques.pluck(:slug)
    recipe.recipe_techniques.destroy_all
    recipe.update!(user: users(:one))
    TechniquesSeeder.seed!
    assert_empty recipe.reload.techniques
    recipe.update!(user: users(:shakestir))
    recipe.recipe_steps.sole.update!(body: "A curated preparation.")
    TechniquesSeeder.seed!
    assert_empty recipe.reload.techniques
  end
end
