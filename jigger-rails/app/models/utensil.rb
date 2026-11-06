class Utensil < ApplicationRecord
  enum :category, {
    glassware: "glassware",
    mixing: "mixing",
    measuring: "measuring",
    straining: "straining",
    other: "other"
  }, validate: true

  has_many :recipe_utensils, dependent: :restrict_with_error

  has_many :step_mentions, dependent: :restrict_with_error

  include CanonicalTranslations
  include CanonicalPhoto

  validates :capacity_milliliters, numericality: { greater_than: 0 }, allow_nil: true

  def self.lookup(text, language:)
    normalized = LookupName.normalize(text)
    return none if normalized.blank?

    translated_ids = translation_class.where(locale: language.to_s, normalized_name: normalized).select(:utensil_id)

    usable.where(id: translated_ids)
  end
end
