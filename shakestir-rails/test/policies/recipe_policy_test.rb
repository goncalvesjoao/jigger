require "test_helper"

class RecipePolicyTest < ActiveSupport::TestCase
  test "everyone can read recipes but only signed in users can create" do
    [ nil, users(:one), users(:two) ].each do |user|
      policy = RecipePolicy.new(user, Recipe)
      assert policy.index?
      assert RecipePolicy.new(user, recipes(:one)).show?
      assert_equal user.present?, policy.new?
      assert_equal user.present?, policy.create?
    end
  end

  test "only the owner can change a recipe" do
    [ nil, users(:one), users(:two) ].each do |user|
      policy = RecipePolicy.new(user, recipes(:one))
      [ :edit?, :update?, :destroy? ].each do |action|
        assert_equal user == users(:one), policy.public_send(action)
      end
    end
  end
end
