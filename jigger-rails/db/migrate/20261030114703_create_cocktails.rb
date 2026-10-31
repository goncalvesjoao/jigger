class CreateCocktails < ActiveRecord::Migration[8.1]
  def change
    create_table :cocktails do |t|
      t.string :name
      t.text :steps
      t.integer :preparation_time_seconds
      t.belongs_to :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
