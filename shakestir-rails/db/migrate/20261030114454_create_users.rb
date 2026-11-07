class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false

      t.string :handle, null: false
      t.string :system_key
      t.string :display_name
      t.text :bio
      t.timestamps
    end
    add_index :users, :email_address, unique: true
    add_index :users, :handle, unique: true
    add_index :users, :system_key, unique: true
  end
end
