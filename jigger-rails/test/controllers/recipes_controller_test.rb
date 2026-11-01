require "test_helper"

class RecipesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @recipe = recipes(:one)
    sign_in_as(users(:one))
  end

  test "guests can browse recipes" do
    sign_out
    get recipes_url
    assert_response :success
    get recipe_url(@recipe)
    assert_response :success
  end

  test "guests must sign in to change recipes" do
    sign_out
    get new_recipe_url
    assert_redirected_to new_session_url

    assert_no_difference("Recipe.count") do
      post recipes_url, params: { recipe: { name: "Test" } }
      assert_redirected_to new_session_url
      delete recipe_url(@recipe)
      assert_redirected_to new_session_url
    end

    patch recipe_url(@recipe), params: { recipe: { name: "Changed" } }
    assert_redirected_to new_session_url
    assert_not_equal "Changed", @recipe.reload.name
  end

  test "root lists all recipes and guest navigation" do
    sign_out
    get root_url
    assert_response :success
    Recipe.marketplace.find_each do |recipe|
      assert_select "#recipe_#{recipe.id}"
    end
    assert_select "nav[aria-label='Main navigation']" do
      assert_select "a[href=?]", new_recipe_path, text: "New Recipe"
      assert_select "a[href=?]", new_session_path, text: "Enter"
      assert_select "button", text: "Log Out", count: 0
    end
  end

  test "signed in navigation offers logout" do
    get root_url
    assert_select "nav" do
      assert_select "a[href=?]", new_recipe_path, text: "New Recipe"
      assert_select "form[action=?]", session_path do
        assert_select "input[name='_method'][value='delete']"
        assert_select "button", text: "Log Out"
      end
      assert_select "a", text: "Enter", count: 0
    end
  end

  test "new recipe form has no owner field" do
    get new_recipe_url
    assert_select "[name='recipe[user_id]']", count: 0
  end

  test "non owners cannot edit update or delete recipes" do
    sign_in_as(users(:two))
    get edit_recipe_url(@recipe)
    assert_response :forbidden

    patch recipe_url(@recipe), params: { recipe: { name: "Changed", user_id: users(:two).id } }
    assert_response :forbidden
    assert_not_equal "Changed", @recipe.reload.name
    assert_equal users(:one), @recipe.user

    assert_no_difference("Recipe.count") do
      delete recipe_url(@recipe)
      assert_response :forbidden
    end
  end

  test "only owners see edit and delete controls" do
    get recipe_url(@recipe)
    assert_select "a[href=?]", edit_recipe_path(@recipe), count: 1
    assert_select "form[action=?]", recipe_path(@recipe), count: 1

    sign_in_as(users(:two))
    get recipe_url(@recipe)
    assert_select "a[href=?]", edit_recipe_path(@recipe), count: 0
    assert_select "form[action=?]", recipe_path(@recipe), count: 0

    sign_out
    get recipe_url(@recipe)
    assert_select "a[href=?]", edit_recipe_path(@recipe), count: 0
    assert_select "form[action=?]", recipe_path(@recipe), count: 0
  end

  test "should get index" do
    get recipes_url
    assert_response :success
  end

  test "should get new" do
    get new_recipe_url
    assert_response :success
  end

  test "should create recipe" do
    assert_difference("Recipe.count") do
      post recipes_url, params: { recipe: { name: @recipe.name, preparation_time_seconds: @recipe.preparation_time_seconds, steps: @recipe.steps, user_id: users(:two).id } }
    end

    assert_redirected_to recipe_url(Recipe.last)
    assert_equal users(:one), Recipe.last.user
    assert_equal "private", Recipe.last.visibility
    assert_equal "draft", Recipe.last.publication_state
  end

  test "should show recipe" do
    get recipe_url(@recipe)
    assert_response :success
  end

  test "should get edit" do
    get edit_recipe_url(@recipe)
    assert_response :success
  end

  test "should update recipe" do
    patch recipe_url(@recipe), params: { recipe: { name: @recipe.name, preparation_time_seconds: @recipe.preparation_time_seconds, steps: @recipe.steps, user_id: users(:two).id, visibility: "public", publication_state: "published" } }
    assert_redirected_to recipe_url(@recipe)
    assert_equal users(:one), @recipe.reload.user
  end

  test "should destroy recipe" do
    ingredient_count = @recipe.recipe_ingredients.count
    assert_difference("Recipe.count", -1) do
      assert_difference("RecipeIngredient.count", -ingredient_count) do
        delete recipe_url(@recipe)
      end
    end

    assert_redirected_to recipes_url
  end
  test "private recipes and drafts are readable only by their owner in HTML and JSON" do
    [ { visibility: "private" }, { visibility: "public", publication_state: "draft" } ].each do |state|
      @recipe.update!(state)
      [ :html, :json ].each do |format|
        sign_out
        get recipe_url(@recipe, format: format)
        assert_response :forbidden
        get recipes_url(format: format)
        assert_response :success
        assert_not_includes response.body, format == :json ? "\"id\":#{@recipe.id}," : "id=\"recipe_#{@recipe.id}\""
        sign_in_as(users(:two))
        get recipe_url(@recipe, format: format)
        assert_response :forbidden
        get recipes_url(format: format)
        assert_response :success
        assert_not_includes response.body, format == :json ? "\"id\":#{@recipe.id}," : "id=\"recipe_#{@recipe.id}\""
        sign_in_as(users(:one))
        get recipe_url(@recipe, format: format)
        assert_response :success
        get recipes_url(format: format)
        assert_response :success
        assert_not_includes response.body, format == :json ? "\"id\":#{@recipe.id}," : "id=\"recipe_#{@recipe.id}\""
      end
    end
  end
  test "JSON authoring creates only a user variation and uses the new route and request name" do
    canonical_count = Recipe.count
    assert_difference("Recipe.count") do
      post recipes_url(format: :json), params: { recipe: { name: "My variation", language: "en", steps: "Stir." } }
      assert_response :created
    end
    assert_equal canonical_count + 1, Recipe.count
    variation = Recipe.last
    payload = response.parsed_body
    assert_equal variation.id, payload["id"]
    assert_equal "My variation", payload["name"]
    assert_not payload.key?("parent_recipe_id")
    assert_equal recipe_url(variation, format: :json), payload["url"]
    get recipe_url(@recipe, format: :json)
    assert_response :success
    assert_not response.parsed_body.key?("parent_recipe_id")
  end
