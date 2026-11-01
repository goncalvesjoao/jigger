require "test_helper"

class CocktailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cocktail = cocktails(:one)
    sign_in_as(users(:one))
  end

  test "guests can browse cocktails" do
    sign_out
    get cocktails_url
    assert_response :success
    get cocktail_url(@cocktail)
    assert_response :success
  end

  test "guests must sign in to change cocktails" do
    sign_out
    get new_cocktail_url
    assert_redirected_to new_session_url

    assert_no_difference("Cocktail.count") do
      post cocktails_url, params: { cocktail: { name: "Test" } }
      assert_redirected_to new_session_url
      delete cocktail_url(@cocktail)
      assert_redirected_to new_session_url
    end

    patch cocktail_url(@cocktail), params: { cocktail: { name: "Changed" } }
    assert_redirected_to new_session_url
    assert_not_equal "Changed", @cocktail.reload.name
  end

  test "root lists all cocktails and guest navigation" do
    sign_out
    get root_url
    assert_response :success
    Cocktail.marketplace.find_each do |cocktail|
      assert_select "#cocktail_#{cocktail.id}"
    end
    assert_select "nav[aria-label='Main navigation']" do
      assert_select "a[href=?]", new_cocktail_path, text: "New Cocktail"
      assert_select "a[href=?]", new_session_path, text: "Enter"
      assert_select "button", text: "Log Out", count: 0
    end
  end

  test "signed in navigation offers logout" do
    get root_url
    assert_select "nav" do
      assert_select "a[href=?]", new_cocktail_path, text: "New Cocktail"
      assert_select "form[action=?]", session_path do
        assert_select "input[name='_method'][value='delete']"
        assert_select "button", text: "Log Out"
      end
      assert_select "a", text: "Enter", count: 0
    end
  end

  test "new cocktail form has no owner field" do
    get new_cocktail_url
    assert_select "[name='cocktail[user_id]']", count: 0
  end

  test "non owners cannot edit update or delete cocktails" do
    sign_in_as(users(:two))
    get edit_cocktail_url(@cocktail)
    assert_response :forbidden

    patch cocktail_url(@cocktail), params: { cocktail: { name: "Changed", user_id: users(:two).id } }
    assert_response :forbidden
    assert_not_equal "Changed", @cocktail.reload.name
    assert_equal users(:one), @cocktail.user

    assert_no_difference("Cocktail.count") do
      delete cocktail_url(@cocktail)
      assert_response :forbidden
    end
  end

  test "only owners see edit and delete controls" do
    get cocktail_url(@cocktail)
    assert_select "a[href=?]", edit_cocktail_path(@cocktail), count: 1
    assert_select "form[action=?]", cocktail_path(@cocktail), count: 1

    sign_in_as(users(:two))
    get cocktail_url(@cocktail)
    assert_select "a[href=?]", edit_cocktail_path(@cocktail), count: 0
    assert_select "form[action=?]", cocktail_path(@cocktail), count: 0

    sign_out
    get cocktail_url(@cocktail)
    assert_select "a[href=?]", edit_cocktail_path(@cocktail), count: 0
    assert_select "form[action=?]", cocktail_path(@cocktail), count: 0
  end

  test "should get index" do
    get cocktails_url
    assert_response :success
  end

  test "should get new" do
    get new_cocktail_url
    assert_response :success
  end

  test "should create cocktail" do
    assert_difference("Cocktail.count") do
      post cocktails_url, params: { cocktail: { name: @cocktail.name, preparation_time_seconds: @cocktail.preparation_time_seconds, steps: @cocktail.steps, user_id: users(:two).id } }
    end

    assert_redirected_to cocktail_url(Cocktail.last)
    assert_equal users(:one), Cocktail.last.user
    assert_equal "private", Cocktail.last.visibility
    assert_equal "draft", Cocktail.last.publication_state
  end

  test "should show cocktail" do
    get cocktail_url(@cocktail)
    assert_response :success
  end

  test "should get edit" do
    get edit_cocktail_url(@cocktail)
    assert_response :success
  end

  test "should update cocktail" do
    patch cocktail_url(@cocktail), params: { cocktail: { name: @cocktail.name, preparation_time_seconds: @cocktail.preparation_time_seconds, steps: @cocktail.steps, user_id: users(:two).id, visibility: "public", publication_state: "published" } }
    assert_redirected_to cocktail_url(@cocktail)
    assert_equal users(:one), @cocktail.reload.user
  end

  test "should destroy cocktail" do
    ingredient_count = @cocktail.cocktail_ingredients.count
    assert_difference("Cocktail.count", -1) do
      assert_difference("CocktailIngredient.count", -ingredient_count) do
        delete cocktail_url(@cocktail)
      end
    end

    assert_redirected_to cocktails_url
  end
  test "private recipes and drafts are readable only by their owner in HTML and JSON" do
    [ { visibility: "private" }, { visibility: "public", publication_state: "draft" } ].each do |state|
      @cocktail.update!(state)
      [ :html, :json ].each do |format|
        sign_out
        get cocktail_url(@cocktail, format: format)
        assert_response :forbidden
        get cocktails_url(format: format)
        assert_response :success
        assert_not_includes response.body, format == :json ? "\"id\":#{@cocktail.id}," : "id=\"cocktail_#{@cocktail.id}\""
        sign_in_as(users(:two))
        get cocktail_url(@cocktail, format: format)
        assert_response :forbidden
        get cocktails_url(format: format)
        assert_response :success
        assert_not_includes response.body, format == :json ? "\"id\":#{@cocktail.id}," : "id=\"cocktail_#{@cocktail.id}\""
        sign_in_as(users(:one))
        get cocktail_url(@cocktail, format: format)
        assert_response :success
        get cocktails_url(format: format)
        assert_response :success
        assert_not_includes response.body, format == :json ? "\"id\":#{@cocktail.id}," : "id=\"cocktail_#{@cocktail.id}\""
      end
    end
  end
  test "JSON authoring creates only a user variation and uses the new route and request name" do
    canonical_count = Cocktail.count
    assert_difference("Cocktail.count") do
      post cocktails_url(format: :json), params: { cocktail: { name: "My variation", language: "en", steps: "Stir." } }
      assert_response :created
    end
    assert_equal canonical_count + 1, Cocktail.count
    variation = Cocktail.last
    payload = response.parsed_body
    assert_equal variation.id, payload["id"]
    assert_equal "My variation", payload["name"]
    assert_nil payload["parent_cocktail_id"]
    assert_equal cocktail_url(variation, format: :json), payload["url"]
    get cocktail_url(@cocktail, format: :json)
    assert_response :success
    assert_equal @cocktail.parent_cocktail_id, response.parsed_body["parent_cocktail_id"]
  end
