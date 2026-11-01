Globalize.with_locale(cocktail.language == "und" ? I18n.default_locale : cocktail.language) do
  json.extract! cocktail, :id, :name, :description, :language, :parent_cocktail_id, :official, :source_url, :source_published_on, :source_date_note, :visibility, :publication_state, :steps, :preparation_time_seconds, :servings, :preparation_method, :source_reference, :published_at, :user_id, :created_at, :updated_at
  json.name cocktail.display_name
  json.url cocktail_url(cocktail, format: :json)

  json.image_url(cocktail.image.attached? ? cocktail_image_url(cocktail, size: :detail) : nil)
end
