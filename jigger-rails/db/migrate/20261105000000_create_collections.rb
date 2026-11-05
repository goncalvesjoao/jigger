class CreateCollections < ActiveRecord::Migration[8.1]
  def up
    create_table :collections do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :visibility, null: false, default: "private"
      t.timestamps
      t.check_constraint "visibility IN ('private', 'public')", name: "collections_visibility"
      t.check_constraint "length(trim(name)) > 0", name: "collections_name"
    end

    create_table :collection_recipes do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.timestamps
      t.index [ :collection_id, :recipe_id ], unique: true
    end

    execute <<~SQL
      INSERT INTO collections (user_id, name, visibility, created_at, updated_at)
      SELECT id, 'Favorites', 'private', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM users
    SQL
  end

  def down
    drop_table :collection_recipes
    drop_table :collections
  end
end
