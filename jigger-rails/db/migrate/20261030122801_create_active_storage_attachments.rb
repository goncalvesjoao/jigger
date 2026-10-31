class CreateActiveStorageAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :active_storage_attachments do |t|
      t.string :name, null: false
      t.references :record, polymorphic: true, null: false, index: false
      t.references :blob, null: false, foreign_key: { to_table: :active_storage_blobs }
      t.datetime :created_at, null: false
      t.index [ :record_type, :record_id, :name, :blob_id ], unique: true, name: "index_active_storage_attachments_uniqueness"
    end
  end
end
