class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false

      t.boolean :admin, null: false, default: false

      t.string :handle, null: false
      t.string :system_key
      t.string :profile_visibility, null: false, default: "private"
      t.string :display_name
      t.text :bio
      t.check_constraint "profile_visibility IN ('private', 'public')", name: "users_profile_visibility"
      t.timestamps
    end
    add_index :users, :email_address, unique: true
    add_index :users, :handle, unique: true
    add_index :users, :system_key, unique: true
  end
end
