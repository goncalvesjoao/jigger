class CreateRecipeIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_ingredients do |t|
      t.references :recipe, null: false, foreign_key: true, index: false
      t.references :ingredient, null: false, foreign_key: true
      t.text :submitted_text, null: false
      t.string :language, null: false
      t.integer :position, null: false
      t.boolean :optional, null: false, default: false
      t.string :role, null: false, default: "mixing"
      t.text :preparation_note
      t.decimal :quantity, precision: 12, scale: 4
      t.string :measuring_unit
      t.timestamps
    end
    add_check_constraint :recipe_ingredients, "position >= 0", name: "recipe_ingredients_position"
    add_check_constraint :recipe_ingredients, "quantity IS NULL OR quantity > 0", name: "recipe_ingredients_positive_quantity"
    add_check_constraint :recipe_ingredients, "role IN ('mixing', 'garnish', 'rim')", name: "recipe_ingredients_role"
    add_index :recipe_ingredients, [ :recipe_id, :ingredient_id ]
    add_index :recipe_ingredients, [ :recipe_id, :position ], unique: true, name: "index_recipe_ingredients_on_recipe_and_position"
  end
end
