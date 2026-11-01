require "test_helper"
require "open3"
require "sqlite3"

class UnifyCocktailsMigrationTest < ActiveSupport::TestCase
  test "migration preserves overlapping IDs nameless drafts references photos and likes" do
    Dir.mktmpdir("jigger-migration") do |directory|
      database = File.join(directory, "migration.sqlite3")
      environment = { "RAILS_ENV" => "test", "DATABASE_URL" => "sqlite3:#{database}", "SCHEMA" => File.join(directory, "schema.rb") }
      output, status = Open3.capture2e(environment, RbConfig.ruby, "bin/rails", "db:migrate", "VERSION=20261030122802")
      assert status.success?, output
      db = SQLite3::Database.new(database)
      db.execute("INSERT INTO users (id, email_address, password_digest, created_at, updated_at) VALUES (1, 'migration@example.com', 'digest', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
      db.execute("INSERT INTO cocktails (id, created_at, updated_at) VALUES (1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
      db.execute("INSERT INTO cocktail_translations (cocktail_id, locale, name, normalized_name, created_at, updated_at) VALUES (1, 'en', 'Parent', 'parent', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
      db.execute("INSERT INTO user_cocktails (id, user_id, cocktail_id, name, language, description, created_at, updated_at) VALUES (1, 1, 1, '  ＧＩＮ  ', 'ja', 'Preserved description', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
      db.execute("INSERT INTO user_cocktails (id, user_id, name, description, created_at, updated_at) VALUES (2, 1, '', 'Nameless draft description', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
      db.execute("INSERT INTO ingredients (id, created_at, updated_at) VALUES (1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
      db.execute("INSERT INTO utensils (id, created_at, updated_at) VALUES (1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
      db.execute("INSERT INTO user_cocktail_ingredients (user_cocktail_id, ingredient_id, submitted_text, language, position, quantity, measuring_unit, created_at, updated_at) VALUES (1, 1, '2 oz gin', 'en', 0, 2, 'oz', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
      db.execute("INSERT INTO user_cocktail_utensils (user_cocktail_id, utensil_id, submitted_text, language, created_at, updated_at) VALUES (1, 1, 'glass', 'en', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
      db.execute("INSERT INTO recipe_steps (user_cocktail_id, position, body, created_at, updated_at) VALUES (1, 0, 'Mix.', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
      db.execute("INSERT INTO step_mentions (recipe_step_id, ingredient_id, start_offset, end_offset, quoted_text, created_at, updated_at) VALUES (1, 1, 0, 3, 'Mix', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
      db.execute("INSERT INTO user_cocktails_users (user_id, user_cocktail_id) VALUES (1, 1)")
      db.execute("INSERT INTO active_storage_blobs (id, key, filename, service_name, byte_size, created_at) VALUES (1, 'migration-photo', 'photo.png', 'test', 1, CURRENT_TIMESTAMP)")
      db.execute("INSERT INTO active_storage_attachments (record_type, record_id, name, blob_id, created_at) VALUES ('UserCocktail', 1, 'image', 1, CURRENT_TIMESTAMP)")
      db.close
      output, status = Open3.capture2e(environment, RbConfig.ruby, "bin/rails", "db:migrate")
      assert status.success?, output
      db = SQLite3::Database.new(database)
      assert_equal [ 1, 1 ], db.get_first_row("SELECT user_id, parent_cocktail_id FROM cocktails WHERE id = 2")
      assert_equal [ "  ＧＩＮ  ", "gin", "ja", "Preserved description" ], db.get_first_row("SELECT name, normalized_name, locale, description FROM cocktail_translations WHERE cocktail_id = 2")
      assert_equal "Nameless draft description", db.get_first_value("SELECT description FROM cocktail_translations WHERE cocktail_id = 3")
      assert_equal 2, db.get_first_value("SELECT cocktail_id FROM recipe_steps")
      assert_equal [ 2, 1, "2 oz gin", 2, "oz" ], db.get_first_row("SELECT cocktail_id, ingredient_id, submitted_text, quantity, measuring_unit FROM cocktail_ingredients")
      assert_equal [ 2, 1, "glass" ], db.get_first_row("SELECT cocktail_id, utensil_id, submitted_text FROM cocktail_utensils")
      assert_equal [ 1, 1, "Mix" ], db.get_first_row("SELECT recipe_step_id, ingredient_id, quoted_text FROM step_mentions")
      assert_equal 2, db.get_first_value("SELECT cocktail_id FROM cocktails_users")
      assert_equal [ "Cocktail", 2, 1 ], db.get_first_row("SELECT record_type, record_id, blob_id FROM active_storage_attachments")
      assert_equal 0, db.get_first_value("SELECT COUNT(*) FROM sqlite_master WHERE name = 'user_cocktails'")
      assert_equal [], db.execute("PRAGMA foreign_key_check")
      db.close
    end
  end
end
