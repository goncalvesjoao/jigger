require "test_helper"

class SpaCsrfTest < ActionDispatch::IntegrationTest
  setup do
    @previous_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @previous_forgery_protection
  end

  test "guest bootstrap token authorizes login and rotated tokens authorize mutations and logout" do
    get session_url(format: :json)
    assert_response :success
    assert_nil response.parsed_body.fetch("data")
    guest_token = response.parsed_body.fetch("metadata").fetch("csrf_token")
    assert guest_token.present?
    assert_includes response.headers.fetch("Cache-Control"), "no-store"
    post session_url, params: { email_address: users(:one).email_address, password: "password" },
      headers: { "X-CSRF-Token" => guest_token }, as: :json
    assert_response :success
    assert_equal users(:one).id, response.parsed_body.fetch("data").fetch("id")
    token = response.parsed_body.fetch("metadata").fetch("csrf_token")
    assert_no_difference "Collection.count" do
      post collections_url, params: { collection: { name: "Old token" } },
        headers: { "X-CSRF-Token" => guest_token }, as: :json
      assert_response :unprocessable_content
      post collections_url, params: { collection: { name: "No token" } }, as: :json
      assert_response :unprocessable_content
      post collections_url, params: { collection: { name: "Bad token" } },
        headers: { "X-CSRF-Token" => "invalid" }, as: :json
      assert_response :unprocessable_content
    end
    post collections_url, params: { collection: { name: "Valid token" } },
      headers: { "X-CSRF-Token" => token }, as: :json
    assert_response :created
    # The same token can authorize multiple mutations; no bootstrap per request.
    patch collection_url(response.parsed_body.fetch("data").fetch("id")),
      params: { collection: { name: "Updated" } }, headers: { "X-CSRF-Token" => token }, as: :json
    assert_response :success
    delete session_url, headers: { "X-CSRF-Token" => token }, as: :json
    assert_response :success
    assert_nil response.parsed_body.fetch("data")
    logout_token = response.parsed_body.fetch("metadata").fetch("csrf_token")
    assert logout_token.present?
    assert cookies[:session_id].blank?
    post session_url, params: { email_address: users(:one).email_address, password: "password" },
      headers: { "X-CSRF-Token" => token }, as: :json
    assert_response :unprocessable_content
    post session_url, params: { email_address: users(:one).email_address, password: "password" },
      headers: { "X-CSRF-Token" => logout_token }, as: :json
    assert_response :success
  end

  test "guest registration requires CSRF and returns identity with a usable fresh token" do
    get session_url(format: :json)
    token = response.parsed_body.fetch("metadata").fetch("csrf_token")
    params = { user: { email_address: "spa-csrf@example.com", password: "password", password_confirmation: "password" } }
    assert_no_difference "User.count" do
      post registration_url, params: params, as: :json
      assert_response :unprocessable_content
    end
    assert_difference "User.count", 1 do
      post registration_url, params: params, headers: { "X-CSRF-Token" => token }, as: :json
      assert_response :created
    end
    assert_equal User.find_by!(email_address: "spa-csrf@example.com").id, response.parsed_body.fetch("data").fetch("id")
    new_token = response.parsed_body.fetch("metadata").fetch("csrf_token")
    delete session_url, headers: { "X-CSRF-Token" => new_token }, as: :json
    assert_response :success
  end

  test "JSON credentials and registration validation errors retain guest state" do
    get session_url(format: :json)
    token = response.parsed_body.fetch("metadata").fetch("csrf_token")
    post session_url, params: { email_address: users(:one).email_address, password: "wrong" },
      headers: { "X-CSRF-Token" => token }, as: :json
    assert_response :unauthorized
    assert response.parsed_body.fetch("errors").key?("base")
    post registration_url, params: { user: { email_address: "invalid", password: "password" } },
      headers: { "X-CSRF-Token" => token }, as: :json
    assert_response :unprocessable_content
    assert response.parsed_body.fetch("errors").key?("email_address")
    get session_url(format: :json)
    assert_nil response.parsed_body.fetch("data")
  end

  test "password reset requires CSRF and returns a fresh token usable for sign in" do
    user = users(:one)
    reset_token = user.password_reset_token
    get session_url(format: :json)
    csrf_token = response.parsed_body.fetch("metadata").fetch("csrf_token")
    attributes = { password: "reset password", password_confirmation: "reset password" }
    assert_no_changes -> { user.reload.password_digest } do
      put password_url(reset_token), params: attributes, as: :json
      assert_response :unprocessable_content
      assert_match /CSRF/, response.parsed_body.fetch("errors").fetch("base").sole
    end
    put password_url(reset_token), params: attributes, headers: { "X-CSRF-Token" => csrf_token }, as: :json
    assert_response :success
    fresh_token = response.parsed_body.fetch("metadata").fetch("csrf_token")
    post session_url, params: { email_address: user.email_address, password: "reset password" },
      headers: { "X-CSRF-Token" => fresh_token }, as: :json
    assert_response :success
    assert_equal user.id, response.parsed_body.fetch("data").fetch("id")
  end
end
