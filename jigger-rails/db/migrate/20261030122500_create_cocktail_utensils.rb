class CreateCocktailUtensils < ActiveRecord::Migration[8.1]
  def change
    create_table :cocktail_utensils do |t|
      t.references :cocktail, null: false, foreign_key: true, index: false
      t.references :utensil, null: false, foreign_key: true
      t.text :submitted_text, null: false
      t.string :language, null: false
      t.string :role, null: false, default: "preparation"
      t.timestamps
    end
    add_check_constraint :cocktail_utensils, "role IN ('preparation', 'serving')", name: "cocktail_utensils_role"
    add_index :cocktail_utensils, [ :cocktail_id, :utensil_id ], unique: true
  end
end
