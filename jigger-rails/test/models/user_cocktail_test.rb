require "test_helper"

class UserCocktailTest < ActiveSupport::TestCase
  test "basic drafts stay editable with safe defaults" do
    recipe = UserCocktail.create!(user: users(:one), name: "My draft", steps: "  Mix gently.\n冷やす。 ")
    assert_equal "private", recipe.visibility
    assert_equal "draft", recipe.publication_state
    assert_equal "und", recipe.language
    assert_equal "  Mix gently.\n冷やす。 ", recipe.reload.steps
    assert_not recipe.update(publication_state: "published")
    assert recipe.reload.update(steps: "Changed")
    assert_equal "Changed", recipe.reload.recipe_steps.sole.body
  end

  test "all requirements must be available and extras and duplicates are harmless" do
    recipe = user_cocktails(:one)
    ingredient = ingredients(:one)
    utensil = utensils(:jigger)
    recipe.user_cocktail_ingredients.create!(ingredient: ingredient, submitted_text: "gin garnish", language: "en")
    recipe.user_cocktail_ingredients.create!(ingredient: ingredients(:two), submitted_text: "ice", language: "en")
    assert_not_includes UserCocktail.makeable_with(ingredient_ids: [ ingredient.id ], utensil_ids: [ utensil.id ]), recipe
    assert_not_includes UserCocktail.makeable_with(ingredient_ids: Ingredient.ids, utensil_ids: []), recipe
    assert_includes UserCocktail.makeable_with(ingredient_ids: Ingredient.ids * 2, utensil_ids: Utensil.ids * 2), recipe
    assert_empty UserCocktail.makeable_with(ingredient_ids: [], utensil_ids: [])
    assert_includes UserCocktail.makeable_with(ingredient_ids: Ingredient.ids, utensil_ids: Utensil.ids), user_cocktails(:two)
  end

  test "only public published complete recipes qualify" do
    recipe = user_cocktails(:one)
    query = -> { UserCocktail.makeable_with(ingredient_ids: Ingredient.ids, utensil_ids: Utensil.ids) }
    assert_includes query.call, recipe
    recipe.update!(visibility: "private")
    assert_not_includes query.call, recipe
    recipe.update!(visibility: "public", publication_state: "draft")
    assert_not_includes query.call, recipe
    recipe.update!(publication_state: "published")
    recipe.user_cocktail_ingredients.destroy_all
    assert_not_includes query.call, recipe
    assert_not recipe.marketplace?
    assert_not recipe.valid?
  end

  test "steps are ordered and multi-step prose cannot be flattened accidentally" do
    recipe = user_cocktails(:one)
    recipe.recipe_steps.create!(position: 1, body: "Serve.")
    assert_equal [ "MyText", "Serve." ], recipe.recipe_steps.map(&:body)
    assert_not recipe.update(steps: "Replace everything")
    assert_equal [ "MyText", "Serve." ], recipe.reload.recipe_steps.map(&:body)
  end

  test "database rejects invalid publication and visibility states" do
    assert_raises(ActiveRecord::StatementInvalid) { user_cocktails(:one).update_columns(visibility: "friends") }
    assert_raises(ActiveRecord::StatementInvalid) { user_cocktails(:one).update_columns(publication_state: "ready") }
  end
  test "new complete variations publish with structured requirements and steps" do
    recipe = UserCocktail.new(user: users(:one), cocktail: cocktails(:margarita), name: "  マイ・マルガリータ ", language: "ja", visibility: "public", publication_state: "published")
    recipe.user_cocktail_ingredients.build(ingredient: ingredients(:one), submitted_text: "ジン", language: "ja")
    recipe.recipe_steps.build(position: 0, body: "  混ぜる。 ")
    assert recipe.save, recipe.errors.full_messages.join(", ")
    assert_equal "  マイ・マルガリータ ", recipe.reload.name
    assert_includes UserCocktail.marketplace, recipe
    assert recipe.marketplace?
    recipe.recipe_steps.destroy_all
    assert_not_includes UserCocktail.marketplace, recipe
    assert_not recipe.marketplace?
  end
  test "canonical cocktail and owned variations have distinct associations" do
    canonical = cocktails(:margarita)
    variation = user_cocktails(:one)
    assert_equal canonical, variation.cocktail
    assert_includes canonical.user_cocktails, variation
    assert_includes variation.user.user_cocktails, variation
    assert_equal variation, variation.user_cocktail_ingredients.sole.user_cocktail
    assert_equal variation, variation.user_cocktail_utensils.sole.user_cocktail
    assert_equal variation, variation.recipe_steps.sole.user_cocktail
    mention = variation.recipe_steps.sole.step_mentions.create!(ingredient: ingredients(:one), start_offset: 0, end_offset: 2, quoted_text: "My")
    assert_equal variation, mention.user_cocktail
    alternate = canonical.cocktail_aliases.create!(name: "マルガリータ", language: "ja")
    assert_equal canonical, alternate.cocktail
  end
end
