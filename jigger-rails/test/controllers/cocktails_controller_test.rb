require "test_helper"

class CocktailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cocktail = Cocktail.create!(name: "Margarita", description: "A classic sour")
    recipes(:one).update!(cocktail: @cocktail, name: "Bright sour")
    recipes(:two).update!(cocktail: @cocktail, name: "Dry sour")
  end

  test "ingredient and utensil matching modes are independent" do
    shaker = Utensil.new(name: "Shaker")
    shaker.image.attach(io: StringIO.new(utensils(:jigger).image.download), filename: "shaker.png", content_type: "image/png")
    shaker.save!
    RecipeUtensil.create!(recipe: recipes(:one), utensil: shaker, submitted_text: "Shaker", language: "en", role: "preparation")
    filters = { ingredient_ids: [ ingredients(:one).id ], utensil_ids: [ utensils(:jigger).id ], ingredient_mode: "only", utensil_mode: "include" }
    get cocktails_url, params: filters
    assert_select ".recipe-count", text: "1"
    get cocktail_url(@cocktail), params: filters
    assert_select "#matching-recipes #recipe_#{recipes(:one).id}"
    get cocktails_url, params: filters.merge(utensil_mode: "only")
    assert_select ".empty-state"
    get cocktails_url, params: filters.merge(ingredient_ids: [ ingredients(:one).id, ingredients(:two).id ])
    assert_select ".recipe-count", text: "1"
    get cocktails_url, params: filters.merge(ingredient_mode: "include", ingredient_ids: [ ingredients(:one).id, ingredients(:two).id ])
    assert_select ".empty-state"
  end

  test "makeable mode without selections keeps marketplace results and text search" do
    [ {}, { ingredient_ids: [ "" ], utensil_ids: [ "" ] } ].each do |filters|
      get cocktails_url, params: filters.merge(makeable: "1")
      assert_response :success
      assert_select "h3 a", text: "Margarita"
      assert_select ".empty-state", count: 0
      assert_select "[data-picker-count]", text: "Add ingredients"
      assert_select "[data-picker-count]", text: "Add utensils"
    end
    get cocktails_url, params: { makeable: "1", q: "bright" }
    assert_select ".recipe-count", text: "1"
  end

  test "marketplace search lives above results and retains selections and image badges" do
    get root_url, params: { q: "margarita", ingredient_ids: Ingredient.ids, utensil_ids: Utensil.ids, makeable: "1" }
    assert_response :success
    assert_select "section.discovery-heading", count: 0
    assert_select "nav .marketplace-search", count: 0
    assert_select "main .marketplace-search[action=?]", cocktails_path do
      assert_select ".marketplace-submit-wrapper > button.marketplace-submit[type=submit][aria-label=Search]" do
        assert_select "svg[aria-hidden=true]"
      end
      assert_select ".marketplace-mode-summary", count: 0
      assert_select "[data-picker-count]", text: "#{Ingredient.count} available · Only these"
      assert_select "[data-picker-count]", text: "#{Utensil.count} available · Only these"
      assert_select "label[for=marketplace-query]", text: "Search cocktails"
      assert_select "input[type=search][name=q][value=margarita]"
      assert_select "input[type=checkbox][name='ingredient_ids[]'][checked]", count: Ingredient.count
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
    assert_select "#matching-recipes #recipe_#{recipes(:two).id}", count: 0
    assert_select "#other-recipes #recipe_#{recipes(:two).id}"
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

  test "matching official recipes appear in full in cocktail details without duplicate cards" do
    recipe = recipes(:one)
    recipe.update!(official: true, servings: 2, source_reference: "Official source")
    get cocktail_url(@cocktail), params: { q: "margarita" }
    assert_response :success
    assert_select ".cocktail-details #recipe_#{recipe.id}", count: 1 do
      assert_select "h2", text: "Bright sour"
      assert_select "#ingredients_recipe_#{recipe.id} .ingredient-list li", count: recipe.recipe_ingredients.count
      assert_select "#preparation_recipe_#{recipe.id} .step-body", text: recipe.recipe_steps.first.body
      assert_select "dd", text: "2"
      assert_select ".recipe-footer", count: 0
      assert_select "p", text: "Official source", count: 0
    end
    assert_select "#matching-recipes h2", text: "Community recipes (1)"
    assert_select "#matching-recipes #recipe_#{recipe.id}", count: 0
    assert_select "#matching-recipes #recipe_#{recipes(:two).id}"
    get cocktail_url(@cocktail, format: :json)
    assert_equal [ recipe.id ], response.parsed_body["official_recipes"].map { |entry| entry["id"] }
    assert_equal [ recipes(:two).id ], response.parsed_body["recipes"].map { |entry| entry["id"] }
    assert_equal 1, response.parsed_body["matching_recipe_count"]
  end

  test "official recipes ignore filters in cocktail details and never bypass public eligibility" do
    recipes(:one).update!(official: true)
    [ { q: "dry" }, { ingredient_ids: [ ingredients(:two).id ] }, { ingredient_ids: [ "" ], utensil_ids: Utensil.ids, makeable: "1" } ].each do |filters|
      get cocktail_url(@cocktail), params: filters
      assert_select ".cocktail-details #recipe_#{recipes(:one).id}", count: 1
      assert_select "#matching-recipes #recipe_#{recipes(:one).id}", count: 0
      assert_select "#other-recipes #recipe_#{recipes(:one).id}", count: 0
      get cocktail_url(@cocktail, format: :json), params: filters
      assert_equal [ recipes(:one).id ], response.parsed_body["official_recipes"].map { |entry| entry["id"] }
      assert_not_includes response.parsed_body["recipes"].map { |entry| entry["id"] }, recipes(:one).id
      assert_not_includes response.parsed_body["other_recipes"].map { |entry| entry["id"] }, recipes(:one).id
      assert_equal(filters[:makeable] == "1" ? 0 : 1, response.parsed_body["matching_recipe_count"])
    end
    users(:one).update!(admin: true)
    sign_in_as(users(:one))
    [ { visibility: "private" }, { visibility: "public", publication_state: "draft" } ].each do |state|
      recipes(:one).update!(state)
      get cocktail_url(@cocktail)
      assert_select "#recipe_#{recipes(:one).id}", count: 0
    end
  end

  test "marketplace excludes matching official recipes from counters and hides zero counters" do
    recipes(:one).update!(official: true)
    get root_url
    assert_select ".recipe-count", text: "1", count: 1
    assert_select ".eyebrow", text: "Official recipe"
    get cocktails_url(format: :json)
    assert_equal 1, response.parsed_body.sole["matching_recipe_count"]
    get root_url, params: { q: "bright" }
    assert_select "h3 a[href=?]", cocktail_path(@cocktail, q: "bright")
    assert_select ".recipe-count", count: 0
    get cocktails_url(format: :json), params: { q: "bright" }
    assert_equal 0, response.parsed_body.sole["matching_recipe_count"]
    get root_url, params: { q: "dry" }
    assert_select ".recipe-count", text: "1", count: 1
    recipes(:one).update!(cocktail: nil)
    get root_url, params: { q: "bright" }
    assert_select ".recipe-count", text: "1", count: 1
  end


  test "ingredient and utensil filters count only makeable recipes" do
    recipes(:two).recipe_ingredients.update_all(ingredient_id: ingredients(:two).id)
    filters = { ingredient_ids: [ ingredients(:one).id ], utensil_ids: Utensil.ids, makeable: "1" }
    get cocktails_url, params: filters
    assert_select ".recipe-count", text: "1"
    get cocktail_url(@cocktail), params: filters
    assert_select "#recipe_#{recipes(:one).id}"
    assert_select "#matching-recipes #recipe_#{recipes(:two).id}", count: 0
    assert_select "#other-recipes #recipe_#{recipes(:two).id}"
    get cocktails_url, params: { ingredient_ids: [ "" ], utensil_ids: Utensil.ids, makeable: "1" }
    assert_select ".recipe-count", count: 0
  end

  test "contains filters require every selection but allow additional items" do
    recipes(:one).recipe_ingredients.create!(ingredient: ingredients(:two), submitted_text: "Ice", language: "en", position: 1)
    filters = { ingredient_ids: [ ingredients(:one).id ] }
    get cocktails_url, params: filters
    assert_select ".recipe-count", text: "1"
    assert_select "h3 a[href=?]", cocktail_path(@cocktail, filters)
    get cocktail_url(@cocktail), params: filters
    assert_select "#matching-recipes #recipe_#{recipes(:one).id}"
    assert_select "#other-recipes #recipe_#{recipes(:two).id}"
    assert_select ".search-context p", text: /Contains ingredients:/
    get cocktails_url, params: filters.merge(makeable: "1", utensil_ids: Utensil.ids)
    assert_select ".recipe-count", count: 0
    get cocktails_url, params: { ingredient_ids: Ingredient.ids, utensil_ids: Utensil.ids }
    assert_select ".recipe-count", text: "1"
    get cocktails_url, params: { utensil_ids: Utensil.ids }
    assert_select ".recipe-count", text: "1"
    get cocktails_url, params: filters.merge(q: "dry")
    assert_select ".recipe-count", count: 0
    get cocktails_url, params: { ingredient_ids: [ "" ], utensil_ids: [ "" ] }
    assert_select ".recipe-count", text: "2"
    get cocktails_url, params: { ingredient_ids: [ "999999999" ] }
    assert_select ".recipe-count", count: 0
  end

  test "cocktail details precede matches and nonmatches are collapsed with search context" do
    @cocktail.update!(history: "A historical account", source_reference: "History book", source_url: "https://example.com/history",
      source_published_on: "1930-01-01", source_date_note: "Year confirmed")
    @cocktail.cocktail_aliases.create!(name: "Daisy", language: "en")
    get cocktail_url(@cocktail), params: { q: "bright" }
    assert_response :success
    assert_select ".cocktail-details" do
      assert_select "h1", text: "Margarita"
      assert_select "p", text: "A classic sour"
      assert_select "p", text: "A historical account"
      assert_select "p", text: "Also known as: Daisy"
      assert_select "a[href='https://example.com/history']", text: "History book"
      assert_select "p", text: "Historical source publication: 1930-01-01"
      assert_select "p", text: "Year confirmed"
    end
    assert_operator response.body.index('class="cocktail-details"'), :<, response.body.index('id="matching-recipes"')
    assert_select ".search-context strong", text: "bright"
    assert_select ".search-context a[href=?]", cocktail_path(@cocktail), text: "Show all recipes"
    assert_select "nav[aria-label='Breadcrumb']" do
      assert_select "a.back-link[href=?]", cocktails_path(q: "bright"), text: "Cocktails"
      assert_select "li[aria-current='page']", text: "Margarita"
    end
    assert_select "#matching-recipes h2", text: "Community recipes (1)"
    assert_select "#matching-recipes #recipe_#{recipes(:one).id}"
    assert_select "details#other-recipes:not([open])" do
      assert_select "summary", text: "Other community recipes (1)"
      assert_select "#recipe_#{recipes(:two).id}"
      assert_select "#recipe_#{recipes(:one).id}", count: 0
    end
  end

  test "unfiltered and blank searches show all public recipes without collapsed alternatives" do
    [ {}, { q: " " } ].each do |filters|
      get cocktail_url(@cocktail), params: filters
      assert_select "#matching-recipes h2", text: "Community recipes (2)"
      assert_select "#matching-recipes article", count: 2
      assert_select "details#other-recipes", count: 0
      assert_select ".search-context", count: 0
    end
    get cocktail_url(@cocktail), params: { q: "margarita" }
    assert_select "#matching-recipes article", count: 2
    assert_select "details#other-recipes", count: 0
  end

  test "zero matching recipes still offers collapsed alternatives and names availability filters" do
    get cocktail_url(@cocktail), params: { ingredient_ids: [ "" ], utensil_ids: Utensil.ids, makeable: "1" }
    assert_select "#matching-recipes h2", text: "Community recipes (0)"
    assert_select "#matching-recipes p", text: "No community recipes match these filters."
    assert_select ".search-context p", text: "Available ingredients: None"
    assert_select ".search-context p", text: /Available utensils:/
    assert_select "details#other-recipes:not([open]) article", count: 2
  end

  test "alternative recipes exclude private drafts and other cocktails even for admins" do
    [ { visibility: "private" }, { publication_state: "draft" }, { cocktail: nil } ].each do |state|
      recipe = Recipe.new(user: users(:one), cocktail: @cocktail, name: "Hidden alternative", language: "en", steps: "Stir.")
      recipe.recipe_ingredients.build(ingredient: ingredients(:one), submitted_text: "Gin", language: "en")
      recipe.assign_attributes({ visibility: "public", publication_state: "published" }.merge(state))
      recipe.save!
    end
    users(:one).update!(admin: true)
    sign_in_as(users(:one))
    get cocktail_url(@cocktail), params: { q: "bright" }
    assert_select "#matching-recipes article", count: 1
    assert_select "#other-recipes article", count: 1
    get cocktail_url(@cocktail, format: :json), params: { q: "bright" }
    assert_equal true, response.parsed_body["filters_applied"]
    assert_equal [ recipes(:one).id ], response.parsed_body["recipes"].map { |recipe| recipe["id"] }
    assert_equal [ recipes(:two).id ], response.parsed_body["other_recipes"].map { |recipe| recipe["id"] }
  end

  test "marketplace paginates whole groups with lazy frames and preserves filters" do
    24.times do |index|
      recipe = Recipe.create!(user: users(:one), name: "Margarita variation #{index}", language: "en", steps: "Stir.")
      recipe.recipe_ingredients.create!(ingredient: ingredients(:one), submitted_text: "Gin", language: "en")
      recipe.update!(visibility: "public", publication_state: "published")
    end
    recipes(:one).update!(published_at: 1.day.from_now)
    filters = { q: "margarita", ingredient_ids: Ingredient.ids, utensil_ids: Utensil.ids, makeable: "1" }

    get root_url, params: filters
    assert_response :success
    assert_select ".recipe-grid article", count: 24
    assert_select ".recipe-count", text: "2", count: 1
    assert_select ".marketplace-results h2", text: "25 cocktails"
    next_url = css_select("turbo-frame#cocktails_page_2[loading='lazy']").sole["src"]
    query = Rack::Utils.parse_nested_query(URI.parse(next_url).query)
    assert_equal "margarita", query["q"]
    assert_equal "1", query["makeable"]
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
