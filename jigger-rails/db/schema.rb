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

ActiveRecord::Schema[8.1].define(version: 2026_10_30_122404) do
  create_table "cocktail_ingredients", force: :cascade do |t|
    t.integer "cocktail_id", null: false
    t.integer "ingredient_id", null: false
    t.integer "quantity"
    t.string "measuring_unit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cocktail_id"], name: "index_cocktail_ingredients_on_cocktail_id"
    t.index ["ingredient_id"], name: "index_cocktail_ingredients_on_ingredient_id"
  end

  create_table "cocktails", force: :cascade do |t|
    t.string "name"
    t.text "steps"
    t.integer "preparation_time_seconds"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_cocktails_on_user_id"
  end

  create_table "cocktails_users", id: false, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "cocktail_id", null: false
    t.index ["cocktail_id", "user_id"], name: "index_cocktails_users_on_cocktail_id_and_user_id"
    t.index ["user_id", "cocktail_id"], name: "index_cocktails_users_on_user_id_and_cocktail_id"
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "cocktail_ingredients", "cocktails"
  add_foreign_key "cocktail_ingredients", "ingredients"
  add_foreign_key "cocktails", "users"
  add_foreign_key "sessions", "users"
end
