class CreateCocktailIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :cocktail_ingredients do |t|
      t.belongs_to :cocktail, null: false, foreign_key: true
      t.belongs_to :ingredient, null: false, foreign_key: true
      t.integer :quantity
      t.string :measuring_unit

      t.timestamps
    end
  end
end
