require "test_helper"

class ReactPasswordMailerTest < ActionMailer::TestCase
  test "only frontend-requested reset mail uses configured frontend origin" do
    previous = ENV["SHAKESTIR_FRONTEND_URL"]
    ENV["SHAKESTIR_FRONTEND_URL"] = "https://recipes.example.test"
    frontend = PasswordsMailer.with(frontend: true).reset(users(:one))
    assert_includes frontend.html_part.body.to_s, "https://recipes.example.test/passwords/"
    assert_includes frontend.text_part.body.to_s, "https://recipes.example.test/passwords/"
    html_flow = PasswordsMailer.reset(users(:one))
    assert_not_includes html_flow.html_part.body.to_s, "https://recipes.example.test"
  ensure
    ENV["SHAKESTIR_FRONTEND_URL"] = previous
  end
end
