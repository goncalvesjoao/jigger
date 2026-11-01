class Cocktail < ApplicationRecord
  has_many :recipes, dependent: :nullify
  has_many :cocktail_aliases, dependent: :destroy, autosave: true, inverse_of: :cocktail
  translates :name, :description, :history, fallbacks_for_empty_translations: true
  translation_class.before_validation { self.normalized_name = name.present? ? LookupName.normalize(name) : nil }
  translation_class.validates :name, :locale, presence: true
  translation_class.validates :locale, uniqueness: { scope: :cocktail_id }

  include PhotoAttachment

  validates :source_url, format: { with: /\Ahttps?:\/\/[^\s]+\z/i }, allow_blank: true
  validates :name, presence: true

  def display_name
    name.presence || translations.detect { |translation| translation.name.present? }&.name
  end

  def self.search(text)
    return all if text.blank?
    pattern = "%#{sanitize_sql_like(LookupName.normalize(text))}%"
    translated = translation_class.where("normalized_name LIKE ?", pattern).select(:cocktail_id)
    aliases = CocktailAlias.where("normalized_name LIKE ?", pattern).select(:cocktail_id)
    where(id: translated).or(where(id: aliases))
  end
end
