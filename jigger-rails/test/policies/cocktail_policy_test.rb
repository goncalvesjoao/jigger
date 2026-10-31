require "test_helper"

class CocktailPolicyTest < ActiveSupport::TestCase
  test "everyone can read cocktails but only signed in users can create" do
    [ nil, users(:one), users(:two) ].each do |user|
      policy = CocktailPolicy.new(user, Cocktail)
      assert policy.index?
      assert policy.show?
      assert_equal user.present?, policy.new?
      assert_equal user.present?, policy.create?
    end
  end

  test "only the owner can change a cocktail" do
    [ nil, users(:one), users(:two) ].each do |user|
      policy = CocktailPolicy.new(user, cocktails(:one))
      [ :edit?, :update?, :destroy? ].each do |action|
        assert_equal user == users(:one), policy.public_send(action)
      end
    end
  end
end
