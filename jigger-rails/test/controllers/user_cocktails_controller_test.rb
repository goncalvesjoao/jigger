require "test_helper"

class UserCocktailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_cocktail = user_cocktails(:one)
    sign_in_as(users(:one))
  end

  test "guests can browse user_cocktails" do
    sign_out
    get user_cocktails_url
    assert_response :success
    get user_cocktail_url(@user_cocktail)
    assert_response :success
  end

  test "guests must sign in to change user_cocktails" do
    sign_out
    get new_user_cocktail_url
    assert_redirected_to new_session_url

    assert_no_difference("UserCocktail.count") do
      post user_cocktails_url, params: { user_cocktail: { name: "Test" } }
      assert_redirected_to new_session_url
      delete user_cocktail_url(@user_cocktail)
      assert_redirected_to new_session_url
    end

    patch user_cocktail_url(@user_cocktail), params: { user_cocktail: { name: "Changed" } }
    assert_redirected_to new_session_url
    assert_not_equal "Changed", @user_cocktail.reload.name
  end

  test "root lists all user_cocktails and guest navigation" do
    sign_out
    get root_url
    assert_response :success
    UserCocktail.find_each do |user_cocktail|
      assert_select "#user_cocktail_#{user_cocktail.id}"
    end
    assert_select "nav[aria-label='Main navigation']" do
      assert_select "a[href=?]", new_user_cocktail_path, text: "New Cocktail"
      assert_select "a[href=?]", new_session_path, text: "Enter"
      assert_select "button", text: "Log Out", count: 0
    end
  end

  test "signed in navigation offers logout" do
    get root_url
    assert_select "nav" do
      assert_select "a[href=?]", new_user_cocktail_path, text: "New Cocktail"
      assert_select "form[action=?]", session_path do
        assert_select "input[name='_method'][value='delete']"
        assert_select "button", text: "Log Out"
      end
      assert_select "a", text: "Enter", count: 0
    end
  end

  test "new user_cocktail form has no owner field" do
    get new_user_cocktail_url
    assert_select "[name='user_cocktail[user_id]']", count: 0
  end

  test "non owners cannot edit update or delete user_cocktails" do
    sign_in_as(users(:two))
    get edit_user_cocktail_url(@user_cocktail)
    assert_response :forbidden

    patch user_cocktail_url(@user_cocktail), params: { user_cocktail: { name: "Changed", user_id: users(:two).id } }
    assert_response :forbidden
    assert_not_equal "Changed", @user_cocktail.reload.name
    assert_equal users(:one), @user_cocktail.user

    assert_no_difference("UserCocktail.count") do
      delete user_cocktail_url(@user_cocktail)
      assert_response :forbidden
    end
  end

  test "only owners see edit and delete controls" do
    get user_cocktail_url(@user_cocktail)
    assert_select "a[href=?]", edit_user_cocktail_path(@user_cocktail), count: 1
    assert_select "form[action=?]", user_cocktail_path(@user_cocktail), count: 1

    sign_in_as(users(:two))
    get user_cocktail_url(@user_cocktail)
    assert_select "a[href=?]", edit_user_cocktail_path(@user_cocktail), count: 0
    assert_select "form[action=?]", user_cocktail_path(@user_cocktail), count: 0

    sign_out
    get user_cocktail_url(@user_cocktail)
    assert_select "a[href=?]", edit_user_cocktail_path(@user_cocktail), count: 0
    assert_select "form[action=?]", user_cocktail_path(@user_cocktail), count: 0
  end

  test "should get index" do
    get user_cocktails_url
    assert_response :success
  end

  test "should get new" do
    get new_user_cocktail_url
    assert_response :success
  end

  test "should create user_cocktail" do
    assert_difference("UserCocktail.count") do
      post user_cocktails_url, params: { user_cocktail: { name: @user_cocktail.name, preparation_time_seconds: @user_cocktail.preparation_time_seconds, steps: @user_cocktail.steps, user_id: users(:two).id, visibility: "public", publication_state: "published" } }
    end

    assert_redirected_to user_cocktail_url(UserCocktail.last)
    assert_equal users(:one), UserCocktail.last.user
    assert_equal "private", UserCocktail.last.visibility
    assert_equal "draft", UserCocktail.last.publication_state
  end

  test "should show user_cocktail" do
    get user_cocktail_url(@user_cocktail)
    assert_response :success
  end

  test "should get edit" do
    get edit_user_cocktail_url(@user_cocktail)
    assert_response :success
  end

  test "should update user_cocktail" do
    patch user_cocktail_url(@user_cocktail), params: { user_cocktail: { name: @user_cocktail.name, preparation_time_seconds: @user_cocktail.preparation_time_seconds, steps: @user_cocktail.steps, user_id: users(:two).id, visibility: "public", publication_state: "published" } }
    assert_redirected_to user_cocktail_url(@user_cocktail)
    assert_equal users(:one), @user_cocktail.reload.user
  end

  test "should destroy user_cocktail" do
    ingredient_count = @user_cocktail.user_cocktail_ingredients.count
    assert_difference("UserCocktail.count", -1) do
      assert_difference("UserCocktailIngredient.count", -ingredient_count) do
        delete user_cocktail_url(@user_cocktail)
      end
    end

    assert_redirected_to user_cocktails_url
  end
  test "private recipes and drafts are readable only by their owner in HTML and JSON" do
    [ { visibility: "private" }, { visibility: "public", publication_state: "draft" } ].each do |state|
      @user_cocktail.update!(state)
      [ :html, :json ].each do |format|
        sign_out
        get user_cocktail_url(@user_cocktail, format: format)
        assert_response :forbidden
        get user_cocktails_url(format: format)
        assert_response :success
        assert_not_includes response.body, format == :json ? "\"id\":#{@user_cocktail.id}," : "id=\"user_cocktail_#{@user_cocktail.id}\""
        sign_in_as(users(:two))
        get user_cocktail_url(@user_cocktail, format: format)
        assert_response :forbidden
        get user_cocktails_url(format: format)
        assert_response :success
        assert_not_includes response.body, format == :json ? "\"id\":#{@user_cocktail.id}," : "id=\"user_cocktail_#{@user_cocktail.id}\""
        sign_in_as(users(:one))
        get user_cocktail_url(@user_cocktail, format: format)
        assert_response :success
        get user_cocktails_url(format: format)
        assert_response :success
        assert_includes response.body, format == :json ? "\"id\":#{@user_cocktail.id}," : "id=\"user_cocktail_#{@user_cocktail.id}\""
      end
    end
  end
  test "JSON authoring creates only a user variation and uses the new route and request name" do
    canonical_count = Cocktail.count
    assert_difference("UserCocktail.count") do
      post user_cocktails_url(format: :json), params: { user_cocktail: { name: "My variation", language: "en", steps: "Stir." } }
      assert_response :created
    end
    assert_equal canonical_count, Cocktail.count
    variation = UserCocktail.last
    payload = response.parsed_body
    assert_equal variation.id, payload["id"]
    assert_equal "My variation", payload["name"]
    assert_nil payload["cocktail_id"]
    assert_equal user_cocktail_url(variation, format: :json), payload["url"]
    get user_cocktail_url(@user_cocktail, format: :json)
    assert_response :success
    assert_equal @user_cocktail.cocktail_id, response.parsed_body["cocktail_id"]
  end
end
