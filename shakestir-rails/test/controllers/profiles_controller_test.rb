require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.update!(display_name: "Jo’s bar", bio: "Usually mixing something citrusy.")
    @public_collection = @user.collections.create!(name: "Public picks", visibility: "public")
    @private_collection = @user.collections.create!(name: "Secret picks")
    @draft = @user.recipes.create!(name: "Work in progress", visibility: "public")
    @private_recipe = @user.recipes.create!(name: "Personal pour")
    @public_collection.recipes << recipes(:one)
    @public_collection.recipes << @private_recipe
  end

  test "every profile is public and exposes only public content to guests" do
    get profile_url(@user)
    assert_response :success
    assert_select "h1", text: "Jo’s bar"
    assert_select ".profile-meta span", text: "@mika"
    assert_public_content_only
    assert_not_includes response.body, Digest::SHA256.hexdigest(@user.email_address)
    assert_select "a[href=?]", edit_my_profile_path, count: 0
  end

  test "owners see only public content on both profile routes and can still manage private content elsewhere" do
    sign_in_as(@user)
    [ my_profile_url, profile_url(@user) ].each do |url|
      get url
      assert_response :success
      assert_public_content_only
      assert_select "a[href=?]", edit_my_profile_path
      assert_select ".profile-library-links", count: 0
    end
    get my_recipes_url
    assert_select "#recipe_#{@draft.id}"
    assert_select "#recipe_#{@private_recipe.id}"
    get my_collections_url
    assert_select "a[href=?]", collection_path(@private_collection)
  end

  test "signed in visitors and admins receive the same public content" do
    [ false, true ].each do |admin|
      users(:two).update!(admin: admin)
      sign_in_as(users(:two))
      get profile_url(@user)
      assert_response :success
      assert_public_content_only
      assert_select "a[href=?]", edit_my_profile_path, count: 0
    end
  end

  test "profile edits require authentication and only update permitted own attributes" do
    get edit_my_profile_url
    assert_redirected_to new_session_url
    patch my_profile_url, params: { user: { display_name: "Not allowed" } }
    assert_redirected_to new_session_url
    sign_in_as(@user)
    get edit_my_profile_url
    assert_response :success
    assert_select "input[name='user[profile_visibility]']", count: 0
    assert_not_includes response.body, @user.email_address
    patch my_profile_url, params: { id: users(:two).id, user: { display_name: "New name", bio: "New bio", profile_visibility: "private", admin: true, email_address: "changed@example.com" } }
    assert_redirected_to my_profile_url
    assert_equal "New name", @user.reload.display_name
    assert_equal "New bio", @user.bio
    assert_not @user.admin?
    assert_equal "one@example.com", @user.email_address
    assert_nil users(:two).display_name
    sign_out
    get profile_url(@user)
    assert_response :success
  end

  test "invalid settings retain saved values and report errors" do
    sign_in_as(@user)
    patch my_profile_url, params: { user: { display_name: "A" * 81, bio: "B" * 281 } }
    assert_response :unprocessable_content
    assert_select ".library-errors[role='alert']"
    assert_equal "Jo’s bar", @user.reload.display_name
  end

  private
    def assert_public_content_only
      assert_select "a[href=?]", collection_path(@private_collection), count: 0
      assert_select "#recipe_#{@draft.id}, #recipe_#{@private_recipe.id}, #recipe_#{recipes(:two).id}", count: 0
      assert_select "#recipe_#{recipes(:one).id}"
      assert_select "a.library-card[href=?]", collection_path(@public_collection) do
        assert_select ".library-card-meta", text: /1 recipe/
      end
      assert_not_includes response.body, @user.email_address
    end
end
