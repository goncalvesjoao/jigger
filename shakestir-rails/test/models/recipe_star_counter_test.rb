require "test_helper"

class RecipeStarCounterTest < ActiveSupport::TestCase
  setup do
    @recipe = recipes(:one)
    @favorites = users(:one).favorites_collection
  end

  test "only Favorites memberships update the counter and duplicate saves do not increment it" do
    regular = users(:one).collections.create!(name: "Weekend")
    regular.collection_recipes.create!(recipe: @recipe)
    assert_equal 0, @recipe.reload.stars_count
    membership = @favorites.collection_recipes.find_or_create_by!(recipe: @recipe)
    @favorites.collection_recipes.find_or_create_by!(recipe: @recipe)
    assert_equal 1, @recipe.reload.stars_count
    users(:two).favorites_collection.collection_recipes.create!(recipe: @recipe)
    assert_equal 2, @recipe.reload.stars_count
    regular.destroy!
    assert_equal 2, @recipe.reload.stars_count
    membership.destroy!
    assert_equal 1, @recipe.reload.stars_count
  end

  test "membership and counter changes roll back together" do
    CollectionRecipe.transaction(requires_new: true) do
      @favorites.collection_recipes.create!(recipe: @recipe)
      assert_equal 1, @recipe.reload.stars_count
      raise ActiveRecord::Rollback
    end
    assert_equal 0, @recipe.reload.stars_count
    membership = @favorites.collection_recipes.create!(recipe: @recipe)
    CollectionRecipe.transaction(requires_new: true) do
      membership.destroy!
      assert_equal 0, @recipe.reload.stars_count
      raise ActiveRecord::Rollback
    end
    assert_equal 1, @recipe.reload.stars_count
    assert CollectionRecipe.exists?(membership.id)
  end

  test "deleting an account decrements stars through its Favorites collection" do
    fan = User.create!(email_address: "fan@example.com", password: "password")
    fan.favorites_collection.collection_recipes.create!(recipe: @recipe)
    assert_equal 1, @recipe.reload.stars_count
    fan.destroy!
    assert_equal 0, @recipe.reload.stars_count
  end

  test "membership and collection identities cannot change and drift the counter" do
    membership = @favorites.collection_recipes.create!(recipe: @recipe)
    assert_not membership.update(recipe: recipes(:two))
    assert_not membership.update(collection: users(:two).favorites_collection)
    assert_not @favorites.update(system_key: nil)
    assert_equal 1, @recipe.reload.stars_count
    assert_equal 0, recipes(:two).stars_count
    assert @favorites.reload.update(name: "Renamed favorites")
    assert_equal 1, @recipe.reload.stars_count
  end
  test "destroying stale copies of a membership decrements only once" do
    membership = @favorites.collection_recipes.create!(recipe: @recipe)
    stale = CollectionRecipe.find(membership.id)
    membership.destroy!
    stale.destroy!
    membership.destroy!
    assert_equal 0, @recipe.reload.stars_count
  end
end
