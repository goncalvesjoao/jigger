class StepMention < ApplicationRecord
  belongs_to :recipe_step
  has_one :recipe, through: :recipe_step
  belongs_to :ingredient, optional: true
  belongs_to :utensil, optional: true

  validates :start_offset, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :end_offset, numericality: { only_integer: true, greater_than: :start_offset }
  validates :quoted_text, presence: true
  validate :one_identity
  validate :matches_prose
  before_save :check_current_prose

  private
    def one_identity
      errors.add(:base, "must reference exactly one ingredient or utensil") unless [ ingredient, utensil ].compact.one?
    end

    # The step lock serializes mention creation with text updates and invalidation.
    def check_current_prose
      current_body = RecipeStep.lock.find(recipe_step_id).body
      unless prose_matches?(current_body)
        errors.add(:quoted_text, "no longer matches the saved step text")
        throw :abort
      end
    end

    def prose_matches?(body)
      end_offset <= body.to_s.length && body.to_s[start_offset...end_offset] == quoted_text
    end

    def matches_prose
      return unless recipe_step && start_offset.is_a?(Integer) && end_offset.is_a?(Integer)
      unless prose_matches?(recipe_step.body)
        errors.add(:quoted_text, "must match the step text at the character offsets")
      end
    end
end
