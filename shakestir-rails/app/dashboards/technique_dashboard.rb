require "administrate/base_dashboard"

class TechniqueDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    slug: Field::String,
    name: TranslatedField,
    description: TranslatedField.with_options(multiline: true),
    instructions: TranslatedField.with_options(multiline: true),
    tip: TranslatedField.with_options(multiline: true),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[id name slug].freeze
  SHOW_PAGE_ATTRIBUTES = ATTRIBUTE_TYPES.keys.freeze
  FORM_ATTRIBUTES = %i[slug name description instructions tip].freeze

  def display_resource(resource)
    resource.display_name.presence || resource.slug
  end
end
