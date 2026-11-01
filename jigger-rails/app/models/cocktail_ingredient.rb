class CocktailIngredient < ApplicationRecord
  enum :role, {
    mixing: "mixing",
    garnish: "garnish",
    rim: "rim"
  }, validate: true

  belongs_to :cocktail
  belongs_to :ingredient

  before_validation :assign_position, on: :create

  validates :submitted_text, :language, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, uniqueness: { scope: :cocktail_id }
  validates :quantity, numericality: { greater_than: 0 }, allow_nil: true
  validates :measuring_unit, presence: true, if: -> { quantity.present? }

  private
    def assign_position
      return unless position.nil?

      siblings = cocktail&.cocktail_ingredients&.reject { |line| line.equal?(self) || line.marked_for_destruction? } || []
      self.position = siblings.map(&:position).compact.max.to_i + 1
    end
end
