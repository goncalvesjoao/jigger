class CreateUserCocktailUtensils < ActiveRecord::Migration[8.1]
  def change
    create_table :user_cocktail_utensils do |t|
      t.references :user_cocktail, null: false, foreign_key: true, index: false
      t.references :utensil, null: false, foreign_key: true
      t.text :submitted_text, null: false
      t.string :language, null: false
      t.string :role, null: false, default: "preparation"
      t.timestamps
    end
    add_check_constraint :user_cocktail_utensils, "role IN ('preparation', 'serving')", name: "user_cocktail_utensils_role"
    add_index :user_cocktail_utensils, [ :user_cocktail_id, :utensil_id ], unique: true
  end
end
