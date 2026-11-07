module CatalogContent
  extend ActiveSupport::Concern

  included do
    include StoredName
    validates :name, presence: true
    scope :usable, -> { with_required_image.where.not(normalized_name: nil).where("length(trim(name)) > 0") }
  end

  def display_name
    name
  end

  def usable?
    name.present? && required_photo?
  end
end
