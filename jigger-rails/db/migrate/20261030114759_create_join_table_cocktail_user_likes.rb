class CreateJoinTableCocktailUserLikes < ActiveRecord::Migration[8.1]
  def change
    create_join_table :users, :cocktails do |t|
      t.index [ :user_id, :cocktail_id ]
      t.index [ :cocktail_id, :user_id ]
    end
  end
end
