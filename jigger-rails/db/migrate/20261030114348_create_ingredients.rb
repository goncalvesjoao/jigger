class CreateIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredients do |t|
      t.string :category, null: false, default: "other"
      t.string :alcohol_status, null: false, default: "unknown"
      t.decimal :alcohol_by_volume, precision: 5, scale: 2
      t.timestamps
    end
    add_check_constraint :ingredients,
      "category IN ('spirit', 'liqueur', 'wine', 'beer', 'mixer', 'juice', 'syrup', 'fruit', 'dairy', 'herb', 'spice', 'ice', 'other')",
      name: "ingredients_category"
    add_check_constraint :ingredients,
      "alcohol_status IN ('alcoholic', 'non_alcoholic', 'unknown')",
      name: "ingredients_alcohol_status"
    add_check_constraint :ingredients,
      "alcohol_by_volume IS NULL OR (alcohol_by_volume >= 0 AND alcohol_by_volume <= 100)",
      name: "ingredients_alcohol_by_volume_range"
  end
end
