require "test_helper"
require_relative "../test_helpers/photo_test_helper"

class CocktailImagesControllerTest < ActionDispatch::IntegrationTest
  include PhotoTestHelper

  setup do
    @cocktail = Cocktail.create!(name: "Margarita")
    recipes(:one).update!(cocktail: @cocktail)
  end

  test "catalog photos appear on discovery and detail pages" do
    @cocktail.update!(image: photo_upload)
    get root_url
    assert_select "img[src=?]", cocktail_image_path(@cocktail, size: :card)
    get cocktail_url(@cocktail)
    assert_select "img[src=?]", cocktail_image_path(@cocktail, size: :detail)
    get cocktail_url(@cocktail, format: :json)
    assert_includes response.parsed_body["image_url"], cocktail_image_path(@cocktail)
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
    recipes(:one).update!(visibility: "private")
    get cocktail_image_url(@cocktail, size: :original)
    assert_response :forbidden
  end
end
