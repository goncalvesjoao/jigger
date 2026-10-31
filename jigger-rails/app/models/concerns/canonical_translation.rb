module CanonicalTranslation
  extend ActiveSupport::Concern

  included do
    before_validation { self.normalized_name = name.present? ? LookupName.normalize(name) : nil }
    validates :locale, uniqueness: { scope: reflect_on_association(:globalized_model).foreign_key }
    validates :name, presence: true, if: -> { locale.to_s == "en" }
    validate :preserve_identity_and_locale
    before_destroy :protect_english_translation
  end

  private
    def preserve_identity_and_locale
      return unless persisted?
      foreign_key = self.class.reflect_on_association(:globalized_model).foreign_key
      errors.add(:base, "cannot move a translation to another identity or locale") if will_save_change_to_attribute?(foreign_key) || will_save_change_to_locale?
    end

    def protect_english_translation
      if locale.to_s == "en" && !destroyed_by_association
        errors.add(:base, "English content is required; delete the unreferenced identity instead")
        throw :abort
      end
    end
end
