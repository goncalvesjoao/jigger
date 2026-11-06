require "test_helper"

class RecipeStarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @favorites = @user.favorites_collection.tap { |collection| collection.update!(name: "My renamed favorites") }
  end

  test "stars reuse favorites membership and unstar only the exact recipe" do
    sign_in_as(@user)
    other = @user.collections.create!(name: "Weekend")
    other.collection_recipes.create!(recipe: recipes(:one))
    2.times { post recipe_star_url(recipes(:one)) }
    assert_equal [ recipes(:one).id ], @favorites.recipe_ids
    get recipe_url(recipes(:one))
    assert_select ".mixing-save-actions .recipe-star-button[aria-pressed=true]" do
      assert_select "svg[aria-hidden=true]"
      assert_select "span", text: /Starred|Star/, count: 0
      assert_select ".recipe-star-count", text: "1"
    end
    delete recipe_star_url(recipes(:one))
    assert_empty @favorites.reload.recipe_ids
    assert_equal [ recipes(:one).id ], other.recipe_ids
  end

  test "stars require authentication and cannot save another owner's private recipe" do
    post recipe_star_url(recipes(:one))
    assert_redirected_to new_session_url
    sign_in_as(@user)
    recipes(:two).update!(visibility: "private")
    post recipe_star_url(recipes(:two))
    assert_response :not_found
    assert_empty @favorites.recipe_ids
  end

  test "favorites stays private and cannot be deleted" do
    assert_not @favorites.update(visibility: "public")
    assert_not @favorites.destroy
  end

  test "ShakeStir recipes use the ShakeStir account handle" do
    recipes(:one).update!(user: users(:shakestir))
    get recipe_url(recipes(:one))
    assert_select "h1", text: "MyString"
    get root_url
    assert_select "h3 a[href=?]", recipe_path(recipes(:one)), text: "MyString"
  end

  test "recipe attribution links to its author’s public profile" do
    get recipe_url(recipes(:one))
    assert_select "h1", text: "MyString"
    assert_select "a[href=?]", profile_path(@user)
  end
  test "public counts include only Favorites memberships and never reveal who starred" do
    @favorites.collection_recipes.create!(recipe: recipes(:one))
    users(:two).favorites_collection.collection_recipes.create!(recipe: recipes(:one))
    regular = @user.collections.create!(name: "Weekend")
    regular.collection_recipes.create!(recipe: recipes(:one))
    get root_url
    assert_select "#recipe_#{recipes(:one).id} .card-media .recipe-star a[href=?]", new_session_path do
      assert_select ".recipe-star-count", text: "2"
    end
    get recipe_url(recipes(:one))
    assert_select ".mixing-save-actions .recipe-star-count", text: "2"
    assert_select ".recipe-star [data-user-id]", count: 0
    sign_in_as(users(:two))
    get root_url
    assert_select "#recipe_#{recipes(:one).id} .recipe-star-button[aria-pressed=true]"
  end

  test "JSON toggles return authoritative state and repeated requests are idempotent" do
    sign_in_as(@user)
    2.times do
      post recipe_star_url(recipes(:one)), as: :json
      assert_response :success
      assert_equal true, response.parsed_body["starred"]
      assert_equal 1, response.parsed_body["star_count"]
      assert_equal recipes(:one).id, response.parsed_body["recipe_id"]
    end
    2.times do
      delete recipe_star_url(recipes(:one)), as: :json
      assert_response :success
      assert_equal false, response.parsed_body["starred"]
      assert_equal 0, response.parsed_body["star_count"]
    end
  end

  test "Favorites picker changes return the same star state and count" do
    sign_in_as(@user)
    post collection_recipes_url, params: { collection_id: @favorites.id, recipe_id: recipes(:one).id }, as: :json
    assert_equal true, response.parsed_body["starred"]
    assert_equal 1, response.parsed_body["star_count"]
    assert_equal @favorites.id, response.parsed_body["favorites_collection_id"]
    delete collection_collection_recipe_url(@favorites, recipes(:one)), as: :json
    assert_equal false, response.parsed_body["starred"]
    assert_equal 0, response.parsed_body["star_count"]
  end

  test "HTML toggles return to marketplace search without losing filters" do
    sign_in_as(@user)
    post recipe_star_url(recipes(:one)), headers: { "HTTP_REFERER" => cocktails_url(q: "gin") }
    assert_redirected_to cocktails_url(q: "gin")
  end
  test "signed out marketplace renders cached totals without reading memberships" do
    @favorites.collection_recipes.create!(recipe: recipes(:one))
    membership_queries = []
    subscriber = ->(_name, _start, _finish, _id, payload) do
      membership_queries << payload[:sql] if payload[:sql].match?(/FROM "collection_recipes"/i)
    end
    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { get root_url }
    assert_response :success
    assert_select "#recipe_#{recipes(:one).id} .recipe-star-count", text: "1"
    assert_empty membership_queries
  end
end
