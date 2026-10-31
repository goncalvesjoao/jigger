class UtensilAlias < ApplicationRecord
  include LookupName

  belongs_to :utensil, inverse_of: :utensil_aliases
  validates :normalized_name, uniqueness: { scope: [ :utensil_id, :language ] }
  validate do
    errors.add(:utensil, "cannot change an alias identity") if persisted? && will_save_change_to_utensil_id?
  end
end
