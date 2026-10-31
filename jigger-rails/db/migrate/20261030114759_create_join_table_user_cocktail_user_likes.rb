class CreateJoinTableUserCocktailUserLikes < ActiveRecord::Migration[8.1]
  def change
    create_join_table :users, :user_cocktails do |t|
      t.index [ :user_id, :user_cocktail_id ]
      t.index [ :user_cocktail_id, :user_id ]
    end
  end
end
