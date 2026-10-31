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
    Cocktail.find_each do |cocktail|
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
    patch cocktail_url(@cocktail), params: { cocktail: { name: @cocktail.name, preparation_time_seconds: @cocktail.preparation_time_seconds, steps: @cocktail.steps, user_id: users(:two).id } }
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
end
