class Recipe < ApplicationRecord
  has_and_belongs_to_many :liking_users, class_name: "User", join_table: "recipes_users",
    foreign_key: :recipe_id, association_foreign_key: :user_id
  has_many :collection_recipes, dependent: :destroy
  has_many :collections, through: :collection_recipes


  belongs_to :cocktail, optional: true
  belongs_to :user

  include StoredName
  has_many :recipe_ingredients, -> { order(:position, :id) }, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients
  has_many :recipe_utensils, dependent: :destroy
  has_many :utensils, through: :recipe_utensils
  has_many :recipe_techniques, dependent: :destroy
  has_many :techniques, -> { order(:slug) }, through: :recipe_techniques
  has_many :recipe_steps, -> { order(:position) }, dependent: :destroy, autosave: true

  include PhotoAttachment

  before_validation :refresh_published_at

  validates :source_url, format: { with: /\Ahttps?:\/\/[^\s]+\z/i }, allow_blank: true

  validates :visibility, inclusion: { in: %w[private public] }
  validates :publication_state, inclusion: { in: %w[draft published] }
  validates :servings, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :publication_requirements, if: -> { publication_state == "published" }

  scope :marketplace, -> {
    where(visibility: "public", publication_state: "published")
      .where("length(trim(recipes.name)) > 0")
      .where(id: RecipeIngredient.select(:recipe_id))
      .where(id: RecipeStep.where("length(trim(body)) > 0").select(:recipe_id))
      .where.not(id: RecipeIngredient.where.not(ingredient_id: Ingredient.usable.select(:id)).select(:recipe_id))
      .where.not(id: RecipeUtensil.where.not(utensil_id: Utensil.usable.select(:id)).select(:recipe_id))
      .order(published_at: :desc, created_at: :desc)
  }
  scope :readable_by, ->(user) { user ? marketplace.or(where(user_id: user.id)) : marketplace }

  def self.makeable_with(ingredient_ids:, utensil_ids:)
    missing_ingredients = RecipeIngredient.where(optional: false).where.not(ingredient_id: ingredient_ids).select(:recipe_id)
    missing_utensils = RecipeUtensil.where.not(utensil_id: utensil_ids).select(:recipe_id)
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
    name
  end

  def self.lookup(text)
    normalized = LookupName.normalize(text)
    return none if normalized.blank?
    where(normalized_name: normalized)
  end

  def self.search(text)
    return all if text.blank?
    pattern = "%#{sanitize_sql_like(LookupName.normalize(text))}%"
    where("recipes.normalized_name LIKE ?", pattern).or(where(cocktail_id: Cocktail.search(text).select(:id)))
  end

  private
    def refresh_published_at
      return unless will_save_change_to_publication_state? && publication_state == "published"

      self.published_at = Time.current
    end

    def complete?
      name.present? &&
        recipe_ingredients.any? && recipe_ingredients.all? { |line| line.ingredient&.usable? } &&
        recipe_utensils.all? { |requirement| requirement.utensil&.usable? } && recipe_steps.reject(&:marked_for_destruction?).any? { |step| step.body.present? }
    end

    def publication_requirements
      errors.add(:base, "published recipes need a name, ingredients and preparation steps") unless complete?
    end
end
