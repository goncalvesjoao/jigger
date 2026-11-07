class CreateRecipeUtensils < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_utensils do |t|
      t.references :recipe, null: false, foreign_key: true, index: false
      t.references :utensil, null: false, foreign_key: true
      t.text :submitted_text, null: false
      t.string :role, null: false, default: "preparation"
      t.timestamps
    end
    add_check_constraint :recipe_utensils, "role IN ('preparation', 'serving')", name: "recipe_utensils_role"
    add_index :recipe_utensils, [ :recipe_id, :utensil_id ], unique: true
  end
end
