require "test_helper"

class AccountControllerTest < ActionDispatch::IntegrationTest
  test "account pages require authentication" do
    [ my_recipes_url, my_lists_url, my_profile_url ].each do |url|
      get url
      assert_redirected_to new_session_url
    end
  end

  test "my recipes includes private recipes and excludes other users recipes" do
    own_recipe = recipes(:one)
    own_recipe.update!(visibility: "private", publication_state: "draft")
    sign_in_as(users(:one))
    get my_recipes_url
    assert_response :success
    assert_select "#recipe_#{own_recipe.id}"
    assert_select "#recipe_#{recipes(:two).id}", count: 0
    assert_select "a[href=?]", new_recipe_path, text: "New Recipe"
  end

  test "account dropdown and pages" do
    sign_in_as(users(:one))
    get root_url
    assert_select "details.account-dropdown" do
      assert_select "summary[aria-label='User account'] img[src=?]", "https://gravatar.com/avatar/#{Digest::SHA256.hexdigest(users(:one).email_address)}?s=80&d=mp"
      assert_select "a[href=?]", my_recipes_path, text: "My recipes"
      assert_select "a[href=?]", my_lists_path, text: "My lists"
      assert_select "a[href=?]", my_profile_path, text: "My profile"
      assert_select "a[href=?][data-turbo-method='delete']", session_path, text: "Log out"
    end
    get my_lists_url
    assert_response :success
    assert_select "h2", text: "Work in progress"
    get my_profile_url
    assert_response :success
    assert_select "dd", text: users(:one).email_address
  end
end
