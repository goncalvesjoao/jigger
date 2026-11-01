class RecipeStep < ApplicationRecord
  belongs_to :cocktail
  has_many :step_mentions, dependent: :destroy

  validates :body, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, uniqueness: { scope: :cocktail_id }
  after_update :clear_stale_mentions, if: :saved_change_to_body?

  private
    def clear_stale_mentions
      step_mentions.destroy_all
    end
end
