require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.update!(display_name: "Jo’s bar", bio: "Usually mixing something citrusy.")
    @public_collection = @user.collections.create!(name: "Public picks", visibility: "public")
    @private_collection = @user.collections.create!(name: "Secret picks")
    @draft = @user.recipes.create!(name: "Work in progress", language: "en", visibility: "public")
    @private_recipe = @user.recipes.create!(name: "Personal pour", language: "en")
    @public_collection.recipes << recipes(:one)
    @public_collection.recipes << @private_recipe
  end

  test "profiles default to private and are only visible to their owner" do
    assert_equal "private", @user.profile_visibility
    get profile_url(@user)
    assert_response :not_found
    sign_in_as(users(:two))
    get profile_url(@user)
    assert_response :not_found
    users(:two).update!(admin: true)
    get profile_url(@user)
    assert_response :not_found
    sign_in_as(@user)
    get profile_url(@user)
    assert_response :success
    assert_select "h1", text: "Jo’s bar"
    assert_select "a[href=?]", edit_my_profile_path
  end

  test "public profiles show only public collections and published public recipes" do
    @user.update!(profile_visibility: "public")
    get profile_url(@user)
    assert_response :success
    assert_select "h1", text: "Jo’s bar"
    assert_select ".profile-bio", text: @user.bio
    assert_select "#profile-collections a.library-card[href=?]", collection_path(@public_collection) do
      assert_select ".library-card-meta", text: /1 recipe/
    end
    assert_select "a[href=?]", collection_path(@private_collection), count: 0
    assert_select "#recipe_#{recipes(:one).id}"
    assert_select "#recipe_#{@draft.id}", count: 0
    assert_select "#recipe_#{@private_recipe.id}", count: 0
    assert_select "#recipe_#{recipes(:two).id}", count: 0
    assert_select ".profile-manage, .personal-recipe-actions, .profile-account", count: 0
    assert_select "a[href=?]", edit_my_profile_path, count: 0
    assert_not_includes response.body, @user.email_address
    assert_not_includes response.body, gravatar_hash(@user)
  end

  test "owners see all their content and management links on either profile route" do
    sign_in_as(@user)
    [ my_profile_url, profile_url(@user) ].each do |url|
      get url
      assert_response :success
      assert_select "#recipe_#{@draft.id}"
      assert_select "#recipe_#{@private_recipe.id}"
      assert_select "a[href=?]", edit_recipe_path(@draft)
      assert_select "a[href=?]", edit_collection_path(@private_collection)
      assert_select "a[href=?]", collection_path(@public_collection) do
        assert_select ".library-card-meta", text: /2 recipes/
      end
      assert_select ".profile-account dd", text: @user.email_address
    end
  end

  test "signed in visitors including admins receive only the public view" do
    @user.update!(profile_visibility: "public")
    visitor = users(:two)
    [ false, true ].each do |admin|
      visitor.update!(admin: admin)
      sign_in_as(visitor)
      get profile_url(@user)
      assert_response :success
      assert_select "#recipe_#{@draft.id}, #recipe_#{@private_recipe.id}", count: 0
      assert_select "a[href=?]", collection_path(@private_collection), count: 0
      assert_select "a.library-card[href=?]", collection_path(@public_collection) do
        assert_select ".library-card-meta", text: /1 recipe/
      end
    end
  end

  test "profile settings require authentication and only update permitted own attributes" do
    get edit_my_profile_url
    assert_redirected_to new_session_url
    patch my_profile_url, params: { user: { profile_visibility: "public" } }
    assert_redirected_to new_session_url
    assert_equal "private", @user.reload.profile_visibility
    sign_in_as(@user)
    get edit_my_profile_url
    assert_response :success
    assert_select "input[name='user[profile_visibility]'][value='private'][checked]"
    patch my_profile_url, params: { id: users(:two).id, user: { display_name: "New name", bio: "New bio", profile_visibility: "public", admin: true, email_address: "changed@example.com" } }
    assert_redirected_to my_profile_url
    @user.reload
    assert_equal "New name", @user.display_name
    assert_equal "New bio", @user.bio
    assert @user.public_profile?
    assert_not @user.admin?
    assert_equal "one@example.com", @user.email_address
    assert_equal "private", users(:two).reload.profile_visibility
    patch my_profile_url, params: { user: { profile_visibility: "private" } }
    assert_redirected_to my_profile_url
    sign_out
    get profile_url(@user)
    assert_response :not_found
  end

  test "invalid profile settings retain entered values and report errors" do
    sign_in_as(@user)
    patch my_profile_url, params: { user: { display_name: "A" * 81, bio: "B" * 281, profile_visibility: "invalid" } }
    assert_response :unprocessable_content
    assert_select ".library-errors[role='alert']"
    assert_equal "private", @user.reload.profile_visibility
  end

  private
    def gravatar_hash(user)
      Digest::SHA256.hexdigest(user.email_address)
    end
end
