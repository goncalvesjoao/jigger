class EnforceRecipeOwnershipAndOfficialUniqueness < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :recipes, "official = 1 OR user_id IS NOT NULL", name: "recipes_require_owner_unless_official"
    add_index :recipes, :cocktail_id, unique: true, where: "official = 1", name: "index_recipes_one_official_per_cocktail"
  end
end
