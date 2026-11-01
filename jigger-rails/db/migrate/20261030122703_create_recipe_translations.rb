class CreateRecipeTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_translations do |t|
      t.references :recipe, null: false, foreign_key: true, index: false
      t.string :locale, null: false
      t.string :name
      t.string :normalized_name
      t.timestamps
    end
    add_index :recipe_translations, [ :recipe_id, :locale ], unique: true
    add_index :recipe_translations, [ :locale, :normalized_name ]
    add_check_constraint :recipe_translations, "length(trim(locale)) > 0", name: "recipe_translations_locale"
    add_check_constraint :recipe_translations, "normalized_name IS NULL OR length(trim(normalized_name)) > 0", name: "recipe_translations_normalized_name"
  end
end
