class CreateStepMentions < ActiveRecord::Migration[8.1]
  def change
    create_table :step_mentions do |t|
      t.references :recipe_step, null: false, foreign_key: true, index: false
      t.references :ingredient, foreign_key: true
      t.references :utensil, foreign_key: true
      t.integer :start_offset, null: false
      t.integer :end_offset, null: false
      t.text :quoted_text, null: false
      t.timestamps
    end
    add_check_constraint :step_mentions, "(ingredient_id IS NOT NULL AND utensil_id IS NULL) OR (ingredient_id IS NULL AND utensil_id IS NOT NULL)", name: "step_mentions_one_identity"
    add_check_constraint :step_mentions, "start_offset >= 0 AND end_offset > start_offset", name: "step_mentions_offsets"
    add_index :step_mentions, [ :recipe_step_id, :start_offset, :end_offset ], unique: true
  end
end
