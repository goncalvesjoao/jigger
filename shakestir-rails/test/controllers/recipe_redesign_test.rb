require "test_helper"

class RecipeRedesignTest < ActionDispatch::IntegrationTest
  test "search groups only the search controls and retains its label and query" do
    get recipes_url, params: { q: "Gin" }
    assert_response :success
    assert_select "form.marketplace-search" do
      assert_select "label[for=marketplace-query]", text: "Search recipes"
      assert_select "div[role=search]" do
        assert_select "input[type=search][name=q][value=Gin]"
        assert_select "button[type=submit][aria-label=Search]"
      end
    end
    assert_select "form[role=search]", count: 0
    assert_select "a.visually-hidden-focusable[href='#main-content']", text: "Skip to content"
  end

  test "cards show the available preparation method" do
    recipes(:one).update!(preparation_method: "shaken")
    get recipes_url
    assert_select "#recipe_#{recipes(:one).id} .card-meta span", text: "Shaken"
    assert_select ".card-copy a", text: "Explore recipe", count: 0
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
    assert_select ".mixing-header h1"
    assert_select ".mixing-header a[href='#preparation']", text: "Preparation"
    assert_select ".detail-hero", count: 0
    assert_operator response.body.index('id="ingredients"'), :<, response.body.index('id="preparation"')
    assert_select "progress[max='2'][aria-label='Preparation progress']"
  end

  test "cards identify recipes by author handles" do
    recipe = recipes(:one)
    recipe.update!(user: users(:shakestir))
    get recipes_url
    assert_select "#recipe_#{recipe.id} h3 a", text: "MyString"
    assert_select "#recipe_#{recipes(:two).id} h3 a", text: "MyString"
    assert_no_match(/Official recipe|Community recipe/, response.body)
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
