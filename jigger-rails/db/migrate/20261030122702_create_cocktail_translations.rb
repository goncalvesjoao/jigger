class CreateCocktailTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :cocktail_translations do |t|
      t.references :cocktail, null: false, foreign_key: true, index: false
      t.string :locale, null: false
      t.string :name
      t.text :description
      t.text :history
      t.string :normalized_name
      t.timestamps
    end
    add_index :cocktail_translations, [ :cocktail_id, :locale ], unique: true
    add_index :cocktail_translations, [ :locale, :normalized_name ]
    add_check_constraint :cocktail_translations, "length(trim(locale)) > 0", name: "cocktail_translations_locale"
    add_check_constraint :cocktail_translations, "normalized_name IS NULL OR length(trim(normalized_name)) > 0", name: "cocktail_translations_normalized_name"
  end
end
