require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "new users receive a private Favorites collection" do
    user = User.create!(email_address: "favorites@example.com", password: "password123")
    assert_equal [ [ "Favorites", "private" ] ], user.collections.pluck(:name, :visibility)
    user.update!(email_address: "renamed@example.com")
    assert_equal 1, user.collections.count
  end

  test "profile names use the public handle when display name is missing" do
    assert_equal "@mika", users(:one).profile_name
    users(:one).update!(display_name: "Mika")
    assert_equal "Mika", users(:one).profile_name
    assert_not User.column_names.include?("profile_visibility")
  end

  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end
end
