class CreateCocktails < ActiveRecord::Migration[8.1]
  def change
    create_table :cocktails do |t|
      t.string :name
      t.text :description
      t.text :history
      t.string :normalized_name
      t.string :source_reference
      t.string :source_url
      t.date :source_published_on
      t.text :source_date_note
      t.references :parent_cocktail, foreign_key: { to_table: :cocktails, on_delete: :nullify }
      t.check_constraint "parent_cocktail_id IS NULL OR parent_cocktail_id != id", name: "cocktails_not_own_parent"
      t.timestamps
    end
    add_index :cocktails, :normalized_name
  end
end
