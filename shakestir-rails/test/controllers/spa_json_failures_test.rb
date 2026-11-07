require "test_helper"

class SpaJsonFailuresTest < ActionDispatch::IntegrationTest
  test "JSON authentication and forbidden responses are structured" do
    get my_account_url(format: :json)
    assert_json_error :unauthorized
    assert_nil response.headers["Location"]
    get my_account_url
    assert_redirected_to new_session_url
    sign_in_as(users(:two))
    patch recipe_url(recipes(:one)), params: { recipe: { name: "No" } }, as: :json
    assert_json_error :forbidden
  end

  test "missing records unknown JSON routes and invalid parameters are structured" do
    get recipe_url(-1, format: :json)
    assert_json_error :not_found
    get "/no-such-endpoint.json"
    assert_json_error :not_found
    sign_in_as(users(:one))
    post collections_url, params: {}, as: :json
    assert_json_error :bad_request
    post collections_url(format: :json), params: "{bad json", headers: { "CONTENT_TYPE" => "application/json" }
    assert_json_error :bad_request
    get recipe_image_url(recipes(:one), format: :json, size: "invalid")
    assert_json_error :not_found
  end

  test "recipe and collection membership validation share the field errors envelope" do
    sign_in_as(users(:one))
    post recipes_url, params: { recipe: { servings: 0 } }, as: :json
    assert_json_error :unprocessable_content, field: "servings"
    post collection_recipes_url, params: { recipe_id: recipes(:one).id, new_collection: { name: "" } }, as: :json
    assert_json_error :unprocessable_content, field: "name"
  end

  test "JSON reset requests do not reveal account existence" do
    post passwords_url, params: { email_address: users(:one).email_address }, as: :json
    assert_response :success
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ users(:one) ]
    acknowledgement = response.parsed_body
    assert_no_enqueued_emails do
      post passwords_url, params: { email_address: "missing@example.com" }, as: :json
    end
    assert_response :success
    assert_equal acknowledgement, response.parsed_body
    assert_nil response.headers["Location"]
  end

  test "reset token validation handles valid invalid expired and reused tokens" do
    user = users(:one)
    token = user.password_reset_token
    get edit_password_url(token, format: :json)
    assert_response :success
    assert_equal true, response.parsed_body.fetch("data").fetch("valid")
    get edit_password_url("invalid", format: :json)
    assert_json_error :unprocessable_content
    travel user.password_reset_token_expires_in + 1.second do
      get edit_password_url(token, format: :json)
      assert_json_error :unprocessable_content
    end
    put password_url(token), params: { password: "new password", password_confirmation: "new password" }, as: :json
    assert_response :success
    put password_url(token), params: { password: "another", password_confirmation: "another" }, as: :json
    assert_json_error :unprocessable_content
  end

  test "reset validates passwords and revokes sessions without logging the user in" do
    user = users(:one)
    token = user.password_reset_token
    sign_in_as(user)
    user.sessions.create!
    [ {}, { password: "new" }, { password: "new", password_confirmation: "different" } ].each do |attributes|
      assert_no_changes -> { user.reload.password_digest } do
        put password_url(token), params: attributes, as: :json
        assert_response :unprocessable_content
        assert response.parsed_body.fetch("errors").any?
      end
    end
    put password_url(token), params: { password: "new password", password_confirmation: "new password" }, as: :json
    assert_response :success
    assert user.reload.authenticate("new password")
    assert_empty user.sessions
    assert cookies[:session_id].blank?
    assert response.parsed_body.fetch("metadata").fetch("csrf_token").present?
    get session_url(format: :json)
    assert_nil response.parsed_body.fetch("data")
  end

  test "rate limited authentication and reset requests return JSON and retry guidance" do
    # Both callbacks capture this cache store when their controllers are loaded.
    store = SessionsController.cache_store
    original = store.method(:increment)
    store.define_singleton_method(:increment) { |*args, **options| 11 }
    [ session_url, passwords_url ].each do |url|
      post url, params: { email_address: "missing@example.com", password: "wrong" }, as: :json
      assert_json_error :too_many_requests
      assert_equal "180", response.headers["Retry-After"]
    end
  ensure
    store.define_singleton_method(:increment, original) if store && original
  end

  private
    def assert_json_error(status, field: "base")
      assert_response status
      assert_equal "application/json", response.media_type
      assert_kind_of Array, response.parsed_body.fetch("errors").fetch(field)
    end
end