end

class UnifiedCocktailsControllerTest < ActionDispatch::IntegrationTest
  test "official status and system recipes are admin managed" do
    recipe = cocktails(:one)
    sign_in_as(users(:one))
    patch cocktail_url(recipe), params: { cocktail: { name: recipe.name, official: true, user_id: nil } }
    assert_redirected_to cocktail_url(recipe)
    assert_not recipe.reload.official?
    assert_equal users(:one), recipe.user
    recipe.update!(official: true)
    patch cocktail_url(recipe), params: { cocktail: { name: "Tampered" } }
    assert_response :forbidden
    recipe.update!(user: nil)
    patch cocktail_url(recipe), params: { cocktail: { name: "Tampered" } }
    assert_response :forbidden
    admin = users(:two)
    admin.update!(admin: true)
    sign_in_as(admin)
    patch cocktail_url(recipe), params: { cocktail: { name: "Curated", official: false } }
    assert_redirected_to cocktail_url(recipe)
    assert_equal "Curated", recipe.reload.name
    assert_not recipe.official?
  end

  test "homepage searches public recipes and hides private parents and variants" do
    parent = cocktails(:one)
    variant = cocktails(:two)
    parent.update!(name: "Negroni", official: true)
    variant.update!(name: "White Negroni", parent_cocktail: parent)
    sign_out
    get root_url, params: { q: "negroni" }
    assert_select "#cocktail_#{parent.id}"
    assert_select "#cocktail_#{variant.id}"
    assert_select "p", text: "Official Jigger recipe"
    get cocktail_url(parent)
    assert_select "a[href=?]", cocktail_path(variant), count: 1
    variant.update!(visibility: "private")
    get cocktail_url(parent)
    assert_select "a[href=?]", cocktail_path(variant), count: 0
    get root_url, params: { q: "white" }
    assert_select "#cocktail_#{variant.id}", count: 0
    sign_in_as(users(:one))
    post cocktails_url, params: { cocktail: { name: "Private parent", parent_cocktail_id: variant.id } }
    assert_response :not_found
  end

  test "historical recipe URLs redirect to their migrated record" do
    recipe = cocktails(:one)
    recipe.update!(legacy_user_cocktail_id: 42)
    get "/user_cocktails/42"
    assert_redirected_to cocktail_url(recipe)
    recipe.update!(visibility: "private")
    get "/user_cocktails/42"
    assert_response :forbidden
  end
end

class LocalizedCocktailsControllerTest < ActionDispatch::IntegrationTest
  test "authoring stores names and descriptions in the submitted language" do
    sign_in_as(users(:one))
    post cocktails_url(format: :json), params: { cocktail: { name: "梅酒カクテル", description: "梅酒を使う", language: "ja" } }
    assert_response :created
    recipe = Cocktail.last
    assert_equal "ja", recipe.language
    assert_equal :ja, recipe.translations.sole.locale
    assert_equal "梅酒カクテル", response.parsed_body["name"]
    get cocktail_url(recipe, format: :json)
    assert_equal "梅酒を使う", response.parsed_body["description"]
    get edit_cocktail_url(recipe)
    assert_select "input[name='cocktail[name]'][value='梅酒カクテル']"
    patch cocktail_url(recipe), params: { cocktail: { name: "梅酒サワー", description: "新しい説明", language: "ja" } }
    assert_redirected_to cocktail_url(recipe)
    assert_equal "梅酒サワー", recipe.reload.display_name
    assert_equal 1, recipe.translations.count
  end
end
