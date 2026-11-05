require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "new users receive a private Favorites collection" do
    user = User.create!(email_address: "favorites@example.com", password: "password123")
    assert_equal [ [ "Favorites", "private" ] ], user.collections.pluck(:name, :visibility)
    user.update!(email_address: "renamed@example.com")
    assert_equal 1, user.collections.count
  end

  test "profile visibility defaults to private and rejects unknown values" do
    user = User.new
    assert_equal "private", user.profile_visibility
    assert_equal "Jigger member", user.profile_name
    user.profile_visibility = "hidden"
    assert_not user.valid?
    assert user.errors[:profile_visibility].any?
  end

  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end
end
