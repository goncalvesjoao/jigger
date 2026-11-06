require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "signup links back to login" do
    get new_registration_path
    assert_response :success
    assert_select "a[href=?]", new_session_path, text: "Already have an account? Log in"
  end

  test "signup creates an account and signs in" do
    assert_difference("User.count") do
      post registration_path, params: { user: { email_address: " New@Example.com ", password: "password", password_confirmation: "password" } }
    end
    assert_redirected_to root_path
    assert_equal "new@example.com", User.last.email_address
    assert cookies[:session_id]
    follow_redirect!
    assert_select "a[data-turbo-method=delete]", text: "Log out"
  end

  test "invalid signup shows errors without creating an account" do
    assert_no_difference("User.count") do
      post registration_path, params: { user: { email_address: "invalid", password: "password", password_confirmation: "different" } }
    end
    assert_response :unprocessable_content
    assert_select "[role=alert]"
    assert_nil cookies[:session_id]
  end

  test "duplicate email shows errors" do
    assert_no_difference("User.count") do
      post registration_path, params: { user: { email_address: users(:one).email_address.upcase, password: "password", password_confirmation: "password" } }
    end
    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /already been taken/
  end
end
