class CreateCocktails < ActiveRecord::Migration[8.1]
  def change
    create_table :cocktails do |t|
      t.string :source_reference
      t.string :source_url
      t.date :source_published_on
      t.text :source_date_note
      t.timestamps
    end
  end
end
