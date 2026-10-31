class CreateUtensils < ActiveRecord::Migration[8.1]
  def change
    create_table :utensils do |t|
      t.timestamps
    end
  end
end
