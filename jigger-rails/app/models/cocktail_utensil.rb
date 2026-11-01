class CocktailUtensil < ApplicationRecord
  enum :role, {
    preparation: "preparation",
    serving: "serving"
  }, validate: true

  belongs_to :cocktail
  belongs_to :utensil

  validates :submitted_text, :language, presence: true
  validates :utensil_id, uniqueness: { scope: :cocktail_id }
end
