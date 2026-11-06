# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_05_000000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cocktail_translations", force: :cascade do |t|
    t.integer "cocktail_id", null: false
    t.string "locale", null: false
    t.string "name", null: false
    t.text "description"
    t.text "history"
    t.string "normalized_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cocktail_id", "locale"], name: "index_cocktail_translations_on_cocktail_id_and_locale", unique: true
    t.index ["locale", "normalized_name"], name: "index_cocktail_translations_on_locale_and_normalized_name"
    t.check_constraint "length(trim(locale)) > 0", name: "cocktail_translations_locale"
    t.check_constraint "normalized_name IS NULL OR length(trim(normalized_name)) > 0", name: "cocktail_translations_normalized_name"
  end

  create_table "cocktails", force: :cascade do |t|
    t.string "source_reference"
    t.string "source_url"
    t.date "source_published_on"
    t.text "source_date_note"
    t.integer "parent_cocktail_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_cocktail_id"], name: "index_cocktails_on_parent_cocktail_id"
    t.check_constraint "parent_cocktail_id IS NULL OR parent_cocktail_id != id", name: "cocktails_not_own_parent"
  end

  create_table "collection_recipes", force: :cascade do |t|
    t.integer "collection_id", null: false
    t.integer "recipe_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "recipe_id"], name: "index_collection_recipes_on_collection_id_and_recipe_id", unique: true
    t.index ["collection_id"], name: "index_collection_recipes_on_collection_id"
    t.index ["recipe_id"], name: "index_collection_recipes_on_recipe_id"
  end

  create_table "collections", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.string "visibility", default: "private", null: false
    t.string "system_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "system_key"], name: "index_collections_on_user_id_and_system_key", unique: true
    t.index ["user_id"], name: "index_collections_on_user_id"
    t.check_constraint "length(trim(name)) > 0", name: "collections_name"
    t.check_constraint "visibility IN ('private', 'public')", name: "collections_visibility"
  end

  create_table "ingredient_translations", force: :cascade do |t|
    t.integer "ingredient_id", null: false
    t.string "locale", null: false
    t.string "name"
    t.text "description"
    t.string "normalized_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id", "locale"], name: "index_ingredient_translations_on_ingredient_id_and_locale", unique: true
    t.index ["locale", "normalized_name"], name: "index_ingredient_translations_on_locale_and_normalized_name"
    t.check_constraint "length(trim(locale)) > 0", name: "ingredient_translations_locale"
    t.check_constraint "locale != 'en' OR (name IS NOT NULL AND length(trim(name)) > 0 AND normalized_name IS NOT NULL AND length(trim(normalized_name)) > 0)", name: "ingredient_translations_english_name"
    t.check_constraint "normalized_name IS NULL OR length(trim(normalized_name)) > 0", name: "ingredient_translations_normalized_name"
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "category", default: "other", null: false
    t.string "alcohol_status", default: "unknown", null: false
    t.decimal "alcohol_by_volume", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "alcohol_by_volume IS NULL OR (alcohol_by_volume >= 0 AND alcohol_by_volume <= 100)", name: "ingredients_alcohol_by_volume_range"
    t.check_constraint "alcohol_status IN ('alcoholic', 'non_alcoholic', 'unknown')", name: "ingredients_alcohol_status"
    t.check_constraint "category IN ('spirit', 'liqueur', 'wine', 'beer', 'mixer', 'juice', 'syrup', 'fruit', 'dairy', 'herb', 'spice', 'ice', 'other')", name: "ingredients_category"
  end

  create_table "recipe_ingredients", force: :cascade do |t|
    t.integer "recipe_id", null: false
    t.integer "ingredient_id", null: false
    t.text "submitted_text", null: false
    t.string "language", null: false
    t.integer "position", null: false
    t.boolean "optional", default: false, null: false
    t.string "role", default: "mixing", null: false
    t.text "preparation_note"
    t.decimal "quantity", precision: 12, scale: 4
    t.string "measuring_unit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_recipe_ingredients_on_ingredient_id"
    t.index ["recipe_id", "ingredient_id"], name: "index_recipe_ingredients_on_recipe_id_and_ingredient_id"
    t.index ["recipe_id", "position"], name: "index_recipe_ingredients_on_recipe_and_position", unique: true
    t.check_constraint "position >= 0", name: "recipe_ingredients_position"
    t.check_constraint "quantity IS NULL OR quantity > 0", name: "recipe_ingredients_positive_quantity"
    t.check_constraint "role IN ('mixing', 'garnish', 'rim')", name: "recipe_ingredients_role"
  end

  create_table "recipe_steps", force: :cascade do |t|
    t.integer "recipe_id", null: false
    t.integer "position", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id", "position"], name: "index_recipe_steps_on_recipe_id_and_position", unique: true
    t.check_constraint "position >= 0", name: "recipe_steps_position"
  end

  create_table "recipe_translations", force: :cascade do |t|
    t.integer "recipe_id", null: false
    t.string "locale", null: false
    t.string "name"
    t.string "normalized_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale", "normalized_name"], name: "index_recipe_translations_on_locale_and_normalized_name"
    t.index ["recipe_id", "locale"], name: "index_recipe_translations_on_recipe_id_and_locale", unique: true
    t.check_constraint "length(trim(locale)) > 0", name: "recipe_translations_locale"
    t.check_constraint "normalized_name IS NULL OR length(trim(normalized_name)) > 0", name: "recipe_translations_normalized_name"
  end

  create_table "recipe_utensils", force: :cascade do |t|
    t.integer "recipe_id", null: false
    t.integer "utensil_id", null: false
    t.text "submitted_text", null: false
    t.string "language", null: false
    t.string "role", default: "preparation", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id", "utensil_id"], name: "index_recipe_utensils_on_recipe_id_and_utensil_id", unique: true
    t.index ["utensil_id"], name: "index_recipe_utensils_on_utensil_id"
    t.check_constraint "role IN ('preparation', 'serving')", name: "recipe_utensils_role"
  end

  create_table "recipes", force: :cascade do |t|
    t.integer "cocktail_id"
    t.integer "user_id", null: false
    t.string "language", default: "und", null: false
    t.string "visibility", default: "private", null: false
    t.string "publication_state", default: "draft", null: false
    t.integer "preparation_time_seconds"
    t.integer "servings", default: 1
    t.string "preparation_method"
    t.string "source_reference"
    t.string "source_url"
    t.integer "stars_count", default: 0, null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cocktail_id"], name: "index_recipes_on_cocktail_id"
    t.index ["published_at"], name: "index_recipes_on_published_at"
    t.index ["user_id"], name: "index_recipes_on_user_id"
    t.index ["visibility", "publication_state"], name: "index_recipes_on_visibility_and_publication_state"
    t.check_constraint "preparation_method IS NULL OR preparation_method IN ('shaken', 'stirred', 'built', 'blended')", name: "recipes_preparation_method"
    t.check_constraint "preparation_time_seconds IS NULL OR preparation_time_seconds >= 0", name: "recipes_preparation_time"
    t.check_constraint "publication_state IN ('draft', 'published')", name: "recipes_publication_state"
    t.check_constraint "servings IS NULL OR servings > 0", name: "recipes_positive_servings"
    t.check_constraint "stars_count >= 0", name: "recipes_nonnegative_stars_count"
    t.check_constraint "visibility IN ('private', 'public')", name: "recipes_visibility"
  end

  create_table "recipes_users", id: false, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "recipe_id", null: false
    t.index ["recipe_id", "user_id"], name: "index_recipes_users_on_recipe_id_and_user_id"
    t.index ["user_id", "recipe_id"], name: "index_recipes_users_on_user_id_and_recipe_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "step_mentions", force: :cascade do |t|
    t.integer "recipe_step_id", null: false
    t.integer "ingredient_id"
    t.integer "utensil_id"
    t.integer "start_offset", null: false
    t.integer "end_offset", null: false
    t.text "quoted_text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_step_mentions_on_ingredient_id"
    t.index ["recipe_step_id", "start_offset", "end_offset"], name: "idx_on_recipe_step_id_start_offset_end_offset_4bc8b67b0a", unique: true
    t.index ["utensil_id"], name: "index_step_mentions_on_utensil_id"
    t.check_constraint "(ingredient_id IS NOT NULL AND utensil_id IS NULL) OR (ingredient_id IS NULL AND utensil_id IS NOT NULL)", name: "step_mentions_one_identity"
    t.check_constraint "start_offset >= 0 AND end_offset > start_offset", name: "step_mentions_offsets"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.boolean "admin", default: false, null: false
    t.string "handle", null: false
    t.string "system_key"
    t.string "profile_visibility", default: "private", null: false
    t.string "display_name"
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["handle"], name: "index_users_on_handle", unique: true
    t.index ["system_key"], name: "index_users_on_system_key", unique: true
    t.check_constraint "profile_visibility IN ('private', 'public')", name: "users_profile_visibility"
  end

  create_table "utensil_translations", force: :cascade do |t|
    t.integer "utensil_id", null: false
    t.string "locale", null: false
    t.string "name"
    t.text "description"
    t.string "normalized_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale", "normalized_name"], name: "index_utensil_translations_on_locale_and_normalized_name"
    t.index ["utensil_id", "locale"], name: "index_utensil_translations_on_utensil_id_and_locale", unique: true
    t.check_constraint "length(trim(locale)) > 0", name: "utensil_translations_locale"
    t.check_constraint "locale != 'en' OR (name IS NOT NULL AND length(trim(name)) > 0 AND normalized_name IS NOT NULL AND length(trim(normalized_name)) > 0)", name: "utensil_translations_english_name"
    t.check_constraint "normalized_name IS NULL OR length(trim(normalized_name)) > 0", name: "utensil_translations_normalized_name"
  end

  create_table "utensils", force: :cascade do |t|
    t.string "category", default: "other", null: false
    t.decimal "capacity_milliliters", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "capacity_milliliters IS NULL OR capacity_milliliters > 0", name: "utensils_positive_capacity_milliliters"
    t.check_constraint "category IN ('glassware', 'mixing', 'measuring', 'straining', 'other')", name: "utensils_category"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cocktail_translations", "cocktails"
  add_foreign_key "cocktails", "cocktails", column: "parent_cocktail_id", on_delete: :nullify
  add_foreign_key "collection_recipes", "collections"
  add_foreign_key "collection_recipes", "recipes"
  add_foreign_key "collections", "users"
  add_foreign_key "ingredient_translations", "ingredients"
  add_foreign_key "recipe_ingredients", "ingredients"
  add_foreign_key "recipe_ingredients", "recipes"
  add_foreign_key "recipe_steps", "recipes"
  add_foreign_key "recipe_translations", "recipes"
  add_foreign_key "recipe_utensils", "recipes"
  add_foreign_key "recipe_utensils", "utensils"
  add_foreign_key "recipes", "cocktails"
  add_foreign_key "recipes", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "step_mentions", "ingredients"
  add_foreign_key "step_mentions", "recipe_steps"
  add_foreign_key "step_mentions", "utensils"
  add_foreign_key "utensil_translations", "utensils"
end
