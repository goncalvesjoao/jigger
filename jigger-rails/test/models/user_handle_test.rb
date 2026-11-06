require "test_helper"

class UserHandleTest < ActiveSupport::TestCase
  test "handles start from email and normalize with uniqueness" do
    user = User.create!(email_address: "private@example.com", password: "password")
    assert_equal "private", user.handle
    assert_equal "private", user.favorites_collection.visibility
    user.update!(handle: " Mika_New ")
    assert_equal "mika_new", user.handle
    assert_not users(:two).update(handle: "MIKA_NEW")
    assert_not user.update(handle: "invalid handle")
  end
  test "automatic handles avoid collisions and reserve Jigger attribution" do
    user = User.create!(email_address: "mika@different.example", password: "password")
    assert_match(/\Amika-[a-f0-9]+\z/, user.handle)
    assert_not users(:one).update(handle: "jigger")
    assert users(:jigger).jigger_account?
  end
end
