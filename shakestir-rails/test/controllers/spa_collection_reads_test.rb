require "test_helper"

class SpaCollectionReadsTest < ActionDispatch::IntegrationTest
  test "current user has an explicit guest state and safe signed in identity" do
    get session_url(format: :json)
    assert_response :success
    assert_nil response.parsed_body.fetch("data")
    assert_includes response.headers.fetch("Cache-Control"), "no-store"
    owner = users(:one)
    owner.update!(display_name: "Mika Bar")
    sign_in_as(owner)
    get session_url(format: :json), params: { id: users(:two).id }
    assert_response :success
    data = response.parsed_body.fetch("data")
    assert_equal owner.id, data.fetch("id")
    assert_equal "Mika Bar", data.fetch("name")
    assert_equal owner.favorites_collection.id, data.fetch("favorites_collection_id")
    assert_match %r{gravatar.com/avatar/}, data.fetch("avatar").fetch("url")
    assert_not_includes response.body, owner.email_address
    assert_not_includes response.body, "password_digest"
    sign_out
    get session_url(format: :json)
    assert_nil response.parsed_body.fetch("data")
  end

  test "collection indexes return own choices and renamed Favorites capabilities" do
    owner = users(:one)
    favorites = owner.favorites_collection
    favorites.update!(name: "My stars")
    collection = owner.collections.create!(name: "Weekend", visibility: "public")
    collection.recipes << recipes(:one)
    sign_in_as(owner)
    [ collections_url(format: :json), my_collections_url(format: :json) ].each do |url|
      get url
      assert_response :success
      data = response.parsed_body.fetch("data")
      assert_equal owner.collections.order(:created_at).pluck(:id), data.pluck("id")
      assert_equal owner.collections.count, response.parsed_body.fetch("metadata").fetch("total_count")
      system_collection = data.find { |entry| entry.fetch("id") == favorites.id }
      assert_equal "favorites", system_collection.fetch("system_key")
      assert_equal true, system_collection.fetch("can_edit")
      assert_equal false, system_collection.fetch("can_delete")
      assert_equal false, system_collection.fetch("can_change_visibility")
      normal = data.find { |entry| entry.fetch("id") == collection.id }
      assert_equal true, normal.fetch("can_delete")
      assert_equal 1, normal.fetch("recipe_count")
      assert_equal [ recipes(:one).id ], normal.fetch("previews").pluck("id")
      assert_includes response.headers.fetch("Cache-Control"), "no-store"
    end
    sign_out
    get collections_url(format: :json)
    assert_response :unauthorized
  end

  test "collection details restrict recipes by viewer and preserve membership ordering" do
    owner = users(:one)
    collection = owner.collections.create!(name: "Shared", visibility: "public")
    draft = owner.recipes.create!(name: "Private idea")
    collection.recipes << recipes(:one)
    collection.recipes << draft
    get collection_url(collection, format: :json)
    assert_response :success
    data = response.parsed_body.fetch("data")
    assert_equal owner.id, data.fetch("owner").fetch("id")
    assert_equal false, data.fetch("can_edit")
    assert_equal [ recipes(:one).id ], data.fetch("recipes").pluck("id")
    assert_equal 1, data.fetch("recipe_count")
    assert_equal [ recipes(:one).id ], data.fetch("previews").pluck("id")
    assert_not_includes response.body, owner.email_address
    sign_in_as(owner)
    get collection_url(collection, format: :json)
    data = response.parsed_body.fetch("data")
    assert_equal true, data.fetch("owned")
    assert_equal [ draft.id, recipes(:one).id ], data.fetch("recipes").pluck("id")
    assert_equal 2, data.fetch("recipe_count")
    sign_in_as(users(:two))
    get collection_url(collection, format: :json)
    assert_equal [ recipes(:one).id ], response.parsed_body.fetch("data").fetch("recipes").pluck("id")
    get collection_url(owner.favorites_collection, format: :json)
    assert_response :not_found
    sign_out
    get collection_url(owner.favorites_collection, format: :json)
    assert_response :not_found
  end

  test "recipe saved memberships include only current user's collections and track changes" do
    recipe = recipes(:one)
    owner = users(:one)
    own_collection = owner.collections.create!(name: "My picks")
    other_collection = users(:two).collections.create!(name: "Their private picks")
    own_collection.recipes << recipe
    other_collection.recipes << recipe
    get recipe_url(recipe, format: :json)
    assert_empty response.parsed_body.fetch("saved_collection_ids")
    sign_in_as(owner)
    get recipe_url(recipe, format: :json)
    assert_equal [ own_collection.id ], response.parsed_body.fetch("saved_collection_ids")
    post recipe_star_url(recipe), as: :json
    get recipe_url(recipe, format: :json)
    assert_equal [ own_collection.id, owner.favorites_collection.id ].sort, response.parsed_body.fetch("saved_collection_ids").sort
    delete collection_collection_recipe_url(own_collection, recipe), as: :json
    get recipe_url(recipe, format: :json)
    assert_equal [ owner.favorites_collection.id ], response.parsed_body.fetch("saved_collection_ids")
    sign_in_as(users(:two))
    get recipe_url(recipe, format: :json)
    assert_equal [ other_collection.id ], response.parsed_body.fetch("saved_collection_ids")
  end
end
