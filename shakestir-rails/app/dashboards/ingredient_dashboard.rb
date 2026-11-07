require "administrate/base_dashboard"

class IngredientDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    description: Field::Text,
    image: PhotoField,
    category: Field::Select,
    alcohol_status: Field::Select,
    alcohol_by_volume: Field::Number.with_options(decimals: 2),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[id name category image].freeze
  SHOW_PAGE_ATTRIBUTES = ATTRIBUTE_TYPES.keys.freeze
  FORM_ATTRIBUTES = %i[name description image category alcohol_status alcohol_by_volume].freeze

  def display_resource(resource)
    resource.display_name.presence || "Ingredient #{resource.id}"
  end
end
