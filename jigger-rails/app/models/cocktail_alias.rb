class CocktailAlias < ApplicationRecord
  include LookupName

  belongs_to :cocktail, inverse_of: :cocktail_aliases
  validates :normalized_name, uniqueness: { scope: [ :cocktail_id, :language ] }
  validate do
    errors.add(:cocktail, "cannot change an alias identity") if persisted? && will_save_change_to_cocktail_id?
  end
end
