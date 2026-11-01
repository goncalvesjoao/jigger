require "test_helper"
require_relative "../test_helpers/photo_test_helper"

class CocktailImagesControllerTest < ActionDispatch::IntegrationTest
  include PhotoTestHelper

  setup do
    @cocktail = Cocktail.create!(name: "Margarita")
    recipes(:one).update!(cocktail: @cocktail)
  end

  test "admin uploads display on discovery and detail pages and preserve photos on failed edits" do
    users(:one).update!(admin: true)
    sign_in_as(users(:one))
    get edit_admin_cocktail_url(@cocktail)
    assert_select "input[type=file][name='cocktail[image]']"
    patch admin_cocktail_url(@cocktail), params: { cocktail: { image: photo_upload } }
    assert_redirected_to admin_cocktail_url(@cocktail)
    original = @cocktail.reload.image.blob
    get root_url
    assert_select "img[src=?]", cocktail_image_path(@cocktail, size: :card)
    get cocktail_url(@cocktail)
    assert_select "img[src=?]", cocktail_image_path(@cocktail, size: :detail)
    get cocktail_url(@cocktail, format: :json)
    assert_includes response.parsed_body["image_url"], cocktail_image_path(@cocktail)
    patch admin_cocktail_url(@cocktail), params: { cocktail: { image: "", description: "Classic" } }
    assert_equal original.id, @cocktail.reload.image.blob.id
    patch admin_cocktail_url(@cocktail), params: { cocktail: { image: photo_upload("truncated.jpg", "image/jpeg") } }
    assert_response :unprocessable_content
    assert_equal original.id, @cocktail.reload.image.blob.id
    patch admin_cocktail_url(@cocktail), params: { cocktail: { image: original.signed_id } }
    assert_response :bad_request
    patch admin_cocktail_url(@cocktail), params: { cocktail: { image: photo_upload("photo.webp", "image/webp") } }
    assert_redirected_to admin_cocktail_url(@cocktail)
    assert_not_equal original.id, @cocktail.reload.image.blob.id
  end

  test "delivery enforces visibility and rejects missing photos and invalid sizes" do
    get cocktail_image_url(@cocktail)
    assert_response :not_found
    @cocktail.update!(image: photo_upload)
    [ :original, :card, :detail ].each do |size|
      get cocktail_image_url(@cocktail, size: size)
      assert_response :found
      assert_includes response.headers["Cache-Control"], "no-store"
      follow_redirect!
      assert_response :success
    end
    get cocktail_image_url(@cocktail, size: :unbounded)
    assert_response :not_found
    sign_in_as(users(:two))
    patch admin_cocktail_url(@cocktail), params: { cocktail: { image: photo_upload } }
    assert_response :forbidden
    recipes(:one).update!(visibility: "private")
    get cocktail_image_url(@cocktail, size: :original)
    assert_response :forbidden
    users(:two).update!(admin: true)
    get cocktail_image_url(@cocktail, size: :original)
    assert_response :found
  end
end
