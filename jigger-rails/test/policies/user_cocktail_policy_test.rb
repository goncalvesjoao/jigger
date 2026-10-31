require "test_helper"

class UserCocktailPolicyTest < ActiveSupport::TestCase
  test "everyone can read user_cocktails but only signed in users can create" do
    [ nil, users(:one), users(:two) ].each do |user|
      policy = UserCocktailPolicy.new(user, UserCocktail)
      assert policy.index?
      assert UserCocktailPolicy.new(user, user_cocktails(:one)).show?
      assert_equal user.present?, policy.new?
      assert_equal user.present?, policy.create?
    end
  end

  test "only the owner can change a user_cocktail" do
    [ nil, users(:one), users(:two) ].each do |user|
      policy = UserCocktailPolicy.new(user, user_cocktails(:one))
      [ :edit?, :update?, :destroy? ].each do |action|
        assert_equal user == users(:one), policy.public_send(action)
      end
    end
  end
end
