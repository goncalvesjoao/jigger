require "administrate/base_dashboard"

class CocktailDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: TranslatedField,
    description: TranslatedField.with_options(multiline: true),
    history: TranslatedField.with_options(multiline: true),
    image: PhotoField,
    recipes: Field::HasMany,
    parent_cocktail: Field::BelongsTo.with_options(class_name: "Cocktail"),
    variants: Field::HasMany.with_options(class_name: "Cocktail"),
    source_reference: Field::String,
    source_url: Field::Url,
    source_published_on: Field::Date,
    source_date_note: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[id name image].freeze
  SHOW_PAGE_ATTRIBUTES = ATTRIBUTE_TYPES.keys.freeze
  FORM_ATTRIBUTES = %i[parent_cocktail name description history image source_reference source_url source_published_on source_date_note].freeze

  def display_resource(resource)
    resource.display_name.presence || "Cocktail #{resource.id}"
  end
end
