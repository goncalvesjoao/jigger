require "test_helper"

class SpaReadEndpointsTest < ActionDispatch::IntegrationTest
  test "guest catalogs return all usable options in picker order" do
    [ [ ingredients_url(format: :json), Ingredient ], [ utensils_url(format: :json), Utensil ] ].each do |url, model|
      expected = model.usable.sort_by { |item| [ item.display_name.downcase, item.id ] }
      assert_not_empty expected
      get url
      assert_response :success
      assert_equal expected.map { |item| { "id" => item.id, "name" => item.display_name } }, response.parsed_body.fetch("data")
      assert_equal expected.size, response.parsed_body.fetch("metadata").fetch("total_count")
      # A record with no catalog photo is not offered as a usable filter option.
      expected.first.image.purge
      get url
      assert_response :success
      assert_not_includes response.parsed_body.fetch("data").pluck("id"), expected.first.id
    end
  end

  test "technique catalog includes every guide sorted by slug" do
    get techniques_url(format: :json)
    assert_response :success
    data = response.parsed_body.fetch("data")
    assert_equal Technique.order(:slug).pluck(:id), data.pluck("id")
    assert_equal Technique.count, response.parsed_body.fetch("metadata").fetch("total_count")
    shake = data.find { |item| item.fetch("id") == techniques(:shake).id }
    assert_equal techniques(:shake).instructions, shake.fetch("instructions")
    assert_equal technique_url(techniques(:shake), format: :json), shake.fetch("url")
  end

  test "private read routes retain their authentication requirement" do
    [ my_account_url(format: :json), my_recipes_url(format: :json), my_profile_url(format: :json) ].each do |url|
      get url
      assert_response :unauthorized
    end
  end

  test "account returns only current account identity and private email" do
    sign_in_as(users(:one))
    get my_account_url(format: :json), params: { id: users(:two).id }
    assert_response :success
    data = response.parsed_body.fetch("data")
    assert_equal users(:one).id, data.fetch("id")
    assert_equal users(:one).email_address, data.fetch("email_address")
    assert_equal %w[display_name email_address handle id name], data.keys.sort
    assert_includes response.headers.fetch("Cache-Control"), "no-store"
  end

  test "my recipes includes own drafts with global status counts and filtered pagination" do
    owner = users(:one)
    25.times { |index| owner.recipes.create!(name: "SPA draft #{index}") }
    counts = owner.recipes.group(:publication_state).count
    sign_in_as(owner)
    get my_recipes_url(format: :json), params: { state: "draft", q: "SPA draft", page: 1 }
    assert_response :success
    data = response.parsed_body.fetch("data")
    metadata = response.parsed_body.fetch("metadata")
    assert_equal 24, data.size
    assert data.all? { |recipe| recipe.fetch("user_id") == owner.id && recipe.fetch("publication_state") == "draft" }
    assert_equal owner.recipes.search("SPA draft").order(updated_at: :desc, id: :desc).limit(24).pluck(:id), data.pluck("id")
    assert_equal 25, metadata.fetch("total_count")
    assert_equal 2, metadata.fetch("next_page")
    assert_equal "draft", metadata.fetch("state")
    assert_equal "SPA draft", metadata.fetch("q")
    assert_equal({ "all" => counts.values.sum, "draft" => counts.fetch("draft", 0),
      "published" => counts.fetch("published", 0) }, metadata.fetch("counts"))
    assert_includes response.headers.fetch("Cache-Control"), "no-store"
    get my_recipes_url(format: :json), params: { state: "draft", q: "SPA draft", page: 2 }
    assert_equal 1, response.parsed_body.fetch("data").size
    assert_nil response.parsed_body.fetch("metadata").fetch("next_page")
    assert_empty data.pluck("id") & response.parsed_body.fetch("data").pluck("id")
    get my_recipes_url(format: :json), params: { state: "invalid", q: "no-matching-recipe" }
    assert_empty response.parsed_body.fetch("data")
    assert_nil response.parsed_body.fetch("metadata").fetch("state")
    assert_equal counts.values.sum, response.parsed_body.fetch("metadata").fetch("counts").fetch("all")
  end

  test "public profiles and owner profile contain only public content and safe identity" do
    owner = users(:one)
    owner.update!(display_name: "Mika Bar", bio: "Citrus drinks")
    draft = owner.recipes.create!(name: "Hidden draft", visibility: "public")
    private_recipe = owner.recipes.create!(name: "Hidden private")
    public_collection = owner.collections.create!(name: "Public picks", visibility: "public")
    private_collection = owner.collections.create!(name: "Private picks")
    public_collection.recipes << [ recipes(:one), draft, private_recipe ]
    private_collection.recipes << recipes(:one)

    [ nil, users(:two), owner ].each do |viewer|
      viewer ? sign_in_as(viewer) : sign_out
      get profile_url(owner, format: :json)
      assert_response :success
      data = response.parsed_body.fetch("data")
      assert_equal "Mika Bar", data.fetch("name")
      assert_equal "Citrus drinks", data.fetch("bio")
      assert_equal viewer == owner, data.fetch("owned")
      assert_equal [ recipes(:one).id ], data.fetch("recipes").pluck("id")
      collection = data.fetch("collections").sole
      assert_equal public_collection.id, collection.fetch("id")
      assert_equal 1, collection.fetch("recipe_count")
      assert_equal [ recipes(:one).id ], collection.fetch("previews").pluck("id")
      assert_nil data.fetch("image_url")
      if viewer == owner
        assert_equal gravatar_hash(owner), URI.parse(data.fetch("avatar").fetch("url")).path.split("/").last
      else
        assert_nil data.fetch("avatar").fetch("url")
        assert_equal "MB", data.fetch("avatar").fetch("initials")
        assert_not_includes response.body, gravatar_hash(owner)
      end
      assert_not_includes response.body, owner.email_address
      assert_not_includes response.body, "password_digest"
      assert_includes response.headers.fetch("Cache-Control"), "no-store"
    end
    get my_profile_url(format: :json)
    assert_response :success
    assert_equal owner.id, response.parsed_body.fetch("data").fetch("id")
    assert_equal true, response.parsed_body.fetch("data").fetch("owned")
  end

  private
    def gravatar_hash(user)
      Digest::SHA256.hexdigest(user.email_address.strip.downcase)
    end
end
