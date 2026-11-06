require "test_helper"
require_relative "../../test_helpers/photo_test_helper"

class Admin::CatalogControllerTest < ActionDispatch::IntegrationTest
  include PhotoTestHelper

  setup do
    users(:one).update!(admin: true)
    sign_in_as(users(:one))
    @cocktail = Cocktail.create!(name: "Margarita", description: "English description")
  end

  test "catalog dashboards list search show and edit the four resources" do
    get admin_root_url
    assert_response :success
    { cocktails: @cocktail, ingredients: ingredients(:one), utensils: utensils(:jigger), recipes: recipes(:one) }.each do |collection, record|
      path = "/admin/#{collection}"
      get path
      assert_response :success
      assert_select "a[href=?]", "#{path}/#{record.id}", minimum: 1
      get path, params: { search: record.display_name }
      assert_response :success
      get "#{path}/new"
      assert_response :success
      assert_select "input[type=file]"
      get "#{path}/#{record.id}"
      assert_response :success
      get "#{path}/#{record.id}/edit"
      assert_response :success
      assert_select "form[enctype='multipart/form-data']"
    end
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/admin/users", method: :get)
    end
  end

  test "admin assets are delivered by the existing asset pipeline" do
    get admin_root_url
    assets = css_select("link[rel=stylesheet], script[src]").filter_map do |element|
      path = element["href"] || element["src"]
      path if path&.include?("/assets/administrate/")
    end
    assert_operator assets.size, :>=, 2
    assets.each do |path|
      get path
      assert_response :success
    end
  end

  test "admins create catalog records with photos and English content is required first" do
    [ Ingredient, Utensil ].each do |type|
      path = "/admin/#{type.model_name.route_key}"
      assert_difference("#{type}.count") do
        post path, params: { type.model_name.param_key => { name: "New #{type}", image: photo_upload } }
      end
      assert_response :redirect
      assert type.last.image.attached?
      assert_equal "New #{type}", type.last.translation_for(:en).name
    end
    assert_no_difference("Ingredient.count") do
      post admin_ingredients_url, params: { content_locale: "ja", ingredient: { name: "日本語", image: photo_upload } }
    end
    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /English translation/
  end

  test "catalog access requires an admin for every resource" do
    sign_out
    get admin_root_url
    assert_redirected_to new_session_url
    users(:one).update!(admin: false)
    sign_in_as(users(:one))
    { cocktails: @cocktail, ingredients: ingredients(:one), utensils: utensils(:jigger), recipes: recipes(:one) }.each do |collection, record|
      get "/admin/#{collection}"
      assert_response :forbidden
      patch "/admin/#{collection}/#{record.id}", params: { record.model_name.param_key => { name: "Tampered" } }
      assert_response :forbidden
      assert_not_equal "Tampered", record.reload.name
      delete "/admin/#{collection}/#{record.id}"
      assert_response :forbidden
      assert record.class.exists?(record.id)
    end
  end

  test "translations show exact locale values and preserve English and shared photos" do
    get admin_cocktails_url(content_locale: "ja")
    assert_select "td", text: "Margarita"
    get edit_admin_cocktail_url(@cocktail, content_locale: "ja")
    assert_response :success
    assert_select "input[name='cocktail[name]'][value]", count: 0
    assert_select "textarea[name='cocktail[description]']", text: ""
    patch admin_cocktail_url(@cocktail, content_locale: "ja"), params: { cocktail: { name: "マルガリータ", description: "日本語の説明", image: "" } }
    assert_redirected_to admin_cocktail_url(@cocktail, content_locale: "ja")
    assert_equal "Margarita", @cocktail.reload.name
    assert_equal "English description", @cocktail.description
    assert_equal "日本語の説明", @cocktail.translation_for(:ja).description
    get admin_cocktails_url, params: { search: "マルガリータ" }
    assert_select "a[href=?]", admin_cocktail_path(@cocktail), minimum: 1
    get admin_cocktails_url, params: { search: "absent-name" }
    assert_select "a[href=?]", admin_cocktail_path(@cocktail), count: 0
    get edit_admin_cocktail_url(@cocktail, content_locale: "../invalid")
    assert_response :bad_request
  end

  test "translated ingredient and utensil forms preserve required English names" do
    [ ingredients(:one), utensils(:jigger) ].each do |record|
      path = "/admin/#{record.model_name.route_key}/#{record.id}"
      english_name = record.name
      patch path, params: { content_locale: "ja", record.model_name.param_key => { name: "日本語", description: "説明" } }
      assert_response :see_other
      assert_equal english_name, record.reload.name
      assert_equal "日本語", record.translation_for(:ja).name
      patch path, params: { record.model_name.param_key => { name: "" } }
      assert_response :unprocessable_content
      assert_equal english_name, record.reload.name
    end
  end

  test "photo uploads use protected previews preserve blank submissions and reject invalid replacements" do
    [ @cocktail, ingredients(:one), utensils(:jigger), recipes(:one) ].each do |record|
      path = "/admin/#{record.model_name.route_key}/#{record.id}"
      key = record.model_name.param_key
      patch path, params: { key => { image: photo_upload } }
      assert_response :see_other
      blob = record.reload.image.blob
      get "#{path}/edit"
      assert_select "img[src=?]", public_send("#{key}_image_path", record, size: :card)
      patch path, params: { key => { image: "" } }
      assert_response :see_other
      assert_equal blob.id, record.reload.image.blob.id
      patch path, params: { key => { image: photo_upload("truncated.jpg", "image/jpeg") } }
      assert_response :unprocessable_content
      assert_equal blob.id, record.reload.image.blob.id
      patch path, params: { key => { image: blob.signed_id } }
      assert_response :bad_request
      assert_equal blob.id, record.reload.image.blob.id
    end
  end

  test "admin recipe forms manage owners and require ownership" do
    reference = recipes(:one)
    recipe = recipes(:two)
    reference.update!(cocktail: @cocktail, user: users(:jigger))
    get edit_admin_recipe_url(recipe)
    assert_select "select[name='recipe[user_id]'] option[value=?]", users(:two).id.to_s
    patch admin_recipe_url(recipe), params: { recipe: { cocktail_id: @cocktail.id } }
    assert_response :redirect
    assert_equal users(:two), recipe.reload.user
    patch admin_recipe_url(recipe), params: { recipe: { user_id: "" } }
    assert_response :unprocessable_content
    assert_equal users(:two), recipe.reload.user
    patch admin_recipe_url(recipe), params: { recipe: { user_id: users(:one).id, name: "Admin edited" } }
    assert_redirected_to admin_recipe_url(recipe)
    assert_equal users(:one), recipe.reload.user
    post admin_recipes_url, params: { recipe: { user_id: users(:one).id, name: "New draft", language: "en" } }
    assert_response :redirect
    assert_equal users(:one), Recipe.last.user
  end
end
