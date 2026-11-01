class UnifyCocktails < ActiveRecord::Migration[8.1]
  def up
    add_reference :cocktails, :user, foreign_key: true
    add_reference :cocktails, :parent_cocktail, foreign_key: { to_table: :cocktails }
    add_column :cocktails, :official, :boolean, null: false, default: false
    add_column :cocktails, :legacy_user_cocktail_id, :integer
    add_index :cocktails, :legacy_user_cocktail_id, unique: true
    add_column :cocktails, :language, :string, null: false, default: "und"
    add_column :cocktails, :visibility, :string, null: false, default: "private"
    add_column :cocktails, :publication_state, :string, null: false, default: "draft"
    add_column :cocktails, :preparation_time_seconds, :integer
    add_column :cocktails, :servings, :integer, default: 1
    add_column :cocktails, :preparation_method, :string
    add_column :cocktails, :source_reference, :string
    add_column :cocktails, :source_url, :string
    add_column :cocktails, :source_published_on, :date
    add_column :cocktails, :source_date_note, :text
    add_column :cocktails, :published_at, :datetime
    add_column :users, :admin, :boolean, null: false, default: false
    add_index :cocktails, [ :visibility, :publication_state ]
    add_index :cocktails, :published_at

    remove_check_constraint :cocktail_translations, name: "cocktail_translations_english_name"
    execute "UPDATE cocktails SET language = 'en'"
    # Keep canonical IDs and allocate new IDs for owned recipes, including their attachments.
    offset = select_value("SELECT COALESCE(MAX(id), 0) FROM cocktails").to_i
    execute <<~SQL
      INSERT INTO cocktails (id, user_id, parent_cocktail_id, legacy_user_cocktail_id, language,
        visibility, publication_state, preparation_time_seconds, servings, preparation_method,
        source_reference, published_at, created_at, updated_at)
      SELECT id + #{offset}, user_id, cocktail_id, id, language, visibility, publication_state,
        preparation_time_seconds, COALESCE(servings, 1), preparation_method, source_reference,
        published_at, created_at, updated_at FROM user_cocktails
    SQL
    select_all("SELECT * FROM user_cocktails").each do |recipe|
      locale = recipe["language"] == "und" ? "en" : recipe["language"]
      normalized = recipe["name"].to_s.unicode_normalize(:nfkc).downcase.strip.gsub(/\s+/, " ").presence
      execute <<~SQL
        INSERT INTO cocktail_translations (cocktail_id, locale, name, description, normalized_name, created_at, updated_at)
        VALUES (#{recipe["id"].to_i + offset}, #{connection.quote(locale)}, #{connection.quote(recipe["name"])},
          #{connection.quote(recipe["description"])}, #{connection.quote(normalized)}, #{connection.quote(recipe["created_at"])}, #{connection.quote(recipe["updated_at"])})
      SQL
    end
    execute "UPDATE active_storage_attachments SET record_type = 'Cocktail', record_id = record_id + #{offset} WHERE record_type = 'UserCocktail'"

    %i[user_cocktail_ingredients user_cocktail_utensils recipe_steps].each do |table|
      remove_foreign_key table, :user_cocktails
      execute "UPDATE #{table} SET user_cocktail_id = user_cocktail_id + #{offset}"
      rename_column table, :user_cocktail_id, :cocktail_id
      add_foreign_key table, :cocktails
    end
    execute "UPDATE user_cocktails_users SET user_cocktail_id = user_cocktail_id + #{offset}"
    rename_column :user_cocktails_users, :user_cocktail_id, :cocktail_id
    rename_table :user_cocktails_users, :cocktails_users
    rename_table :user_cocktail_ingredients, :cocktail_ingredients
    rename_table :user_cocktail_utensils, :cocktail_utensils
    drop_table :user_cocktails

    add_check_constraint :cocktails, "visibility IN ('private', 'public')", name: "cocktails_visibility"
    add_check_constraint :cocktails, "publication_state IN ('draft', 'published')", name: "cocktails_publication_state"
    add_check_constraint :cocktails, "servings IS NULL OR servings > 0", name: "cocktails_positive_servings"
    add_check_constraint :cocktails, "preparation_time_seconds IS NULL OR preparation_time_seconds >= 0", name: "cocktails_preparation_time"
    add_check_constraint :cocktails, "preparation_method IS NULL OR preparation_method IN ('shaken', 'stirred', 'built', 'blended')", name: "cocktails_preparation_method"
    add_check_constraint :cocktails, "parent_cocktail_id IS NULL OR parent_cocktail_id != id", name: "cocktails_not_own_parent"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Unified recipes must be restored from a backup rather than split and lose new content"
  end
end
