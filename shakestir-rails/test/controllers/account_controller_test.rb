require "test_helper"

class AccountControllerTest < ActionDispatch::IntegrationTest
  test "account pages require authentication" do
    [ my_recipes_url, my_collections_url, my_profile_url ].each do |url|
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
    assert_select "a.button[href=?]", new_recipe_path, text: /New recipe/
  end

  test "recipe status filters and search stay within the owners library" do
    own_recipe = recipes(:one)
    own_recipe.update!(visibility: "private", publication_state: "draft")
    sign_in_as(users(:one))
    get my_recipes_url, params: { state: "draft", q: own_recipe.display_name }
    assert_response :success
    assert_select "#recipe_#{own_recipe.id}"
    assert_select "#recipe_#{recipes(:two).id}", count: 0
    assert_select ".personal-filters a[aria-current='page']", text: /Drafts/
    assert_select ".personal-state", text: "Draft"
    assert_select ".personal-visibility", text: "Private"
    assert_select "a[href=?]", edit_recipe_path(own_recipe), text: /Continue editing/
    get my_recipes_url, params: { state: "published" }
    assert_select "#recipe_#{own_recipe.id}", count: 0
    get my_recipes_url, params: { q: "no recipe has this name" }
    assert_select ".library-empty h2", text: "No recipes here yet."
  end

  test "unnamed drafts remain discoverable and editable" do
    sign_in_as(users(:one))
    draft = users(:one).recipes.create!(language: "en")
    get my_recipes_url, params: { state: "draft" }
    assert_response :success
    assert_select "#recipe_#{draft.id} h3 a", text: "Untitled recipe"
    assert_select "a[href=?][aria-label='Edit untitled recipe']", edit_recipe_path(draft)
  end

  test "empty recipe library offers a clear creation action" do
    user = User.create!(email_address: "empty-recipes@example.com", password: "password123")
    sign_in_as(user)
    get my_recipes_url
    assert_response :success
    assert_select ".library-empty a[href=?]", new_recipe_path, text: "Create your first recipe"
    assert_select ".personal-toolbar", count: 0
  end

  test "recipe editors provide grouped fields and a route back to the library" do
    sign_in_as(users(:one))
    get new_recipe_url
    assert_response :success
    assert_select "a.library-back[href=?]", my_recipes_path
    assert_select ".recipe-editor-section", count: 4
    assert_select "select[name='recipe[visibility]'] option[selected][value='private']"
    assert_select "select[name='recipe[publication_state]'] option[selected][value='draft']"
    assert_select "input[name='recipe[user_id]']", count: 0
    get edit_recipe_url(recipes(:one))
    assert_response :success
    assert_select "a[href=?]", recipe_path(recipes(:one)), text: "View recipe"
  end

  test "account dropdown and pages" do
    sign_in_as(users(:one))
    get root_url
    assert_select "nav .primary-navigation" do
      assert_select "a[aria-current='page']", text: "Explore"
      assert_select "a[href=?]", my_recipes_path, text: "My recipes"
      assert_select "a[href=?]", my_collections_path, text: "My collections"
    end
    assert_select "nav a[href=?]", new_recipe_path, count: 0
    assert_select "details.account-dropdown" do
      assert_select "summary[aria-label='User account'] img[src=?]", "https://gravatar.com/avatar/#{Digest::SHA256.hexdigest(users(:one).email_address)}?s=80&d=mp"
      assert_select "a[href=?]", my_profile_path, text: "My profile"
      assert_select "a[href=?][data-turbo-method='delete']", session_path, text: "Log out"
    end
    get my_collections_url
    assert_response :success
    assert_select "h1", text: "My collections"
    get my_profile_url
    assert_response :success
    assert_not_includes response.body, users(:one).email_address
    get my_account_url
    assert_response :success
    assert_select ".account-email", text: users(:one).email_address
  end
end
