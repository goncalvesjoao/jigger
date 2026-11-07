class CreateRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.string :name
      t.string :normalized_name
      t.references :cocktail, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :visibility, null: false, default: "private"
      t.string :publication_state, null: false, default: "draft"
      t.integer :servings, default: 1
      t.string :source_reference
      t.string :source_url
      t.integer :stars_count, null: false, default: 0
      t.datetime :published_at
      t.timestamps
    end
    add_index :recipes, :normalized_name
    add_index :recipes, [ :visibility, :publication_state ]
    add_index :recipes, :published_at
    add_check_constraint :recipes, "stars_count >= 0", name: "recipes_nonnegative_stars_count"
    add_check_constraint :recipes, "visibility IN ('private', 'public')", name: "recipes_visibility"
    add_check_constraint :recipes, "publication_state IN ('draft', 'published')", name: "recipes_publication_state"
    add_check_constraint :recipes, "servings IS NULL OR servings > 0", name: "recipes_positive_servings"
  end
end
