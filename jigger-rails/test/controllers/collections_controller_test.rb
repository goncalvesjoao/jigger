require "test_helper"

class CollectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @collection = users(:one).collections.create!(name: "Weekend")
  end

  test "private collections are hidden and public collections filter unreadable recipes" do
    @collection.recipes << recipes(:one)
    recipes(:one).update!(visibility: "private", publication_state: "draft")
    get collection_url(@collection)
    assert_response :not_found
    @collection.update!(visibility: "public")
    get collection_url(@collection)
    assert_response :success
    assert_select "#recipe_#{recipes(:one).id}", count: 0
    sign_in_as(users(:one))
    get collection_url(@collection)
    assert_select "#recipe_#{recipes(:one).id}"
  end

  test "only owners can edit collections or add recipes" do
    sign_in_as(users(:two))
    patch collection_url(@collection), params: { collection: { name: "Changed" } }
    assert_response :not_found
    post collection_recipes_url, params: { collection_id: @collection.id, recipe_id: recipes(:two).id }
    assert_response :not_found
  end

  test "owners create collections and save and remove recipes without duplicates" do
    sign_in_as(users(:one))
    post collections_url, params: { collection: { name: "Party", visibility: "public", user_id: users(:two).id } }
    collection = users(:one).collections.find_by!(name: "Party")
    assert_equal "public", collection.visibility
    2.times do
      post collection_recipes_url, params: { collection_id: collection.id, recipe_id: recipes(:one).id }
      assert_redirected_to collection_url(collection)
    end
    assert_equal 1, collection.recipes.count
    delete collection_collection_recipe_url(collection, recipes(:one))
    assert_empty collection.recipes.reload
  end

  test "picker creates a collection and saves the recipe in one request" do
    sign_in_as(users(:one))
    assert_difference "Collection.count" do
      assert_difference "CollectionRecipe.count" do
        post collection_recipes_url, params: { recipe_id: recipes(:one).id, new_collection: { name: "After work", visibility: "public" } }, as: :json
      end
    end
    assert_response :success
    collection = users(:one).collections.find_by!(name: "After work")
    assert_equal collection.id, response.parsed_body["id"]
    assert_equal true, response.parsed_body["saved"]
    assert_equal "public", collection.visibility
    assert_includes collection.recipes, recipes(:one)
  end

  test "invalid new collections return errors without saving" do
    sign_in_as(users(:one))
    assert_no_difference [ "Collection.count", "CollectionRecipe.count" ] do
      post collection_recipes_url, params: { recipe_id: recipes(:one).id, new_collection: { name: "", visibility: "private" } }, as: :json
    end
    assert_response :unprocessable_content
    assert_match "Name", response.parsed_body["error"]
  end

  test "recipe image has a dialog picker for the signed in users collections" do
    sign_in_as(users(:one))
    get recipe_url(recipes(:one))
    assert_response :success
    assert_select ".detail-visual button.collection-trigger[aria-haspopup='dialog']"
    assert_select "dialog.collection-dialog" do
      assert_select "button[name='collection_id'][value=?]", @collection.id.to_s, text: /Weekend/
      assert_select "input[name='new_collection[name]']"
      assert_select "select[name='new_collection[visibility]'] option[selected][value='private']"
    end
    assert_select "select[name='collection_id']", count: 0
  end

  test "picker reflects saved membership after adding removing and adding again" do
    sign_in_as(users(:one))
    2.times do
      post collection_recipes_url, params: { collection_id: @collection.id, recipe_id: recipes(:one).id }, as: :json
      assert_response :success
      assert_equal true, response.parsed_body["saved"]
      get recipe_url(recipes(:one))
      assert_select "button.collection-choice[value=?][aria-pressed='true']", @collection.id.to_s do
        assert_select ".collection-choice-indicator", text: "✓"
      end
      assert_select ".collection-trigger span", text: "✓"
      delete collection_collection_recipe_url(@collection, recipes(:one)), as: :json
      assert_response :success
      assert_equal false, response.parsed_body["saved"]
      assert_not @collection.recipes.exists?(recipes(:one).id)
      get recipe_url(recipes(:one))
      assert_select "button.collection-choice[value=?][aria-pressed='false']", @collection.id.to_s
      assert_select ".collection-trigger span", text: "+"
    end
  end

  test "removal requires ownership and repeated removal is harmless" do
    @collection.recipes << recipes(:one)
    sign_in_as(users(:two))
    delete collection_collection_recipe_url(@collection, recipes(:one)), as: :json
    assert_response :not_found
    assert @collection.recipes.exists?(recipes(:one).id)
    sign_in_as(users(:one))
    2.times do
      delete collection_collection_recipe_url(@collection, recipes(:one)), as: :json
      assert_response :success
      assert_equal false, response.parsed_body["saved"]
    end
  end

  test "library shows recipe previews counts and visibility without exposing hidden recipes" do
    @collection.recipes << recipes(:one)
    @collection.recipes << recipes(:two)
    recipes(:two).update!(visibility: "private", publication_state: "draft")
    sign_in_as(users(:one))
    get my_collections_url
    assert_response :success
    assert_select "a.library-card[href=?]", collection_path(@collection) do
      assert_select "h2", text: "Weekend"
      assert_select ".library-card-meta", text: /1 recipe/
      assert_select ".library-visibility", text: "Private"
      assert_select ".library-artwork-tile", count: 4
    end
  end

  test "collection editor explains visibility and groups destructive actions separately" do
    sign_in_as(users(:one))
    get new_collection_url
    assert_response :success
    assert_select "input[type='radio'][value='private'][checked]"
    assert_select "input[type='radio'][value='public']"
    assert_select "a.library-cancel[href=?]", my_collections_path
    get edit_collection_url(@collection)
    assert_response :success
    assert_select ".library-danger form[action=?]", collection_path(@collection)
    patch collection_url(@collection), params: { collection: { name: "", visibility: "public" } }
    assert_response :unprocessable_content
    assert_select ".library-errors[role='alert']"
    assert_select "input[type='radio'][value='public'][checked]"
  end

  test "public visitors see collection contents without management controls" do
    @collection.update!(visibility: "public")
    get collection_url(@collection)
    assert_response :success
    assert_select ".library-detail-heading h1", text: "Weekend"
    assert_select ".library-empty a[href=?]", cocktails_path
    assert_select "a[href=?]", edit_collection_path(@collection), count: 0
    assert_select ".library-remove", count: 0
  end

  test "unreadable recipes cannot be saved" do
    recipes(:two).update!(visibility: "private", publication_state: "draft")
    sign_in_as(users(:one))
    post collection_recipes_url, params: { collection_id: @collection.id, recipe_id: recipes(:two).id }
    assert_response :not_found
    assert_empty @collection.recipes
  end
end
