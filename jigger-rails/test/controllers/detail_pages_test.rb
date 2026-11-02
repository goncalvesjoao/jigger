require "test_helper"
require_relative "../test_helpers/photo_test_helper"

class DetailPagesTest < ActionDispatch::IntegrationTest
  include PhotoTestHelper

  setup do
    @cocktail = Cocktail.create!(name: "Margarita", description: "Canonical description", history: "Canonical history",
      source_reference: "Cocktail history", source_url: "https://example.com/cocktail", image: photo_upload)
    @official = recipes(:one)
    @official.update!(cocktail: @cocktail, official: true, image: photo_upload("photo.webp", "image/webp"))
    @community = recipes(:two)
    @community.update!(cocktail: @cocktail, name: "My Margarita", image: photo_upload("photo.jpg", "image/jpeg"))
  end

  test "cocktail hero uses the canonical photo and embeds official preparation without a second hero" do
    get cocktail_url(@cocktail)
    assert_response :success
    assert_select "h1", text: "Margarita", count: 1
    assert_select ".detail-hero", count: 1 do
      assert_select "img[src=?]", cocktail_image_path(@cocktail, size: :detail)
      assert_select "img[src=?]", recipe_image_path(@official, size: :detail), count: 0
    end
    assert_select ".cocktail-details #recipe_#{@official.id} .mixing-layout"
    assert_select ".cocktail-details img[src=?]", recipe_image_path(@official, size: :detail), count: 0
    assert_select ".cocktail-background details summary", text: "History"
    assert_select ".cocktail-background p", text: "Canonical history"
    assert_select "#matching-recipes #recipe_#{@community.id}"
    assert_select "#matching-recipes #recipe_#{@official.id}", count: 0
    assert_unique_ids_and_valid_section_links
  end

  test "recipe hero uses its own photo and includes canonical background and community alternatives" do
    get recipe_url(@official)
    assert_response :success
    assert_select ".detail-hero img[src=?]", recipe_image_path(@official, size: :detail)
    assert_select ".detail-hero img[src=?]", cocktail_image_path(@cocktail, size: :detail), count: 0
    assert_select ".detail-hero p", text: "Canonical description"
    assert_select ".cocktail-background h2 a", text: "Margarita"
    assert_select ".cocktail-background p", text: "Canonical history"
    assert_select ".cocktail-background a[href='https://example.com/cocktail']", text: "Cocktail history"
    assert_select "#matching-recipes #recipe_#{@community.id}"
    assert_select "#matching-recipes #recipe_#{@official.id}", count: 0
    assert_unique_ids_and_valid_section_links
  end

  test "community recipes exclude the current recipe and hide private and draft siblings even for admins" do
    [ { visibility: "private" }, { publication_state: "draft" }, {} ].each do |state|
      recipe = Recipe.new(user: users(:one), cocktail: @cocktail, language: "en", name: "Another variation", steps: "Shake.")
      recipe.recipe_ingredients.build(ingredient: ingredients(:one), submitted_text: "Gin", language: "en")
      recipe.assign_attributes({ visibility: "public", publication_state: "published" }.merge(state))
      recipe.save!
    end
    users(:one).update!(admin: true)
    sign_in_as(users(:one))
    get recipe_url(@community)
    assert_select "#matching-recipes article", count: 1
    assert_select "#matching-recipes #recipe_#{@community.id}", count: 0
    assert_select "#matching-recipes #recipe_#{@official.id}", count: 0
    assert_select ".detail-hero img[src=?]", recipe_image_path(@community, size: :detail)
    assert_unique_ids_and_valid_section_links
  end

  test "missing images never borrow the other record's photo and cocktails without official recipes still work" do
    @community.image.purge
    get recipe_url(@community)
    assert_select ".detail-hero img", count: 0
    assert_select ".detail-hero [aria-label='No photo available']"
    @cocktail.image.purge
    @official.update!(official: false)
    get cocktail_url(@cocktail)
    assert_response :success
    assert_select ".detail-hero img", count: 0
    assert_select ".recipe-summary", count: 0
    assert_select "#matching-recipes article", count: 2
    assert_unique_ids_and_valid_section_links
  end

  test "standalone private drafts remain readable only by authorized users" do
    @community.update!(cocktail: nil, visibility: "private", publication_state: "draft")
    sign_in_as(users(:two))
    get recipe_url(@community)
    assert_response :success
    assert_select ".cocktail-background", count: 0
    assert_select "#matching-recipes", count: 0
    assert_select ".detail-hero img[src=?]", recipe_image_path(@community, size: :detail)
    assert_unique_ids_and_valid_section_links
    sign_out
    get recipe_url(@community)
    assert_response :forbidden
  end

  private
    def assert_unique_ids_and_valid_section_links
      ids = css_select("[id]").map { |element| element["id"] }
      assert_equal ids.uniq, ids
      css_select(".detail-nav a, .detail-actions a").each do |link|
        href = link["href"]
        assert_includes ids, href.delete_prefix("#") if href.start_with?("#")
      end
    end
end
