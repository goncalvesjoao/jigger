require "test_helper"
require_relative "../test_helpers/photo_test_helper"

class SpaMutationsTest < ActionDispatch::IntegrationTest
  include PhotoTestHelper

  setup do
    @owner = users(:one)
    sign_in_as(@owner)
  end

  test "collection JSON create update and delete return data without redirects" do
    post collections_url, params: { collection: { name: "Weekend", visibility: "public", user_id: users(:two).id } }, as: :json
    assert_response :created
    data = response.parsed_body.fetch("data")
    collection = @owner.collections.find(data.fetch("id"))
    assert_equal "Weekend", data.fetch("name")
    assert_equal [], data.fetch("recipes")
    assert_equal collection_url(collection, format: :json), response.headers.fetch("Location")
    collection.recipes << recipes(:one)
    patch collection_url(collection), params: { collection: { name: "Friday", visibility: "private" } }, as: :json
    assert_response :success
    data = response.parsed_body.fetch("data")
    assert_equal "Friday", data.fetch("name")
    assert_equal "private", data.fetch("visibility")
    assert_equal [ recipes(:one).id ], data.fetch("recipes").pluck("id")
    assert_equal 1, data.fetch("recipe_count")
    delete collection_url(collection), as: :json
    assert_response :no_content
    assert_empty response.body
    assert_not Collection.exists?(collection.id)
    assert Recipe.exists?(recipes(:one).id)
  end

  test "collection errors and Favorites restrictions are structured" do
    assert_no_difference "Collection.count" do
      post collections_url, params: { collection: { name: "" } }, as: :json
      assert_response :unprocessable_content
      assert response.parsed_body.fetch("errors").key?("name")
    end
    favorites = @owner.favorites_collection
    patch collection_url(favorites), params: { collection: { visibility: "public" } }, as: :json
    assert_response :unprocessable_content
    assert response.parsed_body.fetch("errors").key?("visibility")
    assert_equal "private", favorites.reload.visibility
    delete collection_url(favorites), as: :json
    assert_response :unprocessable_content
    assert_match /permanent private/, response.parsed_body.fetch("errors").fetch("base").sole
    assert Collection.exists?(favorites.id)
    patch collection_url(favorites), params: { collection: { name: "My stars" } }, as: :json
    assert_response :success
    assert_equal "My stars", response.parsed_body.fetch("data").fetch("name")
    sign_in_as(users(:two))
    patch collection_url(favorites), params: { collection: { name: "Tampered" } }, as: :json
    assert_response :not_found
    delete collection_url(favorites), as: :json
    assert_response :not_found
  end

  test "profile JSON update returns full safe profile and preserves permitted fields" do
    patch my_profile_url, params: { id: users(:two).id, user: { handle: "mika-new", display_name: "New name", bio: "Citrus", email_address: "ignored@example.com" } }, as: :json
    assert_response :success
    data = response.parsed_body.fetch("data")
    assert_equal @owner.id, data.fetch("id")
    assert_equal "New name", data.fetch("name")
    assert_equal "mika-new", data.fetch("handle")
    assert_equal "Citrus", data.fetch("bio")
    assert data.key?("collections")
    assert data.key?("recipes")
    assert_not data.key?("email_address")
    assert_equal "one@example.com", @owner.reload.email_address
    patch my_profile_url, params: { user: { display_name: "x" * 81 } }, as: :json
    assert_response :unprocessable_content
    assert response.parsed_body.fetch("errors").key?("display_name")
    assert_equal "New name", @owner.reload.display_name
  end

  test "multipart profile JSON uploads and removal retain existing rules" do
    patch my_profile_url(format: :json), params: { user: { image: photo_upload } }
    assert_response :success
    assert_equal profile_image_url(@owner, size: :card), response.parsed_body.fetch("data").fetch("image_url")
    blob_id = @owner.reload.image.blob_id
    patch my_profile_url, params: { user: { image: @owner.image.blob.signed_id } }, as: :json
    assert_response :bad_request
    assert response.parsed_body.fetch("errors").key?("image")
    patch my_profile_url, params: { user: { remove_image: "1", display_name: "x" * 81 } }, as: :json
    assert_response :unprocessable_content
    assert_equal blob_id, @owner.reload.image.blob_id
    patch my_profile_url, params: { user: { remove_image: "1" } }, as: :json
    assert_response :success
    assert_nil response.parsed_body.fetch("data").fetch("image_url")
    assert_not @owner.reload.image.attached?
  end

  test "account JSON deletion requires password and clears only current account and sessions" do
    [ nil, "incorrect" ].each do |password|
      assert_no_difference [ "User.count", "Session.count", "Recipe.count", "Collection.count" ] do
        delete my_account_url, params: { password: password }, as: :json
        assert_response :unprocessable_content
        assert_equal [ "is incorrect" ], response.parsed_body.fetch("errors").fetch("password")
      end
    end
    owner_id = @owner.id
    owned_ids = @owner.recipe_ids
    delete my_account_url, params: { password: "password", id: users(:two).id }, as: :json
    assert_response :no_content
    assert_empty response.body
    assert_not User.exists?(owner_id)
    assert_empty Recipe.where(id: owned_ids)
    assert_empty Collection.where(user_id: owner_id)
    assert_empty Session.where(user_id: owner_id)
    assert User.exists?(users(:two).id)
    assert cookies[:session_id].blank?
    get session_url(format: :json)
    assert_nil response.parsed_body.fetch("data")
  end

  test "failed account JSON deletion rolls back content and keeps session" do
    @owner.collections.create!(name: "Cannot delete")
    callback = -> { throw(:abort) if name == "Cannot delete" }
    Collection.before_destroy(callback)
    assert_no_difference [ "User.count", "Recipe.count", "Collection.count", "Session.count" ] do
      delete my_account_url, params: { password: "password" }, as: :json
      assert_response :unprocessable_content
      assert_match /could not be deleted/, response.parsed_body.fetch("errors").fetch("base").join
    end
    get session_url(format: :json)
    assert_equal @owner.id, response.parsed_body.fetch("data").fetch("id")
  ensure
    Collection.skip_callback(:destroy, :before, callback) if callback
  end

  test "guest JSON mutations retain authentication requirement" do
    collection = @owner.favorites_collection
    sign_out
    assert_no_difference [ "User.count", "Collection.count" ] do
      post collections_url, params: { collection: { name: "No" } }, as: :json
      assert_response :unauthorized
      patch collection_url(collection), params: { collection: { name: "No" } }, as: :json
      assert_response :unauthorized
      delete collection_url(collection), as: :json
      assert_response :unauthorized
      patch my_profile_url, params: { user: { display_name: "No" } }, as: :json
      assert_response :unauthorized
      delete my_account_url, params: { password: "password" }, as: :json
      assert_response :unauthorized
    end
  end
end
