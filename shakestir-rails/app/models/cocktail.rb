class Cocktail < ApplicationRecord
  belongs_to :parent_cocktail, class_name: "Cocktail", optional: true, inverse_of: :variants
  has_many :variants, class_name: "Cocktail", foreign_key: :parent_cocktail_id,
    inverse_of: :parent_cocktail, dependent: :nullify
  validate :parent_must_not_form_cycle

  has_many :recipes, dependent: :nullify
  include StoredName

  include PhotoAttachment

  validates :source_url, format: { with: /\Ahttps?:\/\/[^\s]+\z/i }, allow_blank: true
  validates :name, presence: true

  def parent_must_not_form_cycle
    ancestor = parent_cocktail
    visited = [ self ]
    while ancestor
      if visited.include?(ancestor)
        errors.add(:parent_cocktail, "must not form a cycle")
        break
      end
      visited << ancestor
      ancestor = ancestor.parent_cocktail
    end
  end
  private :parent_must_not_form_cycle

  def display_name
    name
  end

  def self.search(text)
    return all if text.blank?
    pattern = "%#{sanitize_sql_like(LookupName.normalize(text))}%"
    where("normalized_name LIKE ?", pattern)
  end
end
