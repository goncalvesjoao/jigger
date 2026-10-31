class CreateUtensils < ActiveRecord::Migration[8.1]
  def change
    create_table :utensils do |t|
      t.string :category, null: false, default: "other"
      t.decimal :capacity_milliliters, precision: 8, scale: 2
      t.timestamps
    end
    add_check_constraint :utensils,
      "category IN ('glassware', 'mixing', 'measuring', 'straining', 'other')",
      name: "utensils_category"
    add_check_constraint :utensils,
      "capacity_milliliters IS NULL OR capacity_milliliters > 0",
      name: "utensils_positive_capacity_milliliters"
  end
end
