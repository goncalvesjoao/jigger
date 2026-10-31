module CanonicalTranslations
  extend ActiveSupport::Concern

  included do
    translates :name, :description, fallbacks_for_empty_translations: true
    translation_class.include CanonicalTranslation
    validate :requires_english_name
    scope :usable, -> { where(id: translation_class.where(locale: "en").where.not(normalized_name: nil).select(translation_options[:foreign_key])) }
  end

  def display_name
    name
  end

  def usable?
    Globalize.with_locale(:en) { name.present? } && !translation_for(:en, false)&.marked_for_destruction?
  end

  private
    def requires_english_name
      errors.add(:name, "needs an English translation") unless usable?
    end
end
