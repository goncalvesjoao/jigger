class Cocktail < ApplicationRecord
  enum :preparation_method, {
    shaken: "shaken",
    stirred: "stirred",
    built: "built",
    blended: "blended"
  }, validate: { allow_nil: true }

  belongs_to :user, optional: true
  belongs_to :parent_cocktail, class_name: "Cocktail", optional: true
  has_many :variants, class_name: "Cocktail", foreign_key: :parent_cocktail_id, dependent: :nullify, inverse_of: :parent_cocktail
  has_many :cocktail_aliases, dependent: :destroy, autosave: true, inverse_of: :cocktail

  translates :name, :description, :history, fallbacks_for_empty_translations: true
  translation_class.before_validation { self.normalized_name = name.present? ? LookupName.normalize(name) : nil }
  translation_class.validates :locale, presence: true, uniqueness: { scope: :cocktail_id }
  has_many :cocktail_ingredients, -> { order(:position, :id) }, dependent: :destroy
  has_many :ingredients, through: :cocktail_ingredients
  has_many :cocktail_utensils, dependent: :destroy
  has_many :utensils, through: :cocktail_utensils
  has_many :recipe_steps, -> { order(:position) }, dependent: :destroy, autosave: true

  include PhotoAttachment

  before_validation :refresh_published_at

  validates :source_url, format: { with: /\Ahttps?:\/\/[^\s]+\z/i }, allow_blank: true

  validates :visibility, inclusion: { in: %w[private public] }
  validates :publication_state, inclusion: { in: %w[draft published] }
  validates :language, presence: true
  validates :preparation_time_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :servings, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :publication_requirements, if: -> { publication_state == "published" }

  scope :marketplace, -> {
    where(visibility: "public", publication_state: "published")
      .where.not(language: [ "und", "" ])
      .where(id: translation_class.where.not(normalized_name: nil).where("length(trim(name)) > 0").select(:cocktail_id))
      .where(id: CocktailIngredient.select(:cocktail_id))
      .where(id: RecipeStep.where("length(trim(body)) > 0").select(:cocktail_id))
      .where.not(id: CocktailIngredient.where.not(ingredient_id: Ingredient.usable.select(:id)).select(:cocktail_id))
      .where.not(id: CocktailUtensil.where.not(utensil_id: Utensil.usable.select(:id)).select(:cocktail_id))
      .order(published_at: :desc, created_at: :desc)
  }
  scope :readable_by, ->(user) { user&.admin? ? all : (user ? marketplace.or(where(user_id: user.id)) : marketplace) }

  def self.makeable_with(ingredient_ids:, utensil_ids:)
    missing_ingredients = CocktailIngredient.where(optional: false).where.not(ingredient_id: ingredient_ids).select(:cocktail_id)
    missing_utensils = CocktailUtensil.where.not(utensil_id: utensil_ids).select(:cocktail_id)
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

  def display_name
    name.presence || translations.detect { |translation| translation.name.present? }&.name
  end

  def self.lookup(text, language:)
    normalized = LookupName.normalize(text)
    return none if normalized.blank?
    translated = translation_class.where(locale: language.to_s, normalized_name: normalized).select(:cocktail_id)
    aliases = CocktailAlias.where(language: language, normalized_name: normalized).select(:cocktail_id)
    where(id: translated).or(where(id: aliases))
  end

  def self.search(text)
    return all if text.blank?
    pattern = "%#{sanitize_sql_like(LookupName.normalize(text))}%"
    translated = translation_class.where("normalized_name LIKE ?", pattern).select(:cocktail_id)
    aliases = CocktailAlias.where("normalized_name LIKE ?", pattern).select(:cocktail_id)
    where(id: translated).or(where(id: aliases))
  end

  validate :parent_has_no_cycle

  private
    def parent_has_no_cycle
      ancestor = parent_cocktail
      visited = [ self ]
      while ancestor
        if visited.include?(ancestor)
          errors.add(:parent_cocktail, "must not create a cycle")
          break
        end
        visited << ancestor
        ancestor = ancestor.parent_cocktail
      end
    end

    def refresh_published_at
      return unless will_save_change_to_publication_state? && publication_state == "published"

      self.published_at = Time.current
    end

    def complete?
      (name.present? || translations.reject(&:marked_for_destruction?).any? { |translation| translation.name.present? }) && language.present? && language != "und" &&
        cocktail_ingredients.any? && cocktail_ingredients.all? { |line| line.ingredient&.usable? } &&
        cocktail_utensils.all? { |requirement| requirement.utensil&.usable? } && recipe_steps.reject(&:marked_for_destruction?).any? { |step| step.body.present? }
    end

    def publication_requirements
      errors.add(:base, "published recipes need a name, language, ingredients and preparation steps") unless complete?
    end
end
