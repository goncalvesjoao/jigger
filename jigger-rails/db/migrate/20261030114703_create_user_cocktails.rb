class CreateUserCocktails < ActiveRecord::Migration[8.1]
  def change
    create_table :user_cocktails do |t|
      t.string :name, null: false, default: ""
      t.string :language, null: false, default: "und"
      t.references :cocktail, foreign_key: true
      t.integer :preparation_time_seconds
      t.references :user, null: false, foreign_key: true
      t.string :visibility, null: false, default: "private"
      t.string :publication_state, null: false, default: "draft"
      t.timestamps
    end
    add_check_constraint :user_cocktails, "visibility IN ('private', 'public')", name: "user_cocktails_visibility"
    add_check_constraint :user_cocktails, "publication_state IN ('draft', 'published')", name: "user_cocktails_publication_state"
    add_check_constraint :user_cocktails, "preparation_time_seconds IS NULL OR preparation_time_seconds >= 0", name: "user_cocktails_preparation_time"
    add_check_constraint :user_cocktails, "publication_state != 'published' OR (cocktail_id IS NOT NULL AND length(trim(name)) > 0 AND language != 'und')", name: "user_cocktails_published_identity"
    add_index :user_cocktails, [ :visibility, :publication_state ]
  end
end
