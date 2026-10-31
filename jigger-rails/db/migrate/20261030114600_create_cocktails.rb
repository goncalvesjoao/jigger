class CreateCocktails < ActiveRecord::Migration[8.1]
  def change
    create_table :cocktails do |t|
      t.timestamps
    end
  end
end
