require "administrate/base_dashboard"

class RecipeDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: TranslatedField,
    image: PhotoField,
    cocktail: Field::BelongsTo,
    user: Field::BelongsTo,
    techniques: Field::HasMany,
    language: Field::String,
    visibility: Field::Select.with_options(collection: %w[private public]),
    publication_state: Field::Select.with_options(collection: %w[draft published]),
    servings: Field::Number,
    preparation_method: Field::Select.with_options(include_blank: true),
    preparation_time_seconds: Field::Number,
    steps: Field::Text,
    source_reference: Field::String,
    source_url: Field::Url,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[id name user publication_state].freeze
  SHOW_PAGE_ATTRIBUTES = ATTRIBUTE_TYPES.keys.freeze
  FORM_ATTRIBUTES = %i[name image cocktail user language visibility publication_state servings preparation_method preparation_time_seconds steps techniques source_reference source_url].freeze

  def display_resource(resource)
    resource.display_name.presence || "Recipe #{resource.id}"
  end
end
