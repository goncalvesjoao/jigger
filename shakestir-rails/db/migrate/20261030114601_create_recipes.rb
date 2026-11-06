class CreateRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.references :cocktail, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :language, null: false, default: "und"
      t.string :visibility, null: false, default: "private"
      t.string :publication_state, null: false, default: "draft"
      t.integer :preparation_time_seconds
      t.integer :servings, default: 1
      t.string :preparation_method
      t.string :source_reference
      t.string :source_url
      t.integer :stars_count, null: false, default: 0
      t.datetime :published_at
      t.timestamps
    end
    add_index :recipes, [ :visibility, :publication_state ]
    add_index :recipes, :published_at
    add_check_constraint :recipes, "stars_count >= 0", name: "recipes_nonnegative_stars_count"
    add_check_constraint :recipes, "visibility IN ('private', 'public')", name: "recipes_visibility"
    add_check_constraint :recipes, "publication_state IN ('draft', 'published')", name: "recipes_publication_state"
    add_check_constraint :recipes, "servings IS NULL OR servings > 0", name: "recipes_positive_servings"
    add_check_constraint :recipes, "preparation_time_seconds IS NULL OR preparation_time_seconds >= 0", name: "recipes_preparation_time"
    add_check_constraint :recipes, "preparation_method IS NULL OR preparation_method IN ('shaken', 'stirred', 'built', 'blended')", name: "recipes_preparation_method"
  end
end
