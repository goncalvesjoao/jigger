class CreateIngredientTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredient_translations do |t|
      t.references :ingredient, null: false, foreign_key: true, index: false
      t.string :locale, null: false
      t.string :name
      t.text :description
      t.string :normalized_name
      t.timestamps
    end
    add_index :ingredient_translations, [ :ingredient_id, :locale ], unique: true
    add_index :ingredient_translations, [ :locale, :normalized_name ]
    add_check_constraint :ingredient_translations, "length(trim(locale)) > 0", name: "ingredient_translations_locale"
    add_check_constraint :ingredient_translations, "locale != 'en' OR (name IS NOT NULL AND length(trim(name)) > 0 AND normalized_name IS NOT NULL AND length(trim(normalized_name)) > 0)", name: "ingredient_translations_english_name"
    add_check_constraint :ingredient_translations, "normalized_name IS NULL OR length(trim(normalized_name)) > 0", name: "ingredient_translations_normalized_name"
  end
end
