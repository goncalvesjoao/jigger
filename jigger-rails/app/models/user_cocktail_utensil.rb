class UserCocktailUtensil < ApplicationRecord
  enum :role, {
    preparation: "preparation",
    serving: "serving"
  }, validate: true

  belongs_to :user_cocktail
  belongs_to :utensil

  validates :submitted_text, :language, presence: true
  validates :utensil_id, uniqueness: { scope: :user_cocktail_id }
end
