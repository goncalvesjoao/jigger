require "test_helper"

class ReactAuthoringTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "authors create complete published recipes with real requirements and optional taste" do
    post recipes_url(format: :json), params: { recipe: {
      name: "A new pour", visibility: "public", publication_state: "published", sweetness: 2, sourness: 4,
      steps: "Stir gently. Preserve this prose.",
      recipe_ingredients_attributes: [{ ingredient_id: ingredients(:one).id, submitted_text: "45 ml Gin", position: 0 }],
      recipe_utensils_attributes: [{ utensil_id: Utensil.usable.first.id, submitted_text: "Mixing glass" }]
    } }, as: :json
    assert_response :created
    data = response.parsed_body
    recipe = Recipe.find(data.fetch("id"))
    assert_equal users(:one), recipe.user
    assert_equal "Stir gently. Preserve this prose.", recipe.steps
    assert_equal "45 ml Gin", data.fetch("recipe_ingredients").first.fetch("submitted_text")
    assert_equal 2, data.fetch("sweetness")
    assert_nil data.fetch("bitterness")
    get recipes_url(format: :json), params: { sweetness: 2, sourness: 4 }
    assert_includes response.parsed_body.fetch("data").pluck("id"), recipe.id
    get recipes_url(format: :json), params: { sweetness: "unknown" }
    assert_not_includes response.parsed_body.fetch("data").pluck("id"), recipe.id
    get recipes_url(format: :json), params: { sweetness: 5 }
    assert_not_includes response.parsed_body.fetch("data").pluck("id"), recipe.id
  end

  test "taste is validated and private recipes never enter taste discovery" do
    recipe = recipes(:one)
    patch recipe_url(recipe, format: :json), params: { recipe: { sweetness: 6 } }, as: :json
    assert_response :unprocessable_content
    assert_nil recipe.reload.sweetness
    patch recipe_url(recipe, format: :json), params: { recipe: { sweetness: 3, visibility: "private" } }, as: :json
    assert_response :success
    get recipes_url(format: :json), params: { sweetness: 3 }
    assert_not_includes response.parsed_body.fetch("data").pluck("id"), recipe.id
    sign_in_as(users(:two))
    patch recipe_url(recipe, format: :json), params: { recipe: { sourness: 3 } }, as: :json
    assert_response :forbidden
  end

  test "nested requirement ownership cannot be crossed and failed edits roll back" do
    recipe = recipes(:one)
    other_line = recipes(:two).recipe_ingredients.first
    patch recipe_url(recipe, format: :json), params: { recipe: { name: "Should roll back", recipe_ingredients_attributes: [{ id: other_line.id, submitted_text: "Hijacked" }] } }, as: :json
    assert_response :not_found
    assert_not_equal "Should roll back", recipe.reload.name
    assert_not_equal "Hijacked", other_line.reload.submitted_text
  end

  test "structured step edits preserve identity and exact prose" do
    recipe = recipes(:one)
    recipe.recipe_steps.create!(position: 7, body: "Finish with zest.")
    step = recipe.recipe_steps.last
    patch recipe_url(recipe, format: :json), params: { recipe: { recipe_steps_attributes: [{ id: step.id, body: "Finish with a twist.", position: 7 }] } }, as: :json
    assert_response :success
    assert_equal "Finish with a twist.", step.reload.body
    assert_equal 7, step.position
  end
  test "published requirements cannot all be destroyed and unknown taste can be cleared" do
    recipe = recipes(:one)
    patch recipe_url(recipe, format: :json), params: { recipe: { recipe_ingredients_attributes: recipe.recipe_ingredients.map { |line| { id: line.id, _destroy: true } } } }, as: :json
    assert_response :unprocessable_content
    assert recipe.reload.recipe_ingredients.any?
    patch recipe_url(recipe, format: :json), params: { recipe: { sweetness: 0 } }, as: :json
    assert_response :success
    assert_equal 0, recipe.reload.sweetness
    patch recipe_url(recipe, format: :json), params: { recipe: { sweetness: nil } }, as: :json
    assert_response :success
    assert_nil recipe.reload.sweetness
    get recipes_url(format: :json), params: { sweetness: ["2"] }
    assert_response :success
  end

end
