class CreateCocktailAliases < ActiveRecord::Migration[8.1]
  def change
    create_table :cocktail_aliases do |t|
      t.references :cocktail, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :language, null: false
      t.string :normalized_name, null: false
      t.timestamps
    end
    add_index :cocktail_aliases, [ :language, :normalized_name ]
    add_index :cocktail_aliases, [ :cocktail_id, :language, :normalized_name ], unique: true
    add_check_constraint :cocktail_aliases, "length(trim(name)) > 0 AND length(trim(language)) > 0 AND length(trim(normalized_name)) > 0", name: "cocktail_aliases_nonblank_names"
  end
end
