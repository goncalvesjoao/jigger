class Cocktail < ApplicationRecord
  has_many :cocktail_aliases, dependent: :destroy, autosave: true, inverse_of: :cocktail
  has_many :user_cocktails, dependent: :restrict_with_error

  include CanonicalTranslations
  translates :history

  def self.lookup(text, language:)
    normalized = LookupName.normalize(text)
    return none if normalized.blank?

    alias_ids = CocktailAlias.where(language: language, normalized_name: normalized).select(:cocktail_id)

    translated_ids = translation_class.where(locale: language.to_s, normalized_name: normalized).select(:cocktail_id)

    usable.where(id: translated_ids).or(usable.where(id: alias_ids))
  end
end
