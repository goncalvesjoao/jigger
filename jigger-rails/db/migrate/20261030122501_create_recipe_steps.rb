class CreateRecipeSteps < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_steps do |t|
      t.references :user_cocktail, null: false, foreign_key: true, index: false
      t.integer :position, null: false
      t.text :body, null: false
      t.timestamps
    end
    add_index :recipe_steps, [ :user_cocktail_id, :position ], unique: true
    add_check_constraint :recipe_steps, "position >= 0", name: "recipe_steps_position"
  end
end
