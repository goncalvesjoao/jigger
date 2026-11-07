require "test_helper"
require_relative "../test_helpers/photo_test_helper"

class AccountDeletionTest < ActionDispatch::IntegrationTest
  include PhotoTestHelper
  include ActiveJob::TestHelper

  test "account details and deletion require authentication" do
    get my_account_url
    assert_redirected_to new_session_url
    assert_no_difference "User.count" do
      delete my_account_url, params: { password: "password" }
      assert_redirected_to new_session_url
    end
  end

  test "My account belongs only to the signed in user regardless of supplied IDs" do
    sign_in_as(users(:one))
    get my_account_url, params: { id: users(:two).id, user_id: users(:two).id }
    assert_response :success
    assert_equal "private, no-store", response.headers["Cache-Control"]
    assert_select ".account-email", text: users(:one).email_address
    assert_not_includes response.body, users(:two).email_address
    assert_select "form[action=?][data-turbo-confirm]", my_account_path do
      assert_select "input[name='_method'][value=delete]"
      assert_select "input[name=password][type=password][required][autocomplete=current-password]"
    end
    assert_select "details.account-dropdown a[href=?]", my_account_path, text: "My account"
    get edit_my_profile_url
    assert_not_includes response.body, users(:one).email_address
  end

  test "missing and incorrect passwords leave the account and content intact" do
    sign_in_as(users(:one))
    [ nil, "incorrect" ].each do |password|
      assert_no_difference [ "User.count", "Recipe.count", "Collection.count", "Session.count" ] do
        delete my_account_url, params: { password: password }
        assert_response :unprocessable_content
        assert_select ".library-errors[role=alert]", text: /Password is incorrect/
      end
    end
  end

  test "deleting an account removes all owned data and legacy joins while preserving other users and catalog records" do
    user = users(:one)
    other = users(:two)
    owned_ids = user.recipe_ids
    step_ids = RecipeStep.where(recipe_id: owned_ids).ids
    collection_ids = user.collection_ids
    user.recipes.create!(name: "Private draft")
    user.favorites_collection.recipes << recipes(:two)
    other.favorites_collection.recipes << recipes(:one)
    user.liked_recipes << recipes(:two)
    other.liked_recipes << recipes(:one)
    mention = recipes(:one).recipe_steps.first.step_mentions.create!(ingredient: ingredients(:one), start_offset: 0, end_offset: 2, quoted_text: "My")
    user.sessions.create!
    sign_in_as(user)
    session_ids = user.session_ids
    catalog_counts = [ Ingredient.count, Utensil.count, Cocktail.count ]

    delete my_account_url, params: { password: "password", id: other.id, user_id: other.id }
    assert_redirected_to root_url
    assert_not User.exists?(user.id)
    assert User.exists?(other.id)
    assert_empty Recipe.where(user_id: user.id)
    assert_empty Collection.where(user_id: user.id)
    assert_empty Session.where(id: session_ids)
    assert_empty RecipeIngredient.where(recipe_id: owned_ids)
    assert_empty RecipeUtensil.where(recipe_id: owned_ids)
    assert_empty RecipeStep.where(id: step_ids)
    assert_not StepMention.exists?(mention.id)
    assert_empty CollectionRecipe.where(collection_id: collection_ids)
    assert_empty CollectionRecipe.where(recipe_id: owned_ids)
    assert_empty other.reload.liked_recipes
    assert_empty other.favorites_collection.recipes
    assert_equal 0, recipes(:two).reload.stars_count
    assert_equal catalog_counts, [ Ingredient.count, Utensil.count, Cocktail.count ]
    assert cookies[:session_id].blank?
    get my_account_url
    assert_redirected_to new_session_url
    get profile_url(user)
    assert_response :not_found
  end

  test "uploaded profile and recipe photos are purged after successful deletion" do
    user = User.create!(email_address: "delete-photos@example.com", password: "password", image: photo_upload)
    recipe = user.recipes.create!(name: "Photo draft", image: photo_upload)
    blobs = [ user.image.blob, recipe.image.blob ]
    sign_in_as(user)
    perform_enqueued_jobs(only: ActiveStorage::PurgeJob) do
      delete my_account_url, params: { password: "password" }
      assert_redirected_to root_url
    end
    assert_empty ActiveStorage::Attachment.where(record_type: "User", record_id: user.id)
    assert_empty ActiveStorage::Attachment.where(record_type: "Recipe", record_id: recipe.id)
    blobs.each do |blob|
      assert_not ActiveStorage::Blob.exists?(blob.id)
      assert_not blob.service.exist?(blob.key)
    end
  end

  test "failed dependent deletion rolls back recipes collections and star counters and keeps the session" do
    user = users(:one)
    user.collections.create!(name: "Cannot delete")
    user.favorites_collection.recipes << recipes(:two)
    sign_in_as(user)
    callback = -> { throw(:abort) if name == "Cannot delete" }
    Collection.before_destroy(callback)
    assert_no_difference [ "User.count", "Recipe.count", "Collection.count", "CollectionRecipe.count", "Session.count" ] do
      delete my_account_url, params: { password: "password" }
      assert_response :unprocessable_content
    end
    assert_equal 1, recipes(:two).reload.stars_count
    get my_account_url
    assert_response :success
  ensure
    Collection.skip_callback(:destroy, :before, callback) if callback
  end
end
