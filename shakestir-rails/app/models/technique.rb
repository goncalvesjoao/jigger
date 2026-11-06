class Technique < ApplicationRecord
  translates :name, :description, :instructions, :tip, fallbacks_for_empty_translations: true
  translation_class.include CanonicalTranslation

  has_many :recipe_techniques, dependent: :restrict_with_error
  has_many :recipes, through: :recipe_techniques

  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validate :requires_english_content

  def display_name
    name
  end

  def to_param
    slug
  end

  private
    def requires_english_content
      english = translation_for(:en, false)
      %i[name description instructions].each do |field|
        value = globalize.stash_contains?(:en, field) ? globalize.fetch_stash(:en, field) : english&.public_send(field)
        errors.add(field, "needs an English translation") if value.blank? || english&.marked_for_destruction?
      end
    end
end
