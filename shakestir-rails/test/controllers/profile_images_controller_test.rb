require "test_helper"
require_relative "../test_helpers/photo_test_helper"

class ProfileImagesControllerTest < ActionDispatch::IntegrationTest
  include PhotoTestHelper

  setup do
    @user = users(:one)
    @user.update!(display_name: "Mika")
  end

  test "owners upload and replace photos shown on their profile and account menu" do
    sign_in_as(@user)
    patch my_profile_url, params: { user: { image: photo_upload } }
    assert_redirected_to my_profile_url
    assert @user.reload.image.attached?
    first = @user.image.blob_id
    get my_profile_url
    assert_select ".profile-avatar img[src=?]", profile_image_path(@user, size: :card)
    assert_select ".user-avatar[src=?]", profile_image_path(@user, size: :card)
    patch my_profile_url, params: { user: { image: photo_upload("photo.webp", "image/webp") } }
    assert_redirected_to my_profile_url
    assert_not_equal first, @user.reload.image.blob_id
    get profile_image_url(@user, size: :card)
    assert_response :redirect
    assert_equal "private, no-store", response.headers["Cache-Control"]
  end

  test "profile photos are public for guests and signed in visitors" do
    @user.update!(image: photo_upload)
    get profile_image_url(@user, size: :card)
    assert_response :redirect
    assert_equal "private, no-store", response.headers["Cache-Control"]
    get profile_url(@user)
    assert_select ".profile-avatar img[src=?]", profile_image_path(@user, size: :card)
    sign_in_as(users(:two))
    get profile_image_url(@user)
    assert_response :redirect
  end

  test "blank and rejected uploads retain the saved photo and signed IDs are refused" do
    @user.update!(image: photo_upload)
    original_id = @user.image.blob_id
    sign_in_as(@user)
    patch my_profile_url, params: { user: { image: "", display_name: "Changed" } }
    assert_redirected_to my_profile_url
    assert_equal original_id, @user.reload.image.blob_id
    file = Tempfile.new([ "invalid-avatar", ".png" ])
    file.write("Not an image")
    file.flush
    patch my_profile_url, params: { user: { image: Rack::Test::UploadedFile.new(file.path, "image/png") } }
    assert_response :unprocessable_content
    assert_select ".library-errors[role=alert]"
    assert_equal original_id, @user.reload.image.blob_id
    patch my_profile_url, params: { user: { image: @user.image.blob.signed_id } }
    assert_response :bad_request
    assert_equal original_id, @user.reload.image.blob_id
  ensure
    file&.close!
  end

  test "removing a photo restores the avatar and failed profile edits do not remove it" do
    @user.update!(image: photo_upload)
    sign_in_as(@user)
    patch my_profile_url, params: { user: { remove_image: "1", display_name: "x" * 81 } }
    assert_response :unprocessable_content
    assert @user.reload.image.attached?
    patch my_profile_url, params: { user: { remove_image: "1" } }
    assert_redirected_to my_profile_url
    assert_not @user.reload.image.attached?
    get my_profile_url
    assert_select ".profile-avatar img[src*='gravatar.com']"
    get profile_image_url(@user)
    assert_response :not_found
  end

  test "upload controls are labeled and guests cannot change photos" do
    patch my_profile_url, params: { user: { image: photo_upload } }
    assert_redirected_to new_session_url
    assert_not @user.reload.image.attached?
    sign_in_as(@user)
    get edit_my_profile_url
    assert_select "form[enctype='multipart/form-data']"
    assert_select "label[for=user_image]", text: "Profile picture"
    assert_select "input[type=file][name='user[image]'][accept='image/jpeg,image/png,image/webp']"
  end

  test "public profiles without photos use initials without disclosing the email avatar hash" do
    get profile_url(@user)
    assert_select ".profile-avatar span", text: "M"
    assert_select ".profile-avatar img", count: 0
    assert_not_includes response.body, Digest::SHA256.hexdigest(@user.email_address)
  end
end
