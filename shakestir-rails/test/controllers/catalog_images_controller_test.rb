require "test_helper"
require_relative "../test_helpers/photo_test_helper"
require "vips"

class CatalogImagesControllerTest < ActionDispatch::IntegrationTest
  include PhotoTestHelper

  test "ingredient and utensil images have public original and bounded variant delivery" do
    [ [ ingredients(:one), :ingredient_image_url ], [ utensils(:jigger), :utensil_image_url ] ].each do |catalog, route|
      catalog.update!(image: photo_upload)
      [ [ :original, [ 640, 480 ], "image/png" ], [ :card, [ 320, 240 ], "image/webp" ], [ :detail, [ 640, 480 ], "image/webp" ] ].each do |size, dimensions, mime|
        get public_send(route, catalog, size: size)
        assert_response :found
        assert_includes response.headers["Cache-Control"], "no-store"
        assert_includes response.location, "/rails/active_storage/disk/"
        follow_redirect!
        assert_response :success
        assert_equal mime, response.media_type
        decoded = Vips::Image.new_from_buffer(response.body, "")
        assert_equal dimensions, [ decoded.width, decoded.height ]
      end
      catalog.update!(image: photo_upload("small.png"))
      get public_send(route, catalog, size: :card)
      assert_response :found
      follow_redirect!
      decoded = Vips::Image.new_from_buffer(response.body, "")
      assert_equal [ 24, 16 ], [ decoded.width, decoded.height ]
      get public_send(route, catalog, size: :arbitrary)
      assert_response :not_found
    end
  end

  test "catalog photos appear with submitted requirements on the existing recipe detail page" do
    ingredient = ingredients(:one)
    utensil = utensils(:jigger)
    ingredient.update!(image: photo_upload)
    utensil.update!(image: photo_upload)
    recipe = recipes(:one)
    get recipe_url(recipe)
    assert_response :success
    assert_select "img[src=?]", ingredient_image_path(ingredient, size: :card)
    assert_select "img[src=?]", utensil_image_path(utensil, size: :card)
    assert_select "span[lang=en]", text: recipe.recipe_ingredients.sole.submitted_text
    assert_select "span[lang=en]", text: recipe.recipe_utensils.sole.submitted_text
    recipe.update!(visibility: "private")
    get recipe_url(recipe)
    assert_response :forbidden
    get ingredient_image_url(ingredient)
    assert_response :found
    follow_redirect!
    assert_response :success
  end

  test "missing and unusable catalog photos return not found and writes have no routes" do
    [ [ ingredients(:one), :ingredient_image_url, "/ingredients" ], [ utensils(:jigger), :utensil_image_url, "/utensils" ] ].each do |catalog, route, prefix|
      catalog.image.detach
      get public_send(route, catalog)
      assert_response :not_found
      sign_in_as(users(:one))
      post prefix, params: { image: photo_upload }
      assert_response :not_found
      patch public_send(route, catalog), params: { image: photo_upload }
      assert_response :not_found
      catalog.update!(image: photo_upload)
      catalog.translations.where(locale: "en").delete_all
      sign_out
      get public_send(route, catalog)
      assert_response :not_found
    end
  end

  test "malformed shared attachments cannot publish a private recipe blob through catalog routes" do
    private_recipe = recipes(:one)
    private_recipe.update!(visibility: "private", image: photo_upload)
    [ [ ingredients(:one), :ingredient_image_url ], [ utensils(:jigger), :utensil_image_url ] ].each do |catalog, route|
      # Simulate old/imported data bypassing the fresh-upload setter.
      catalog.image.detach
      attachment = ActiveStorage::Attachment.create!(name: "image", record: catalog, blob: private_recipe.image.blob)
      [ :original, :card, :detail ].each do |size|
        get public_send(route, catalog, size: size)
        assert_response :not_found
      end
      attachment.delete
    end
    get recipe_image_url(private_recipe)
    assert_response :forbidden
    sign_in_as(users(:one))
    get recipe_image_url(private_recipe)
    assert_response :found
    follow_redirect!
    assert_response :success
    sign_out
    get "/rails/active_storage/blobs/redirect/#{private_recipe.image.blob.signed_id}/photo.png"
    assert_response :not_found
  end
end
