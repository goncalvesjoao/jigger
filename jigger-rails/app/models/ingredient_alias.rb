class IngredientAlias < ApplicationRecord
  include LookupName

  belongs_to :ingredient, inverse_of: :ingredient_aliases
  validates :normalized_name, uniqueness: { scope: [ :ingredient_id, :language ] }
  validate do
    errors.add(:ingredient, "cannot change an alias identity") if persisted? && will_save_change_to_ingredient_id?
  end
end
