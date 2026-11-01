class Ingredient < ApplicationRecord
  enum :category, {
    spirit: "spirit",
    liqueur: "liqueur",
    wine: "wine",
    beer: "beer",
    mixer: "mixer",
    juice: "juice",
    syrup: "syrup",
    fruit: "fruit",
    dairy: "dairy",
    herb: "herb",
    spice: "spice",
    ice: "ice",
    other: "other"
  }, validate: true
  enum :alcohol_status, {
    alcoholic: "alcoholic",
    non_alcoholic: "non_alcoholic",
    unknown: "unknown"
  }, validate: true

  has_many :ingredient_aliases, dependent: :destroy, autosave: true, inverse_of: :ingredient
  has_many :cocktail_ingredients, dependent: :restrict_with_error

  has_many :step_mentions, dependent: :restrict_with_error

  include CanonicalTranslations
  include CanonicalPhoto

  validates :alcohol_by_volume, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  def self.lookup(text, language:)
    normalized = LookupName.normalize(text)
    return none if normalized.blank?

    alias_ids = IngredientAlias.where(language: language, normalized_name: normalized).select(:ingredient_id)

    translated_ids = translation_class.where(locale: language.to_s, normalized_name: normalized).select(:ingredient_id)

    usable.where(id: translated_ids).or(usable.where(id: alias_ids))
  end
end
