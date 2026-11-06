class CreateTechniques < ActiveRecord::Migration[8.1]
  def change
    create_table :techniques do |t|
      t.string :slug, null: false
      t.timestamps
    end
    add_index :techniques, :slug, unique: true
    add_check_constraint :techniques, "length(trim(slug)) > 0", name: "techniques_slug"

    create_table :technique_translations do |t|
      t.references :technique, null: false, foreign_key: true, index: false
      t.string :locale, null: false
      t.string :name
      t.string :normalized_name
      t.text :description
      t.text :instructions
      t.text :tip
      t.timestamps
    end
    add_index :technique_translations, [ :technique_id, :locale ], unique: true
    add_index :technique_translations, [ :locale, :normalized_name ]
    add_check_constraint :technique_translations, "length(trim(locale)) > 0", name: "technique_translations_locale"
    add_check_constraint :technique_translations, "locale != 'en' OR (name IS NOT NULL AND length(trim(name)) > 0 AND normalized_name IS NOT NULL AND length(trim(normalized_name)) > 0 AND description IS NOT NULL AND length(trim(description)) > 0 AND instructions IS NOT NULL AND length(trim(instructions)) > 0)", name: "technique_translations_english_content"

    create_table :recipe_techniques do |t|
      t.references :recipe, null: false, foreign_key: true, index: false
      t.references :technique, null: false, foreign_key: true
      t.timestamps
    end
    add_index :recipe_techniques, [ :recipe_id, :technique_id ], unique: true
  end
end
