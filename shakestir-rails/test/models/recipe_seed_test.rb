require "test_helper"

class RecipeSeedTest < ActiveSupport::TestCase
  test "demo accounts have public signatures and private drafts with repeatable collections" do
    load Rails.root.join("db/seeds.rb")
    bartender = User.find_by!(email_address: "leo@shakestir.example")
    home = User.find_by!(email_address: "alex@shakestir.example")
    [ bartender, home, User.shakestir_account ].each { |user| assert user.image.attached? }
    image_ids = [ bartender, home, User.shakestir_account ].map { |user| user.image.blob_id }
    ProfileImagesSeeder.seed!
    assert_equal image_ids, [ bartender, home, User.shakestir_account ].map { |user| user.reload.image.blob_id }
    assert bartender.authenticate("password")
    assert home.authenticate("password")
    assert_equal 3, bartender.recipes.marketplace.count
    assert_equal 2, home.recipes.count
    assert home.recipes.all? { |recipe| recipe.visibility == "private" && recipe.publication_state == "draft" }
    assert_empty home.recipes.marketplace
    assert home.collections.all? { |collection| collection.visibility == "private" }
    assert_operator home.collections.where.not(name: "Favorites").minimum(:id), :>, 0
    assert home.collections.where.not(name: "Favorites").all? { |collection| collection.recipes.count >= 3 }
    assert bartender.collections.find_by!(name: "Halloween Special").recipes.where(user: users(:shakestir)).exists?
    assert_equal TheCocktailDbSeeder.find_cocktail("Sidecar"), TheCocktailDbSeeder.find_cocktail("Boston Sidecar").parent_cocktail
    counts = [ User.count, Recipe.count, Collection.count, CollectionRecipe.count ]
    DemoAccountsSeeder.seed!
    assert_equal counts, [ User.count, Recipe.count, Collection.count, CollectionRecipe.count ]
  end

  test "cached imports publish complete system recipes and repeat without duplication or overwriting curation" do
    load Rails.root.join("db/seeds.rb")
    imported = Recipe.where(source_reference: "TheCocktailDB")
    assert_operator imported.marketplace.count, :>, 0
    assert imported.all? { |recipe| recipe.user == users(:shakestir) }
    recipe = imported.marketplace.first
    assert recipe.cocktail.present?
    assert imported.all? { |entry| entry.cocktail.image.attached? }
    content = TheCocktailDbSeeder.load_json("canonical_cocktails.json")
    assert_equal TheCocktailDbSeeder.load_json("cocktails.json").fetch("drinks").map { |drink| drink.fetch("strDrink") }.sort, content.keys.sort
    content.each do |name, attributes|
      translation = Cocktail::Translation.find_by!(locale: "en", normalized_name: LookupName.normalize(name))
      assert translation.description.present?, name
      assert translation.history.present?, name
      assert_equal attributes.fetch("description"), translation.description
      assert_equal attributes.fetch("history"), translation.history
      cocktail = translation.globalized_model
      assert_equal attributes.fetch("source_reference"), cocktail.source_reference
      assert_equal attributes.fetch("source_url"), cocktail.source_url
      assert cocktail.source_date_note.present?, name
    end
    assert recipe.cocktail.exclusive_photo?
    assert_not_equal recipe.image.blob.id, recipe.cocktail.image.blob.id
    photo_id = recipe.cocktail.image.blob.id
    assert recipe.recipe_steps.any?
    assert recipe.recipe_ingredients.any?
    assert recipe.source_url.start_with?("https://www.thecocktaildb.com/drink/")
    published_at = recipe.published_at
    counts = [ Cocktail.count, Recipe.count, RecipeIngredient.count, RecipeStep.count, ActiveStorage::Attachment.count ]
    TheCocktailDbSeeder.seed!
    assert_equal counts, [ Cocktail.count, Recipe.count, RecipeIngredient.count, RecipeStep.count, ActiveStorage::Attachment.count ]
    assert_equal published_at, recipe.reload.published_at
    assert_equal photo_id, recipe.cocktail.image.blob.id
    recipe.update!(user: users(:shakestir), name: "Curated recipe")
    TheCocktailDbSeeder.seed!
    assert_equal "Curated recipe", recipe.reload.name
  end

  test "seeds preserve existing imports and leave user owned recipes unchanged" do
    load Rails.root.join("db/seeds.rb")
    imported = Recipe.find_by!(source_url: "https://www.thecocktaildb.com/drink/11007")
    owned = Recipe.find_by!(source_url: "https://www.thecocktaildb.com/drink/12198")
    owned.update!(user: users(:one), name: "Personal variation")

    TheCocktailDbSeeder.seed!
    assert_equal users(:shakestir), imported.reload.user
    assert_equal users(:shakestir).id, imported.user_id
    assert_equal "TheCocktailDB", imported.source_reference
    assert_equal users(:one), owned.reload.user
    assert_equal users(:one), owned.user
    assert_equal "Personal variation", owned.name
  end

  test "canonical content backfills curated imports in English and preserves admin content and citations" do
    load Rails.root.join("db/seeds.rb")
    recipe = Recipe.find_by!(source_url: "https://www.thecocktaildb.com/drink/11007")
    recipe.update!(user: users(:shakestir))
    cocktail = recipe.cocktail
    english = cocktail.translation_for(:en)
    english.update!(description: "Admin description", history: nil)
    Globalize.with_locale(:ja) { cocktail.update!(name: "マルガリータ", description: "日本語の説明", history: "日本語の歴史") }
    cocktail.update!(source_reference: nil, source_url: nil, source_published_on: nil, source_date_note: nil)

    Globalize.with_locale(:ja) { TheCocktailDbSeeder.seed! }
    expected = TheCocktailDbSeeder.load_json("canonical_cocktails.json").fetch("Margarita")
    assert_equal "Admin description", english.reload.description
    assert_equal expected.fetch("history"), english.history
    assert_equal expected.fetch("source_url"), cocktail.reload.source_url
    Globalize.with_locale(:ja) do
      assert_equal "日本語の説明", cocktail.description
      assert_equal "日本語の歴史", cocktail.history
    end

    english.update!(history: "Admin history")
    cocktail.update!(source_reference: "Admin source", source_url: nil, source_date_note: nil)
    TheCocktailDbSeeder.seed_canonical_content!
    assert_equal "Admin history", english.reload.history
    assert_equal "Admin source", cocktail.reload.source_reference
    assert_nil cocktail.source_url
    assert_nil cocktail.source_date_note
  end
end
