class AddProfileToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :profile_visibility, :string, null: false, default: "private"
    add_column :users, :display_name, :string
    add_column :users, :bio, :text
    add_check_constraint :users, "profile_visibility IN ('private', 'public')", name: "users_profile_visibility"
  end
end
