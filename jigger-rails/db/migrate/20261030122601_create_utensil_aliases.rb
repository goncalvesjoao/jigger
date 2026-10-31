class CreateUtensilAliases < ActiveRecord::Migration[8.1]
  def change
    create_table :utensil_aliases do |t|
      t.references :utensil, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :language, null: false
      t.string :normalized_name, null: false
      t.timestamps
    end
    add_index :utensil_aliases, [ :language, :normalized_name ]
    add_index :utensil_aliases, [ :utensil_id, :language, :normalized_name ], unique: true
    add_check_constraint :utensil_aliases, "length(trim(name)) > 0 AND length(trim(language)) > 0 AND length(trim(normalized_name)) > 0", name: "utensil_aliases_nonblank_names"
  end
end
