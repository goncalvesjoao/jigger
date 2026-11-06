require "test_helper"

class Admin::CocktailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cocktail = Cocktail.create!(name: "Margarita")
  end

  test "guests must sign in and non admins cannot curate cocktails" do
    get new_admin_cocktail_url
    assert_redirected_to new_session_url
    sign_in_as(users(:one))
    get new_admin_cocktail_url
    assert_response :forbidden
    get edit_admin_cocktail_url(@cocktail)
    assert_response :forbidden
    patch admin_cocktail_url(@cocktail), params: { cocktail: { name: "Changed" } }
    assert_response :forbidden
    assert_equal "Margarita", @cocktail.reload.name
    assert_no_difference("Cocktail.count") do
      delete admin_cocktail_url(@cocktail)
      assert_response :forbidden
    end
  end

  test "admin forms submit to admin routes and retain validation errors" do
    users(:one).update!(admin: true)
    sign_in_as(users(:one))
    get new_admin_cocktail_url
    assert_select "form[action=?]", admin_cocktails_path
    post admin_cocktails_url, params: { cocktail: { name: " " } }
    assert_response :unprocessable_content
    assert_select "[role=alert]"
    get edit_admin_cocktail_url(@cocktail)
    assert_select "form[action=?]", admin_cocktail_path(@cocktail)
    patch admin_cocktail_url(@cocktail), params: { cocktail: { name: " " } }
    assert_response :unprocessable_content
    patch admin_cocktail_url(@cocktail), params: { cocktail: { name: "Updated" } }
    assert_redirected_to admin_cocktail_url(@cocktail)
    assert_equal "Updated", @cocktail.reload.name
  end

  test "admin deletion keeps recipes and redirects to the admin list" do
    users(:one).update!(admin: true)
    sign_in_as(users(:one))
    recipes(:one).update!(cocktail: @cocktail)
    assert_no_difference("Recipe.count") do
      assert_difference("Cocktail.count", -1) { delete admin_cocktail_url(@cocktail) }
    end
    assert_redirected_to admin_cocktails_url
    assert_nil recipes(:one).reload.cocktail
  end

  test "admins edit cocktail history and source metadata independently of recipe credits" do
    users(:one).update!(admin: true)
    sign_in_as(users(:one))
    recipe = recipes(:one)
    recipe.update!(cocktail: @cocktail, source_reference: "Recipe author", source_url: "https://example.com/instructions")
    patch admin_cocktail_url(@cocktail), params: { cocktail: {
      description: "A classic sour", history: "Historical account", source_reference: "History book",
      source_url: "https://example.com/history", source_published_on: "1930-01-01", source_date_note: "Year confirmed; day uncertain"
    } }
    assert_redirected_to admin_cocktail_url(@cocktail)
    assert_equal Date.new(1930, 1, 1), @cocktail.reload.source_published_on
    assert_equal "History book", @cocktail.source_reference
    assert_equal "Recipe author", recipe.reload.source_reference
    get cocktail_url(@cocktail)
    assert_select "p", text: "Historical account"
    assert_select "a[href='https://example.com/history']", text: "History book"
    get cocktail_url(@cocktail, format: :json)
    assert_equal "Year confirmed; day uncertain", response.parsed_body["source_date_note"]
    get recipe_url(recipe)
    assert_select "a[href='https://example.com/instructions']", text: "Recipe author"
    assert_select ".cocktail-background a[href='https://example.com/history']", text: "History book"
    assert_select ".recipe-footer a[href='https://example.com/history']", count: 0
    get edit_recipe_url(recipe)
    %w[description history parent_recipe_id source_published_on source_date_note].each do |field|
      assert_select "[name='recipe[#{field}]']", count: 0
    end
    get recipe_url(recipe, format: :json)
    %w[description history parent_recipe_id source_published_on source_date_note].each do |field|
      assert_not response.parsed_body.key?(field)
    end
    assert_equal "https://example.com/instructions", response.parsed_body["source_url"]
  end

  test "public cocktail routes expose only discovery" do
    [ [ "/cocktails", :post ], [ "/cocktails/#{@cocktail.id}", :patch ], [ "/cocktails/#{@cocktail.id}", :delete ], [ "/cocktails/#{@cocktail.id}/edit", :get ] ].each do |path, method|
      assert_raises(ActionController::RoutingError) do
        Rails.application.routes.recognize_path(path, method: method)
      end
    end
  end
end
