require "test_helper"

class TasteSeedTest < ActiveSupport::TestCase
  setup { load Rails.root.join("db/seeds.rb") }

  test "every exact imported and demo spec has a distinct documented expectation" do
    entries = TasteEstimatesSeeder.entries
    assert_equal 35, entries.size
    imported = Recipe.where(user: User.shakestir_account, source_reference: "TheCocktailDB")
    assert_equal 30, imported.count
    demo = Recipe.joins(:user).where(users: { email_address: TasteEstimatesSeeder::DEMO_EMAILS })
    assert_equal 5, demo.count
    (imported.to_a + demo.to_a).each do |recipe|
      key = recipe.source_url.presence || "demo:#{recipe.user.email_address}:#{recipe.name}"
      entry = entries.fetch(key)
      assert_equal entry.fetch("spec_fingerprint"), TasteEstimatesSeeder.fingerprint(recipe), recipe.name
      TasteEstimatesSeeder::FIELDS.each { |field| assert_equal entry.fetch(field), recipe[field], "#{recipe.name}: #{field}" }
      assert entry.fetch("rationale").present?
    end
    assert_operator imported.find_by!(name: "Negroni").bitterness, :>, imported.find_by!(name: "French Negroni").bitterness
    assert_operator imported.find_by!(name: "Whitecap Margarita").sweetness, :>, imported.find_by!(name: "Pina Colada").sweetness
    assert_equal 0, imported.find_by!(name: "Old Fashioned").sourness
  end

  test "reruns fill missing values without overwriting zeroes partial curation content or timestamps" do
    imported = Recipe.find_by!(source_url: "https://www.thecocktaildb.com/drink/11003")
    demo = User.find_by!(email_address: "leo@shakestir.example").recipes.find_by!(name: "Midnight Velvet")
    [ imported, demo ].each { |recipe| recipe.update!(sweetness: 0, sourness: nil, bitterness: 4) }
    snapshot = [ imported, demo ].map { |r| [ r.name, r.steps, r.recipe_ingredients.pluck(:submitted_text), r.source_reference, r.source_url, r.published_at, r.updated_at ] }
    counts = [ Recipe.count, RecipeIngredient.count, RecipeStep.count ]
    TheCocktailDbSeeder.seed!
    DemoAccountsSeeder.seed!
    [ imported, demo ].each do |recipe|
      assert_equal 0, recipe.reload.sweetness
      assert_equal 0, recipe.sourness
      assert_equal 4, recipe.bitterness
    end
    assert_equal snapshot, [ imported, demo ].map { |r| [ r.name, r.steps, r.recipe_ingredients.pluck(:submitted_text), r.source_reference, r.source_url, r.published_at, r.updated_at ] }
    assert_equal counts, [ Recipe.count, RecipeIngredient.count, RecipeStep.count ]
    before = [ imported, demo ].map(&:attributes)
    TheCocktailDbSeeder.seed!
    DemoAccountsSeeder.seed!
    assert_equal before, [ imported, demo ].map { |r| r.reload.attributes }
  end

  test "changed preparations and requirement quantities do not receive stale estimates" do
    recipe = Recipe.find_by!(source_url: "https://www.thecocktaildb.com/drink/11007")
    recipe.update!(sweetness: nil, sourness: nil, bitterness: nil)
    recipe.recipe_ingredients.first.update!(quantity: 99, measuring_unit: "ml")
    TheCocktailDbSeeder.seed!
    assert_nil recipe.reload.sweetness
    assert_nil recipe.sourness
    demo = User.find_by!(email_address: "alex@shakestir.example").recipes.find_by!(name: "My Weekend Margarita")
    demo.update!(sweetness: nil, sourness: nil, bitterness: nil)
    demo.recipe_steps.first.update!(body: "An edited preparation.")
    DemoAccountsSeeder.seed!
    assert_nil demo.reload.sweetness
    assert_nil demo.bitterness
  end

  test "reassigned imported and demo recipes and unrelated source identities remain untouched" do
    imported = Recipe.find_by!(source_url: "https://www.thecocktaildb.com/drink/12198")
    demo = User.find_by!(email_address: "leo@shakestir.example").recipes.find_by!(name: "Ruby Masquerade")
    [ imported, demo ].each { |recipe| recipe.update!(user: users(:one), sweetness: nil, sourness: nil, bitterness: nil) }
    unrelated = users(:one).recipes.create!(name: "Negroni", source_url: "https://example.com/my-negroni")
    before = [ imported, demo, unrelated ].map(&:attributes)
    TheCocktailDbSeeder.seed!
    DemoAccountsSeeder.seed!
    assert_equal before, [ imported, demo, unrelated ].map { |r| r.reload.attributes }
  end
end
