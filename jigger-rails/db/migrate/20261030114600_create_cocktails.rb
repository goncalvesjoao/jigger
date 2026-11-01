class CreateCocktails < ActiveRecord::Migration[8.1]
  def change
    create_table :cocktails do |t|
      t.references :user, foreign_key: true
      t.references :parent_cocktail, foreign_key: { to_table: :cocktails }
      t.boolean :official, null: false, default: false
      t.string :language, null: false, default: "und"
      t.string :visibility, null: false, default: "private"
      t.string :publication_state, null: false, default: "draft"
      t.integer :preparation_time_seconds
      t.integer :servings, default: 1
      t.string :preparation_method
      t.string :source_reference
      t.string :source_url
      t.date :source_published_on
      t.text :source_date_note
      t.datetime :published_at
      t.timestamps
    end
    add_index :cocktails, [ :visibility, :publication_state ]
    add_index :cocktails, :published_at
    add_check_constraint :cocktails, "visibility IN ('private', 'public')", name: "cocktails_visibility"
    add_check_constraint :cocktails, "publication_state IN ('draft', 'published')", name: "cocktails_publication_state"
    add_check_constraint :cocktails, "servings IS NULL OR servings > 0", name: "cocktails_positive_servings"
    add_check_constraint :cocktails, "preparation_time_seconds IS NULL OR preparation_time_seconds >= 0", name: "cocktails_preparation_time"
    add_check_constraint :cocktails, "preparation_method IS NULL OR preparation_method IN ('shaken', 'stirred', 'built', 'blended')", name: "cocktails_preparation_method"
    add_check_constraint :cocktails, "parent_cocktail_id IS NULL OR parent_cocktail_id != id", name: "cocktails_not_own_parent"
  end
end
