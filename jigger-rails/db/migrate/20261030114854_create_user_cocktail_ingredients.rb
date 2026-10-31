class CreateUserCocktailIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :user_cocktail_ingredients do |t|
      t.references :user_cocktail, null: false, foreign_key: true, index: false
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
    add_check_constraint :user_cocktail_ingredients, "position >= 0", name: "user_cocktail_ingredients_position"
    add_check_constraint :user_cocktail_ingredients, "quantity IS NULL OR quantity > 0", name: "user_cocktail_ingredients_positive_quantity"
    add_check_constraint :user_cocktail_ingredients, "role IN ('mixing', 'garnish', 'rim')", name: "user_cocktail_ingredients_role"
    add_index :user_cocktail_ingredients, [ :user_cocktail_id, :ingredient_id ]
    add_index :user_cocktail_ingredients, [ :user_cocktail_id, :position ], unique: true, name: "index_user_cocktail_ingredients_on_cocktail_and_position"
  end
end
