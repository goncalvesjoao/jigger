require "test_helper"

class TechniquesControllerTest < ActionDispatch::IntegrationTest
  test "guests can read a guide by slug without JavaScript" do
    get technique_url(techniques(:shake))
    assert_response :success
    assert_select "h1", text: "Shake"
    assert_select "h3", text: "How to do it"
    assert_select "h3", text: "Beginner tip"
    assert_select ".technique-instructions", text: /Seal the shaker/
    get technique_url("missing")
    assert_response :not_found
  end

  test "recipe shows only assigned guides beside its source and includes them in JSON" do
    recipe = recipes(:one)
    recipe.techniques << techniques(:shake)
    get recipe_url(recipe)
    assert_response :success
    assert_select ".recipe-footer .recipe-reference-grid > .recipe-techniques" do
      assert_select "a[href=?]", technique_path(techniques(:shake)), text: "Shake"
      assert_select "a[href=?]", technique_path(techniques(:stir)), count: 0
      assert_select "dialog[aria-labelledby] .technique-instructions", text: /Seal the shaker/
    end
    get recipe_url(recipe, format: :json)
    assert_equal [ "shake" ], response.parsed_body.fetch("techniques").pluck("slug")
    recipe.techniques.clear
    get recipe_url(recipe)
    assert_select ".recipe-techniques", count: 0
  end

  test "owners assign and clear techniques while other users cannot change them" do
    recipe = recipes(:one)
    sign_in_as(users(:one))
    get edit_recipe_url(recipe)
    assert_select "input[name='recipe[technique_ids][]'][value=?]", techniques(:shake).id.to_s
    patch recipe_url(recipe), params: { recipe: { technique_ids: [ techniques(:shake).id, techniques(:stir).id ] } }
    assert_response :see_other
    assert_equal %w[shake stir], recipe.reload.techniques.pluck(:slug)
    sign_in_as(users(:two))
    patch recipe_url(recipe), params: { recipe: { technique_ids: [ "" ] } }
    assert_response :forbidden
    assert_equal 2, recipe.reload.techniques.count
    sign_in_as(users(:one))
    patch recipe_url(recipe), params: { recipe: { technique_ids: [ "" ] } }
    assert_response :see_other
    assert_empty recipe.reload.techniques
    post recipes_url, params: { recipe: { name: "New draft", technique_ids: [ techniques(:shake).id ] } }
    assert_response :redirect
    assert_equal [ "shake" ], Recipe.last.techniques.pluck(:slug)
  end

  test "private recipe techniques remain behind recipe permissions" do
    recipe = recipes(:one)
    recipe.update!(visibility: "private")
    recipe.techniques << techniques(:shake)
    get recipe_url(recipe)
    assert_response :forbidden
    get recipe_url(recipe, format: :json)
    assert_response :forbidden
  end
end
