class AddParentCocktailToCocktails < ActiveRecord::Migration[8.1]
  def change
    add_reference :cocktails, :parent_cocktail, foreign_key: { to_table: :cocktails, on_delete: :nullify }
    add_check_constraint :cocktails, "parent_cocktail_id IS NULL OR parent_cocktail_id != id", name: "cocktails_not_own_parent"
  end
end
