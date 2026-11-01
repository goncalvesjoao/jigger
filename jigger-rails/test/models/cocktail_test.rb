require "test_helper"

class CocktailTest < ActiveSupport::TestCase
  test "basic drafts stay editable with safe defaults" do
    recipe = Cocktail.create!(user: users(:one), name: "My draft", steps: "  Mix gently.\n冷やす。 ")
    assert_equal "private", recipe.visibility
    assert_equal "draft", recipe.publication_state
    assert_equal "und", recipe.language
    assert_equal "  Mix gently.\n冷やす。 ", recipe.reload.steps
    assert_not recipe.update(publication_state: "published")
    assert recipe.reload.update(steps: "Changed")
    assert_equal "Changed", recipe.reload.recipe_steps.sole.body
  end

  test "description servings preparation method and source reference are persisted with constraints" do
    recipe = cocktails(:one)
    assert recipe.update(
      description: "A brighter split-base variation.",
      servings: 2,
      preparation_method: :shaken,
      source_reference: "Difford's Guide"
    )
    recipe.reload
    assert_equal "A brighter split-base variation.", recipe.description
    assert_equal 2, recipe.servings
    assert_equal "shaken", recipe.preparation_method
    assert_equal "Difford's Guide", recipe.source_reference
    assert_not recipe.update(servings: 0)
  end

  test "required ingredients and utensils must be available while optional ingredients may be missing" do
    recipe = cocktails(:one)
    ingredient = ingredients(:one)
    utensil = utensils(:jigger)
    recipe.cocktail_ingredients.create!(ingredient: ingredient, submitted_text: "gin garnish", language: "en")
    recipe.cocktail_ingredients.create!(ingredient: ingredients(:two), submitted_text: "ice", language: "en", optional: true)
    assert_not_includes Cocktail.makeable_with(ingredient_ids: [ ingredients(:two).id ], utensil_ids: [ utensil.id ]), recipe
    assert_not_includes Cocktail.makeable_with(ingredient_ids: Ingredient.ids, utensil_ids: []), recipe
    assert_includes Cocktail.makeable_with(ingredient_ids: [ ingredient.id ], utensil_ids: [ utensil.id ]), recipe
    assert_includes Cocktail.makeable_with(ingredient_ids: Ingredient.ids * 2, utensil_ids: Utensil.ids * 2), recipe
    assert_empty Cocktail.makeable_with(ingredient_ids: [], utensil_ids: [])
    assert_includes Cocktail.makeable_with(ingredient_ids: Ingredient.ids, utensil_ids: Utensil.ids), cocktails(:two)
  end

  test "only public published complete recipes qualify" do
    recipe = cocktails(:one)
    query = -> { Cocktail.makeable_with(ingredient_ids: Ingredient.ids, utensil_ids: Utensil.ids) }
    assert_includes query.call, recipe
    recipe.update!(visibility: "private")
    assert_not_includes query.call, recipe
    recipe.update!(visibility: "public", publication_state: "draft")
    assert_not_includes query.call, recipe
    recipe.update!(publication_state: "published")
    recipe.cocktail_ingredients.destroy_all
    assert_not_includes query.call, recipe
    assert_not recipe.marketplace?
    assert_not recipe.valid?
  end

  test "steps are ordered and multi-step prose cannot be flattened accidentally" do
    recipe = cocktails(:one)
    recipe.recipe_steps.create!(position: 1, body: "Serve.")
    assert_equal [ "MyText", "Serve." ], recipe.recipe_steps.map(&:body)
    assert_not recipe.update(steps: "Replace everything")
    assert_equal [ "MyText", "Serve." ], recipe.reload.recipe_steps.map(&:body)
  end

  test "database rejects invalid publication and visibility states" do
    assert_raises(ActiveRecord::StatementInvalid) { cocktails(:one).update_columns(visibility: "friends") }
    assert_raises(ActiveRecord::StatementInvalid) { cocktails(:one).update_columns(publication_state: "ready") }
  end
  test "publishing stamps published_at and marketplace is ordered by latest publication first" do
    older = cocktails(:one)
    newer = cocktails(:two)

    older.update!(publication_state: "draft")
    newer.update!(publication_state: "draft")
    older.update!(publication_state: "published")
    travel 1.second do
      newer.update!(publication_state: "published")
    end

    assert_not_nil older.reload.published_at
    assert_not_nil newer.reload.published_at
    assert_operator newer.published_at, :>, older.published_at
    assert_equal newer, Cocktail.marketplace.first
  end
  test "new complete variations publish with structured requirements and steps" do
    recipe = Cocktail.new(user: users(:one), parent_cocktail: cocktails(:margarita), name: "  マイ・マルガリータ ", language: "ja", visibility: "public", publication_state: "published")
    recipe.cocktail_ingredients.build(ingredient: ingredients(:one), submitted_text: "ジン", language: "ja")
    recipe.recipe_steps.build(position: 0, body: "  混ぜる。 ")
    assert recipe.save, recipe.errors.full_messages.join(", ")
    assert_equal "  マイ・マルガリータ ", recipe.reload.name
    assert_includes Cocktail.marketplace, recipe
    assert recipe.marketplace?
    recipe.recipe_steps.destroy_all
    assert_not_includes Cocktail.marketplace, recipe
    assert_not recipe.marketplace?
  end
  test "parent recipes and owned variants share the same model" do
    canonical = cocktails(:margarita)
    variation = cocktails(:one)
    assert_equal canonical, variation.parent_cocktail
    assert_includes canonical.variants, variation
    assert_includes variation.user.cocktails, variation
    assert_equal variation, variation.cocktail_ingredients.sole.cocktail
    assert_equal variation, variation.cocktail_utensils.sole.cocktail
    assert_equal variation, variation.recipe_steps.sole.cocktail
    mention = variation.recipe_steps.sole.step_mentions.create!(ingredient: ingredients(:one), start_offset: 0, end_offset: 2, quoted_text: "My")
    assert_equal variation, mention.cocktail
    alternate = canonical.cocktail_aliases.create!(name: "マルガリータ", language: "ja")
    assert_equal canonical, alternate.cocktail
  end
