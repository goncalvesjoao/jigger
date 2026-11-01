class RecipeAlias < ApplicationRecord
  include LookupName

  belongs_to :recipe, inverse_of: :recipe_aliases
  validates :normalized_name, uniqueness: { scope: [ :recipe_id, :language ] }
  validate do
    errors.add(:recipe, "cannot change an alias identity") if persisted? && will_save_change_to_recipe_id?
  end
end
