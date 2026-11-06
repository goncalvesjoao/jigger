require "test_helper"

class UtensilTest < ActiveSupport::TestCase
  test "category is string-backed and capacity_milliliters is optional but positive" do
    utensil = utensils(:jigger)

    utensil.assign_attributes(category: :measuring, capacity_milliliters: 30.0)
    assert utensil.valid?, utensil.errors.full_messages.join(", ")
    assert_equal "measuring", utensil.category

    utensil.capacity_milliliters = 0
    assert_not utensil.valid?
    assert_includes utensil.errors[:capacity_milliliters], "must be greater than 0"
  end
end
