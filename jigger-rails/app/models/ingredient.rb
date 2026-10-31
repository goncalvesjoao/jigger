class Ingredient < ApplicationRecord
  has_many :ingredient_aliases, dependent: :destroy, autosave: true, inverse_of: :ingredient
  has_many :user_cocktail_ingredients, dependent: :restrict_with_error

  has_many :step_mentions, dependent: :restrict_with_error

  include CanonicalTranslations
  include CanonicalPhoto

  def self.lookup(text, language:)
    normalized = LookupName.normalize(text)
    return none if normalized.blank?

    alias_ids = IngredientAlias.where(language: language, normalized_name: normalized).select(:ingredient_id)

    translated_ids = translation_class.where(locale: language.to_s, normalized_name: normalized).select(:ingredient_id)

    usable.where(id: translated_ids).or(usable.where(id: alias_ids))
  end
end
