require "test_helper"

class RecipeRedesignTest < ActionDispatch::IntegrationTest
  test "search groups only the search controls and retains its label and query" do
    get recipes_url, params: { q: "Gin" }
    assert_response :success
    assert_select "form.search-form" do
      assert_select "label[for=q]", text: "Search recipes"
      assert_select "div[role=search]" do
        assert_select "input[type=search][name=q][value=Gin]"
        assert_select "input[type=submit][value=Search]"
        assert_select "label", count: 0
      end
    end
    assert_select "form[role=search]", count: 0
    assert_select "a.visually-hidden-focusable[href='#main-content']", text: "Skip to content"
  end

  test "cards show metadata only when a preparation method is available" do
    recipes(:one).update!(preparation_method: "shaken")
    get recipes_url
    assert_select "#recipe_#{recipes(:one).id} .card-meta", text: "Shaken"
    assert_select "#recipe_#{recipes(:two).id} .card-meta", count: 0
    assert_not_includes response.body, "Explore recipe"
    assert_not_includes response.body, "↗"
  end

  test "mixing view preserves exact ordered prose and ingredient text" do
    recipe = recipes(:one)
    recipe.recipe_steps.first.update!(body: "Stir.\n  Keep this spacing.")
    recipe.recipe_steps.create!(position: 2, body: "最後に注ぐ。")
    get recipe_url(recipe)
    assert_response :success
    assert_equal [ "Stir.\n  Keep this spacing.", "最後に注ぐ。" ], css_select(".step-body").map(&:text)
    assert_select ".ingredient-list .submitted-prose", text: "Gin"
    assert_select ".quantity", text: "0.5 oz"
    assert_select "input[type=checkbox][data-action='preparation#update']", count: 2
    assert_select "a.button[href='#ingredients']", text: "Start mixing ↓"
    assert_select "#ingredients a[href='#preparation']"
    assert_select "#preparation a[href='#ingredients']"
    assert_select "progress[max='2'][aria-label='Preparation progress']"
  end

  test "cards distinguish official system recipes from community recipes" do
    recipe = recipes(:one)
    recipe.update!(user: nil, official: true)
    get recipes_url
    assert_select "#recipe_#{recipe.id} .eyebrow", text: "Official recipe"
    assert_select "#recipe_#{recipes(:two).id} .eyebrow", text: "Community recipe"
  end

  test "owner can read an empty draft without broken preparation controls" do
    sign_in_as(users(:one))
    recipe = Recipe.create!(user: users(:one), name: "Empty draft", language: "en")
    get recipe_url(recipe)
    assert_response :success
    assert_select "p", text: "No ingredients listed."
    assert_select "p", text: "No preparation steps listed."
    assert_select ".mixing-progress", count: 0
  end
end
