require "test_helper"

class CocktailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cocktail = Cocktail.create!(name: "Margarita", description: "A classic sour")
    recipes(:one).update!(cocktail: @cocktail, name: "Bright sour")
    recipes(:two).update!(cocktail: @cocktail, name: "Dry sour")
  end

  test "marketplace search lives in the navbar and badges overlay card images" do
    get root_url, params: { q: "margarita", ingredient_ids: Ingredient.ids, utensil_ids: Utensil.ids }
    assert_response :success
    assert_select "section.discovery-heading", count: 0
    assert_select "nav .navbar-search[action=?]", cocktails_path do
      assert_select "label[for=navbar-query]", text: "Search cocktails"
      assert_select "input[type=search][name=q][value=margarita]"
      assert_select "input[name='ingredient_ids[]']", count: Ingredient.count + 1
    end
    assert_select ".card-media .recipe-count[title='Matching recipe(s)'][aria-label='2 matching recipes']", text: "2"
    assert_select ".card-copy .recipe-count", count: 0
  end

  test "marketplace groups matching recipes and keeps unassigned creations discoverable" do
    get root_url
    assert_response :success
    assert_select ".recipe-count", text: "2", count: 1
    assert_select "h3 a[href=?]", cocktail_path(@cocktail), text: "Margarita", count: 1
    recipes(:two).update!(cocktail: nil)
    get root_url
    assert_select ".recipe-count", text: "1", count: 2
    assert_select "h3 a[href=?]", recipe_path(recipes(:two)), text: "Dry sour"
    assert_no_difference("Cocktail.count") { recipes(:two).update!(name: "My original") }
  end

  test "counts and detail links preserve the current search and exclude private recipes" do
    get cocktails_url, params: { q: "bright" }
    assert_select ".recipe-count", text: "1", count: 1
    assert_select "h3 a[href=?]", cocktail_path(@cocktail, q: "bright")
    get cocktail_url(@cocktail), params: { q: "bright" }
    assert_response :success
    assert_select "#recipe_#{recipes(:one).id}"
    assert_select "#recipe_#{recipes(:two).id}", count: 0
    recipes(:two).update!(visibility: "private")
    get root_url, params: { q: "margarita" }
    assert_select ".recipe-count", text: "1"
    get cocktail_url(@cocktail)
    assert_select "#recipe_#{recipes(:two).id}", count: 0
    recipes(:one).update!(publication_state: "draft")
    get root_url
    assert_select ".recipe-count", count: 0
    get cocktail_url(@cocktail)
    assert_response :forbidden
  end

  test "ingredient and utensil filters count only makeable recipes" do
    recipes(:two).recipe_ingredients.update_all(ingredient_id: ingredients(:two).id)
    filters = { ingredient_ids: [ ingredients(:one).id ], utensil_ids: Utensil.ids }
    get cocktails_url, params: filters
    assert_select ".recipe-count", text: "1"
    get cocktail_url(@cocktail), params: filters
    assert_select "#recipe_#{recipes(:one).id}"
    assert_select "#recipe_#{recipes(:two).id}", count: 0
    get cocktails_url, params: { ingredient_ids: [ "" ], utensil_ids: Utensil.ids }
    assert_select ".recipe-count", count: 0
  end

  test "marketplace paginates whole groups with lazy frames and preserves filters" do
    24.times do |index|
      recipe = Recipe.create!(name: "Margarita variation #{index}", language: "en", steps: "Stir.")
      recipe.recipe_ingredients.create!(ingredient: ingredients(:one), submitted_text: "Gin", language: "en")
      recipe.update!(visibility: "public", publication_state: "published")
    end
    recipes(:one).update!(published_at: 1.day.from_now)
    filters = { q: "margarita", ingredient_ids: Ingredient.ids, utensil_ids: Utensil.ids }

    get root_url, params: filters
    assert_response :success
    assert_select ".recipe-grid article", count: 24
    assert_select ".recipe-count", text: "2", count: 1
    assert_select ".section-heading span", text: "25 cocktails"
    next_url = css_select("turbo-frame#cocktails_page_2[loading='lazy']").sole["src"]
    query = Rack::Utils.parse_nested_query(URI.parse(next_url).query)
    assert_equal "margarita", query["q"]
    assert_equal Ingredient.ids.map(&:to_s), query["ingredient_ids"]
    assert_equal Utensil.ids.map(&:to_s), query["utensil_ids"]
    first_ids = css_select(".recipe-grid article").map { |card| card["id"] }
    assert_select "a[href=?]", next_url, text: "Load more cocktails"

    get next_url, headers: { "Turbo-Frame" => "cocktails_page_2" }
    assert_response :success
    assert_select "turbo-frame#cocktails_page_2[target='_top']"
    assert_select ".recipe-grid article", count: 1
    assert_empty first_ids & css_select(".recipe-grid article").map { |card| card["id"] }
    assert_select "turbo-frame[src]", count: 0

    get cocktails_url(format: :json), params: filters.merge(page: 2)
    assert_response :success
    assert_equal 1, response.parsed_body.size

    get cocktails_url, params: filters.merge(page: 3)
    assert_response :success
    assert_select ".recipe-grid article", count: 0
    assert_select "turbo-frame[src]", count: 0
  end

  test "only admins curate identities and assign recipes" do
    sign_in_as(users(:one))
    assert_no_difference("Cocktail.count") do
      post admin_cocktails_url, params: { cocktail: { name: "New drink" } }
      assert_response :forbidden
    end
    patch recipe_url(recipes(:one)), params: { recipe: { cocktail_id: "" } }
    assert_equal @cocktail, recipes(:one).reload.cocktail
    users(:two).update!(admin: true)
    sign_in_as(users(:two))
    assert_difference("Cocktail.count") do
      post admin_cocktails_url, params: { cocktail: { name: "New drink" } }
      assert_response :redirect
    end
    patch recipe_url(recipes(:one)), params: { recipe: { cocktail_id: Cocktail.last.id } }
    assert_equal Cocktail.last, recipes(:one).reload.cocktail
    patch recipe_url(recipes(:one)), params: { recipe: { cocktail_id: "" } }
    assert_nil recipes(:one).reload.cocktail
  end

  test "JSON discovery returns grouped matching counts without private recipes" do
    recipes(:two).update!(visibility: "private")
    get cocktails_url(format: :json), params: { q: "bright" }
    assert_response :success
    group = response.parsed_body.sole
    assert_equal @cocktail.id, group["cocktail_id"]
    assert_equal 1, group["matching_recipe_count"]
    assert_equal [ recipes(:one).id ], group["recipes"].map { |recipe| recipe["id"] }
    get cocktail_url(@cocktail, format: :json)
    assert_response :success
    assert_equal 1, response.parsed_body["matching_recipe_count"]
  end

  test "admins can use canonical creation and assignment forms" do
    users(:two).update!(admin: true)
    sign_in_as(users(:two))
    get new_admin_cocktail_url
    assert_response :success
    assert_select "input[name='cocktail[name]']"
    get edit_admin_cocktail_url(@cocktail)
    assert_response :success
    get edit_recipe_url(recipes(:one))
    assert_response :success
    assert_select "select[name='recipe[cocktail_id]'] option[value=?][selected]", @cocktail.id.to_s
  end

  test "deleting an identity preserves recipes as standalone results" do
    assert_no_difference("Recipe.count") { @cocktail.destroy! }
    assert_nil recipes(:one).reload.cocktail
    get root_url
    assert_select ".recipe-count", text: "1", count: 2
  end
end