end

class UnifiedCocktailTest < ActiveSupport::TestCase
  test "ownership endorsement and parentage are independent" do
    recipe = cocktails(:one)
    recipe.update!(user: nil, parent_cocktail: nil, official: true,
      source_reference: "Reference book", source_published_on: "1930-01-01", source_date_note: "Year known; exact day uncertain")
    assert recipe.marketplace?
    assert_includes Cocktail.marketplace, recipe
    assert_nil recipe.user
    assert_nil recipe.parent_cocktail
    assert_equal Date.new(1930, 1, 1), recipe.reload.source_published_on
    recipe.update!(official: false, parent_cocktail: cocktails(:two))
    assert recipe.marketplace?
    assert_not recipe.official?
    assert_not cocktails(:two).update(parent_cocktail: recipe)
    assert_not recipe.update(parent_cocktail: recipe)
  end

  test "localized recipes need no English name or parent and search translations and aliases" do
    recipe = cocktails(:one)
    recipe.update!(parent_cocktail: nil)
    Globalize.with_locale(:ja) { recipe.update!(name: "梅のカクテル") }
    recipe.translations.where(locale: "en").delete_all
    recipe.cocktail_aliases.create!(name: "Plum special", language: "en")
    assert recipe.reload.marketplace?
    assert_equal "梅のカクテル", recipe.display_name
    assert_includes Cocktail.marketplace.search("梅"), recipe
    assert_includes Cocktail.marketplace.search("plum"), recipe
    assert_empty Cocktail.marketplace.search("%")
    recipe.update!(visibility: "private")
    assert_not_includes Cocktail.marketplace.search("plum"), recipe
  end

  test "source URLs only accept HTTP links" do
    assert_not cocktails(:one).update(source_url: "javascript:alert(1)")
    assert cocktails(:one).update(source_url: "https://example.com/recipe")
  end
end
