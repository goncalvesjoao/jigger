class UserCocktailIngredient < ApplicationRecord
  belongs_to :user_cocktail
  belongs_to :ingredient

  validates :submitted_text, :language, presence: true
  validates :quantity, numericality: { greater_than: 0 }, allow_nil: true
  validates :measuring_unit, presence: true, if: -> { quantity.present? }
end
