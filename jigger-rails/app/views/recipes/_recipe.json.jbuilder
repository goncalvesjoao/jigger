Globalize.with_locale(recipe.language == "und" ? I18n.default_locale : recipe.language) do
  json.extract! recipe, :id, :name, :language, :cocktail_id, :official, :source_url, :visibility, :publication_state, :steps, :preparation_time_seconds, :servings, :preparation_method, :source_reference, :published_at, :user_id, :created_at, :updated_at
  json.name recipe.display_name
  json.url recipe_url(recipe, format: :json)

  json.image_url(recipe.image.attached? ? recipe_image_url(recipe, size: :detail) : nil)
end
