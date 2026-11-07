class CreateTechniques < ActiveRecord::Migration[8.1]
  def change
    create_table :techniques do |t|
      t.string :name
      t.text :description
      t.text :instructions
      t.text :tip
      t.string :normalized_name
      t.string :slug, null: false
      t.timestamps
    end
    add_index :techniques, :normalized_name
    add_index :techniques, :slug, unique: true
    add_check_constraint :techniques, "length(trim(slug)) > 0", name: "techniques_slug"

    create_table :recipe_techniques do |t|
      t.references :recipe, null: false, foreign_key: true, index: false
      t.references :technique, null: false, foreign_key: true
      t.timestamps
    end
    add_index :recipe_techniques, [ :recipe_id, :technique_id ], unique: true
  end
end
