require "test_helper"

class RecipeTest < ActiveSupport::TestCase
  test "basic drafts stay editable with safe defaults" do
    recipe = Recipe.create!(user: users(:one), name: "My draft", steps: "  Mix gently.\n冷やす。 ")
    assert_equal "private", recipe.visibility
    assert_equal "draft", recipe.publication_state
    assert_equal "und", recipe.language
    assert_equal "  Mix gently.\n冷やす。 ", recipe.reload.steps
    assert_not recipe.update(publication_state: "published")
    assert recipe.reload.update(steps: "Changed")
    assert_equal "Changed", recipe.reload.recipe_steps.sole.body
  end

  test "servings preparation method and source reference are persisted with constraints" do
    recipe = recipes(:one)
    assert recipe.update(
      servings: 2,
      preparation_method: :shaken,
      source_reference: "Difford's Guide"
    )
    recipe.reload
    assert_equal 2, recipe.servings
    assert_equal "shaken", recipe.preparation_method
    assert_equal "Difford's Guide", recipe.source_reference
    assert_not recipe.update(servings: 0)
  end

  test "required ingredients and utensils must be available while optional ingredients may be missing" do
    recipe = recipes(:one)
    ingredient = ingredients(:one)
    utensil = utensils(:jigger)
    recipe.recipe_ingredients.create!(ingredient: ingredient, submitted_text: "gin garnish", language: "en")
    recipe.recipe_ingredients.create!(ingredient: ingredients(:two), submitted_text: "ice", language: "en", optional: true)
    assert_not_includes Recipe.makeable_with(ingredient_ids: [ ingredients(:two).id ], utensil_ids: [ utensil.id ]), recipe
    assert_not_includes Recipe.makeable_with(ingredient_ids: Ingredient.ids, utensil_ids: []), recipe
    assert_includes Recipe.makeable_with(ingredient_ids: [ ingredient.id ], utensil_ids: [ utensil.id ]), recipe
    assert_includes Recipe.makeable_with(ingredient_ids: Ingredient.ids * 2, utensil_ids: Utensil.ids * 2), recipe
    assert_empty Recipe.makeable_with(ingredient_ids: [], utensil_ids: [])
    assert_includes Recipe.makeable_with(ingredient_ids: Ingredient.ids, utensil_ids: Utensil.ids), recipes(:two)
  end

  test "only public published complete recipes qualify" do
    recipe = recipes(:one)
    query = -> { Recipe.makeable_with(ingredient_ids: Ingredient.ids, utensil_ids: Utensil.ids) }
    assert_includes query.call, recipe
    recipe.update!(visibility: "private")
    assert_not_includes query.call, recipe
    recipe.update!(visibility: "public", publication_state: "draft")
    assert_not_includes query.call, recipe
    recipe.update!(publication_state: "published")
    recipe.recipe_ingredients.destroy_all
    assert_not_includes query.call, recipe
    assert_not recipe.marketplace?
    assert_not recipe.valid?
  end

  test "steps are ordered and multi-step prose cannot be flattened accidentally" do
    recipe = recipes(:one)
    recipe.recipe_steps.create!(position: 1, body: "Serve.")
    assert_equal [ "MyText", "Serve." ], recipe.recipe_steps.map(&:body)
    assert_not recipe.update(steps: "Replace everything")
    assert_equal [ "MyText", "Serve." ], recipe.reload.recipe_steps.map(&:body)
  end

  test "database rejects invalid publication and visibility states" do
    assert_raises(ActiveRecord::StatementInvalid) { recipes(:one).update_columns(visibility: "friends") }
    assert_raises(ActiveRecord::StatementInvalid) { recipes(:one).update_columns(publication_state: "ready") }
  end
  test "publishing stamps published_at and marketplace is ordered by latest publication first" do
    older = recipes(:one)
    newer = recipes(:two)

    older.update!(publication_state: "draft")
    newer.update!(publication_state: "draft")
    older.update!(publication_state: "published")
    travel 1.second do
      newer.update!(publication_state: "published")
    end

    assert_not_nil older.reload.published_at
    assert_not_nil newer.reload.published_at
    assert_operator newer.published_at, :>, older.published_at
    assert_equal newer, Recipe.marketplace.first
  end
  test "new complete variations publish with structured requirements and steps" do
    recipe = Recipe.new(user: users(:one), name: "  マイ・マルガリータ ", language: "ja", visibility: "public", publication_state: "published")
    recipe.recipe_ingredients.build(ingredient: ingredients(:one), submitted_text: "ジン", language: "ja")
    recipe.recipe_steps.build(position: 0, body: "  混ぜる。 ")
    assert recipe.save, recipe.errors.full_messages.join(", ")
    assert_equal "  マイ・マルガリータ ", recipe.reload.name
    assert_includes Recipe.marketplace, recipe
    assert recipe.marketplace?
    recipe.recipe_steps.destroy_all
    assert_not_includes Recipe.marketplace, recipe
    assert_not recipe.marketplace?
  end
  test "recipes retain ownership requirements steps and mentions" do
    variation = recipes(:one)
    assert_includes variation.user.recipes, variation
    assert_equal variation, variation.recipe_ingredients.sole.recipe
    assert_equal variation, variation.recipe_utensils.sole.recipe
    assert_equal variation, variation.recipe_steps.sole.recipe
    mention = variation.recipe_steps.sole.step_mentions.create!(ingredient: ingredients(:one), start_offset: 0, end_offset: 2, quoted_text: "My")
    assert_equal variation, mention.recipe
  end
end

class UnifiedRecipeTest < ActiveSupport::TestCase
  test "all recipes require a user in the model and database" do
    recipe = recipes(:one)
    assert_not recipe.update(user: nil)
    assert_includes recipe.errors[:user], "must exist"
    recipe.reload
    assert_raises(ActiveRecord::StatementInvalid) { recipe.update_columns(user_id: nil) }
    assert Recipe.new(user: users(:one)).valid?
    assert Recipe.new(user: users(:jigger)).valid?
    assert_not Recipe.new.valid?
  end

  test "Jigger recipes are owned recipes and multiple preparations can share a cocktail" do
    cocktail = Cocktail.create!(name: "Reference cocktail")
    recipes(:one).update!(user: users(:jigger), cocktail: cocktail)
    recipes(:two).update!(user: users(:jigger), cocktail: cocktail)
    assert_equal 2, Recipe.where(user: users(:jigger), cocktail: cocktail).count
    assert recipes(:two).update(cocktail: nil)
    assert_not recipes(:one).update(user: nil)
    recipes(:one).reload.update!(user: users(:one))
  end

  test "localized recipes need no English name or cocktail assignment and search translations" do
    recipe = recipes(:one)
    Globalize.with_locale(:ja) { recipe.update!(name: "梅のカクテル") }
    recipe.translations.where(locale: "en").delete_all
    assert recipe.reload.marketplace?
    assert_equal "梅のカクテル", recipe.display_name
    assert_includes Recipe.marketplace.search("梅"), recipe
    assert_empty Recipe.marketplace.search("plum")
    assert_empty Recipe.marketplace.search("%")
    recipe.update!(visibility: "private")
    assert_not_includes Recipe.marketplace.search("梅"), recipe
  end

  test "source URLs only accept HTTP links" do
    assert_not recipes(:one).update(source_url: "javascript:alert(1)")
    assert recipes(:one).update(source_url: "https://example.com/recipe")
  end
end
