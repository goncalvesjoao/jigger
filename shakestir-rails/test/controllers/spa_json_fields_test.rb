require "test_helper"
require_relative "../test_helpers/photo_test_helper"

class SpaJsonFieldsTest < ActionDispatch::IntegrationTest
  include PhotoTestHelper

  test "effective photo and own photo remain distinct for cocktail fallback" do
    recipe = recipes(:one)
    cocktail = Cocktail.create!(name: "Photo cocktail", image: photo_upload)
    recipe.update!(cocktail: cocktail)
    get recipe_url(recipe, format: :json)
    assert_equal cocktail_image_url(cocktail, size: :detail), response.parsed_body.fetch("image_url")
    assert_nil response.parsed_body.fetch("own_image_url")
    recipe.update!(image: photo_upload)
    get recipe_url(recipe, format: :json)
    assert_equal recipe_image_url(recipe, size: :detail), response.parsed_body.fetch("own_image_url")
    assert_equal response.parsed_body.fetch("own_image_url"), response.parsed_body.fetch("image_url")
  end

  test "recipe detail preserves ingredient metadata and multiline step boundaries" do
    recipe = recipes(:one)
    recipe.recipe_steps.first.update!(body: "Add gin.\nAdd ice.")
    second = recipe.recipe_steps.create!(position: 1, body: "Stir and strain.")
    get recipe_url(recipe, format: :json)
    assert_response :success
    payload = response.parsed_body
    assert_equal [ "Add gin.\nAdd ice.", second.body ], payload.fetch("recipe_steps").pluck("body")
    assert_equal [ 0, 1 ], payload.fetch("recipe_steps").pluck("position")
    assert_equal false, payload.fetch("steps_editable")
    line = payload.fetch("recipe_ingredients").sole
    assert_equal recipe_ingredients(:one).ingredient_id, line.fetch("ingredient_id")
    assert_equal "0.5", line.fetch("quantity").to_s
    assert_equal "oz", line.fetch("measuring_unit")
    assert_equal "freshly squeezed", line.fetch("preparation_note")
    assert_equal false, line.fetch("optional")
    assert_equal "mixing", line.fetch("role")
    assert_equal "Gin", line.fetch("submitted_text")
    assert_equal "jigger", payload.fetch("recipe_utensils").sole.fetch("submitted_text")
    assert_equal false, payload.fetch("can_edit")
    assert_equal false, payload.fetch("can_delete")
    assert_nil payload.fetch("cocktail")
    assert_not payload.fetch("author_profile").key?("email_address")
  end

  test "recipe cards include viewer specific stars and public author name" do
    owner = users(:one)
    owner.update!(display_name: "Mika")
    recipe = recipes(:one)
    owner.favorites_collection.collection_recipes.create!(recipe: recipe)
    sign_in_as(owner)
    get recipes_url(format: :json)
    payload = response.parsed_body.fetch("data").find { |entry| entry.fetch("id") == recipe.id }
    assert_equal true, payload.fetch("starred")
    assert_equal 1, payload.fetch("star_count")
    assert_equal true, payload.fetch("can_edit")
    assert_equal true, payload.fetch("can_delete")
    assert_equal "Mika", payload.fetch("author_profile").fetch("name")
    assert_not payload.key?("recipe_ingredients")
    sign_out
    get recipe_url(recipe, format: :json)
    assert_equal false, response.parsed_body.fetch("starred")
    assert_equal 1, response.parsed_body.fetch("star_count")
    assert_equal false, response.parsed_body.fetch("can_edit")
    sign_in_as(users(:two))
    get recipe_url(recipe, format: :json)
    assert_equal false, response.parsed_body.fetch("starred")
    assert_equal false, response.parsed_body.fetch("can_delete")
  end

  test "cocktail context is exposed only when the cocktail is readable" do
    recipe = recipes(:one)
    cocktail = Cocktail.create!(name: "Test cocktail")
    recipe.update!(cocktail: cocktail)
    get recipe_url(recipe, format: :json)
    assert_equal cocktail.id, response.parsed_body.fetch("cocktail").fetch("id")
    get cocktail_url(cocktail, format: :json)
    assert_equal false, response.parsed_body.fetch("recipes").sole.fetch("starred")
    recipe.update!(visibility: "private")
    sign_in_as(users(:one))
    get recipe_url(recipe, format: :json)
    assert_response :success
    assert_nil response.parsed_body.fetch("cocktail")
    sign_out
    get recipe_url(recipe, format: :json)
    assert_response :forbidden
  end

  test "index responses wrap data and pagination metadata" do
    cocktail = Cocktail.create!(name: "Test cocktail")
    recipes(:one).update!(cocktail: cocktail)
    [ recipes_url(format: :json), cocktails_url(format: :json) ].each do |url|
      get url
      assert_response :success
      data = response.parsed_body.fetch("data")
      assert_kind_of Array, data
      assert_equal({
        "current_page" => 1, "next_page" => nil, "total_count" => data.size,
        "total_pages" => 1, "per_page" => 24
      }, response.parsed_body.fetch("metadata"))
      assert_nil response.headers["X-Current-Page"]

      get url, params: { q: "no-matching-result-for-pagination" }
      assert_response :success
      assert_empty response.parsed_body.fetch("data")
      assert_equal({
        "current_page" => 1, "next_page" => nil, "total_count" => 0,
        "total_pages" => 0, "per_page" => 24
      }, response.parsed_body.fetch("metadata"))
    end
  end

  test "recipe JSON mutations return the expanded detail representation" do
    sign_in_as(users(:one))
    post recipes_url(format: :json), params: { recipe: { name: "Draft", steps: "Stir." } }
    assert_response :created
    payload = response.parsed_body
    assert_equal [ "Stir." ], payload.fetch("recipe_steps").pluck("body")
    assert_empty payload.fetch("recipe_ingredients")
    assert_equal true, payload.fetch("steps_editable")
    patch recipe_url(payload.fetch("id"), format: :json), params: { recipe: { steps: "Shake." } }
    assert_response :success
    assert_equal [ "Shake." ], response.parsed_body.fetch("recipe_steps").pluck("body")
  end

  test "technique guide is available as JSON by slug" do
    get technique_url(techniques(:shake), format: :json)
    assert_response :success
    payload = response.parsed_body
    assert_equal "shake", payload.fetch("slug")
    assert_equal techniques(:shake).instructions, payload.fetch("instructions")
    assert_equal techniques(:shake).tip, payload.fetch("tip")
  end
end
