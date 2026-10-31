class UserCocktail < ApplicationRecord
  belongs_to :user
  belongs_to :cocktail, optional: true
  has_many :user_cocktail_ingredients, dependent: :destroy
  has_many :ingredients, through: :user_cocktail_ingredients
  has_many :user_cocktail_utensils, dependent: :destroy
  has_many :utensils, through: :user_cocktail_utensils
  has_many :recipe_steps, -> { order(:position) }, dependent: :destroy, autosave: true

  include PhotoAttachment

  validates :visibility, inclusion: { in: %w[private public] }
  validates :publication_state, inclusion: { in: %w[draft published] }
  validates :language, presence: true
  validates :preparation_time_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :publication_requirements, if: -> { publication_state == "published" }

  scope :marketplace, -> {
    where(visibility: "public", publication_state: "published")
      .where(cocktail_id: Cocktail.usable.select(:id)).where.not(name: "").where.not(language: "und")
      .where(id: UserCocktailIngredient.select(:user_cocktail_id))
      .where(id: RecipeStep.select(:user_cocktail_id))
      .where.not(id: UserCocktailIngredient.where.not(ingredient_id: Ingredient.usable.select(:id)).select(:user_cocktail_id))
      .where.not(id: UserCocktailUtensil.where.not(utensil_id: Utensil.usable.select(:id)).select(:user_cocktail_id))
  }
  scope :readable_by, ->(user) { user ? marketplace.or(where(user_id: user.id)) : marketplace }

  def self.makeable_with(ingredient_ids:, utensil_ids:)
    missing_ingredients = UserCocktailIngredient.where.not(ingredient_id: ingredient_ids).select(:user_cocktail_id)
    missing_utensils = UserCocktailUtensil.where.not(utensil_id: utensil_ids).select(:user_cocktail_id)
    marketplace.where.not(id: missing_ingredients).where.not(id: missing_utensils)
  end

  def marketplace?
    visibility == "public" && publication_state == "published" && complete?
  end

  # Keep the existing plain-text CRUD form as a single-step editor.
  def steps
    recipe_steps.reject(&:marked_for_destruction?).map(&:body).join("\n")
  end

  def steps=(text)
    @multi_step_edit = false
    existing = recipe_steps.reject(&:marked_for_destruction?)
    return if text == steps
    if existing.size <= 1
      step = existing.first || recipe_steps.build(position: 0)
      text.blank? ? step.mark_for_destruction : step.body = text
    else
      @multi_step_edit = true
    end
  end

  validate { errors.add(:steps, "must be edited through recipe_steps for a multi-step recipe") if @multi_step_edit }

  private
    def complete?
      name.present? && language.present? && language != "und" && cocktail&.usable? &&
        user_cocktail_ingredients.any? && user_cocktail_ingredients.all? { |line| line.ingredient&.usable? } &&
        user_cocktail_utensils.all? { |requirement| requirement.utensil&.usable? } && recipe_steps.reject(&:marked_for_destruction?).any? { |step| step.body.present? }
    end

    def publication_requirements
      errors.add(:base, "published recipes need a name, language, cocktail identity, ingredients and preparation steps") unless complete?
    end
end
