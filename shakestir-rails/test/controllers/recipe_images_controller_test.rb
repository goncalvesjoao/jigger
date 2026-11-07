require "test_helper"
require_relative "../test_helpers/photo_test_helper"
require "vips"

class RecipeImagesControllerTest < ActionDispatch::IntegrationTest
  include PhotoTestHelper

  setup do
    @recipe = recipes(:one)
    sign_in_as(users(:one))
    @recipe.update!(image: photo_upload)
  end

  test "multipart upload shows card and detail photos and supports replacement" do
    get new_recipe_url
    assert_select "input[type=file][name='recipe[image]'][accept='image/jpeg,image/png,image/webp']"
    get recipes_url
    assert_select "img[src=?]", recipe_image_path(@recipe, size: :card)
    get recipe_url(@recipe)
    assert_select "img[src=?]", recipe_image_path(@recipe, size: :detail)
    previous_id = @recipe.image.blob.id
    patch recipe_url(@recipe), params: { recipe: { image: photo_upload("photo.webp", "image/webp") } }
    assert_redirected_to recipe_url(@recipe)
    assert_not_equal previous_id, @recipe.reload.image.blob.id
    patch recipe_url(@recipe), params: { recipe: { image: "", name: "Still editable" } }
    assert_redirected_to recipe_url(@recipe)
    assert @recipe.reload.image.attached?
    assert_equal "Still editable", @recipe.name
  end

  test "create with a photo remains an owned private draft" do
    assert_difference("Recipe.count") do
      post recipes_url, params: { recipe: { name: "My photo", image: photo_upload } }
    end
    recipe = Recipe.last
    assert_redirected_to recipe_url(recipe)
    assert recipe.image.attached?
    assert_equal users(:one), recipe.user
    assert_equal "private", recipe.visibility
    assert_equal "draft", recipe.publication_state
    get recipe_image_url(recipe, size: :original)
    assert_response :found
    follow_redirect!
    assert_response :success
  end

  test "original and resized photos use authorized storage redirects without upscaling" do
    [ [ :original, [ 640, 480 ], "image/png" ], [ :card, [ 320, 240 ], "image/webp" ], [ :detail, [ 640, 480 ], "image/webp" ] ].each do |size, dimensions, type|
      get recipe_image_url(@recipe, size: size)
      assert_response :found
      assert_includes response.headers["Cache-Control"], "private"
      assert_includes response.headers["Cache-Control"], "no-store"
      assert_includes response.headers["Vary"], "Cookie"
      assert_includes response.location, "/rails/active_storage/disk/"
      follow_redirect!
      assert_response :success
      assert_equal type, response.media_type
      decoded = Vips::Image.new_from_buffer(response.body, "")
      assert_equal dimensions, [ decoded.width, decoded.height ]
    end
    @recipe.update!(image: photo_upload("small.png"))
    get recipe_image_url(@recipe, size: :card)
    assert_response :found
    follow_redirect!
    decoded = Vips::Image.new_from_buffer(response.body, "")
    assert_equal [ 24, 16 ], [ decoded.width, decoded.height ]
    get recipe_image_url(@recipe, size: :unbounded)
    assert_response :not_found
  end

  test "private and draft originals thumbnails HTML and JSON are owner only" do
    [ { visibility: "private" }, { visibility: "public", publication_state: "draft" } ].each do |state|
      @recipe.update!(state)
      [ nil, users(:two), users(:one) ].each do |viewer|
        viewer ? sign_in_as(viewer) : sign_out
        [ :original, :card, :detail ].each do |size|
          get recipe_image_url(@recipe, size: size)
          assert_response(viewer == users(:one) ? :found : :forbidden)
          assert_includes response.headers["Cache-Control"], "no-store"
        end
        [ :html, :json ].each do |format|
          get recipe_url(@recipe, format: format)
          assert_response(viewer == users(:one) ? :success : :forbidden)
        end
      end
    end
  end

  test "public published photos are public and JSON exposes only the protected photo route" do
    sign_out
    [ :original, :card, :detail ].each do |size|
      get recipe_image_url(@recipe, size: size)
      assert_response :found
    end
    get recipe_url(@recipe, format: :json)
    assert_response :success
    assert_includes response.parsed_body["image_url"], recipe_image_path(@recipe)
    assert_not_includes response.body, @recipe.image.blob.signed_id
    assert_not_includes response.body, @recipe.image.blob.key
    assert_not_includes response.body, "active_storage"
    sign_in_as(users(:one))
    @recipe.update!(visibility: "private")
    sign_out
    get recipe_image_url(@recipe, size: :card)
    assert_response :forbidden
  end

  test "known blob and representation signatures cannot bypass the recipe route" do
    Rails.application.reload_routes!
    blob = @recipe.image.blob
    variant = @recipe.image.variant(:card)
    @recipe.update!(visibility: "private")
    sign_out
    [ "/rails/active_storage/blobs/redirect/#{blob.signed_id}/photo.png",
      "/rails/active_storage/blobs/proxy/#{blob.signed_id}/photo.png",
      "/rails/active_storage/representations/redirect/#{blob.signed_id}/#{variant.variation.key}/photo.webp",
      "/rails/active_storage/representations/proxy/#{blob.signed_id}/#{variant.variation.key}/photo.webp",
      "/rails/active_storage/disk/known-service-token/photo.png" ].each do |path|
      get path
      assert_response :not_found
    end
    storage_routes = Rails.application.routes.routes.select { |route| route.defaults[:controller].to_s.start_with?("active_storage/") }
    assert_equal [ [ "active_storage/disk", "show" ] ], storage_routes.map { |route| route.defaults.values_at(:controller, :action) }
    put "/rails/active_storage/disk/known-service-token"
    assert_response :not_found
    post "/rails/active_storage/direct_uploads"
    assert_response :not_found
  end

  test "failed replacement keeps the existing photo in form and authorized delivery" do
    original = @recipe.image.blob
    patch recipe_url(@recipe), params: { recipe: { image: photo_upload("truncated.jpg", "image/jpeg") } }
    assert_response :unprocessable_content
    assert_select "img[src=?]", recipe_image_path(@recipe, size: :card)
    assert_equal original.id, @recipe.reload.image.blob.id
    get recipe_image_url(@recipe, size: :original)
    assert_response :found
    follow_redirect!
    assert_equal original.download, response.body
    patch recipe_url(@recipe, format: :json), params: { recipe: { image: original.signed_id } }
    assert_response :bad_request
    assert_equal original.id, @recipe.reload.image.blob.id
  end

  test "nonowners cannot upload replacements and missing photos return not found" do
    original = @recipe.image.blob
    sign_in_as(users(:two))
    patch recipe_url(@recipe), params: { recipe: { image: photo_upload("photo.webp", "image/webp") } }
    assert_response :forbidden
    assert_equal original.id, @recipe.reload.image.blob.id
    get recipe_image_url(recipes(:two))
    assert_response :not_found
  end
  test "issued disk URLs survive privacy changes until the normal service expiry" do
    travel_to Time.current.change(usec: 0) do
      get recipe_image_url(@recipe, size: :original)
      assert_response :found
      issued_url = response.location
      @recipe.update!(visibility: "private")
      sign_out
      get recipe_image_url(@recipe, size: :original)
      assert_response :forbidden
      get issued_url
      assert_response :success
      assert_equal "image/png", response.media_type
      travel ActiveStorage.service_urls_expire_in + 1.second
      get issued_url
      assert_response :not_found
    end
  end

  test "signed disk URLs reject tampering and missing stored files" do
    get recipe_image_url(@recipe, size: :original)
    assert_response :found
    issued_url = response.location
    tampered_url = issued_url.sub(/--[a-f0-9]+/, "--deadbeef")
    assert_not_equal issued_url, tampered_url
    get tampered_url
    assert_response :not_found
    @recipe.image.blob.service.delete(@recipe.image.blob.key)
    get issued_url
    assert_response :not_found
    get recipe_image_url(@recipe, size: :card)
    assert_response :not_found
  end

  test "redirect target comes from the storage service without downloading original bytes" do
    service = @recipe.image.blob.service
    destination = "https://storage.example.test/photo.png?signature=temporary"
    service.define_singleton_method(:url) { |*| destination }
    service.define_singleton_method(:download) { |*| raise "redirects must not buffer the original file" }
    get recipe_image_url(@recipe, size: :original, url: "https://untrusted.example.test/")
    assert_redirected_to destination
    assert_includes response.headers["Cache-Control"], "no-store"
  ensure
    service.singleton_class.remove_method(:url)
    service.singleton_class.remove_method(:download)
  end
  test "JSON provides only a readable canonical image as a failed-photo fallback" do
    cocktail = Cocktail.create!(name: "Canonical drink", image: photo_upload)
    @recipe.update!(cocktail: cocktail)
    get recipe_url(@recipe, format: :json)
    assert_response :success
    assert_equal cocktail_image_url(cocktail, size: :detail), response.parsed_body.fetch("fallback_image_url")
    assert_includes response.parsed_body.fetch("image_url"), recipe_image_path(@recipe)
    @recipe.update!(visibility: "private")
    get recipe_url(@recipe, format: :json)
    assert_response :success
    assert_nil response.parsed_body.fetch("fallback_image_url")
  end

end
