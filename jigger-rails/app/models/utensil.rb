class Utensil < ApplicationRecord
  enum :category, {
    glassware: "glassware",
    mixing: "mixing",
    measuring: "measuring",
    straining: "straining",
    other: "other"
  }, validate: true

  has_many :utensil_aliases, dependent: :destroy, autosave: true, inverse_of: :utensil
  has_many :user_cocktail_utensils, dependent: :restrict_with_error

  has_many :step_mentions, dependent: :restrict_with_error

  include CanonicalTranslations
  include CanonicalPhoto

  validates :capacity_milliliters, numericality: { greater_than: 0 }, allow_nil: true

  def self.lookup(text, language:)
    normalized = LookupName.normalize(text)
    return none if normalized.blank?

    alias_ids = UtensilAlias.where(language: language, normalized_name: normalized).select(:utensil_id)

    translated_ids = translation_class.where(locale: language.to_s, normalized_name: normalized).select(:utensil_id)

    usable.where(id: translated_ids).or(usable.where(id: alias_ids))
  end
end