end

class UnifiedRecipesControllerTest < ActionDispatch::IntegrationTest
  test "official status and system recipes are admin managed" do
    recipe = recipes(:one)
    sign_in_as(users(:one))
    patch recipe_url(recipe), params: { recipe: { name: recipe.name, official: true, user_id: nil } }
    assert_redirected_to recipe_url(recipe)
    assert_not recipe.reload.official?
    assert_equal users(:one), recipe.user
    recipe.update!(official: true)
    patch recipe_url(recipe), params: { recipe: { name: "Tampered" } }
    assert_response :forbidden
    recipe.update!(user: nil)
    patch recipe_url(recipe), params: { recipe: { name: "Tampered" } }
    assert_response :forbidden
    admin = users(:two)
    admin.update!(admin: true)
    sign_in_as(admin)
    patch recipe_url(recipe), params: { recipe: { name: "Curated", official: false } }
    assert_response :unprocessable_content
    assert recipe.reload.official?
    assert_nil recipe.user
    assert_not_equal "Curated", recipe.name
  end

  test "homepage searches public recipes and hides private recipes" do
    reference = recipes(:one)
    alternate = recipes(:two)
    reference.update!(name: "Negroni", official: true)
    alternate.update!(name: "White Negroni")
    sign_out
    get root_url, params: { q: "negroni" }
    assert_select "#recipe_#{reference.id}"
    assert_select "#recipe_#{alternate.id}"
    assert_select "p", text: "Official Jigger recipe"
    alternate.update!(visibility: "private")
    get root_url, params: { q: "white" }
    assert_select "#recipe_#{alternate.id}", count: 0
  end
end

class LocalizedRecipesControllerTest < ActionDispatch::IntegrationTest
  test "authoring stores names in the submitted language" do
    sign_in_as(users(:one))
    post recipes_url(format: :json), params: { recipe: { name: "梅酒カクテル", language: "ja" } }
    assert_response :created
    recipe = Recipe.last
    assert_equal "ja", recipe.language
    assert_equal :ja, recipe.translations.sole.locale
    assert_equal "梅酒カクテル", response.parsed_body["name"]
    get recipe_url(recipe, format: :json)
    assert_not response.parsed_body.key?("description")
    get edit_recipe_url(recipe)
    assert_select "input[name='recipe[name]'][value='梅酒カクテル']"
    patch recipe_url(recipe), params: { recipe: { name: "梅酒サワー", language: "ja" } }
    assert_redirected_to recipe_url(recipe)
    assert_equal "梅酒サワー", recipe.reload.display_name
    assert_equal 1, recipe.translations.count
  end
end
