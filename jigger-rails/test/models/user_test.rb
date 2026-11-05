require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "new users receive a private Favorites collection" do
    user = User.create!(email_address: "favorites@example.com", password: "password123")
    assert_equal [ [ "Favorites", "private" ] ], user.collections.pluck(:name, :visibility)
    user.update!(email_address: "renamed@example.com")
    assert_equal 1, user.collections.count
  end

  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end
end
