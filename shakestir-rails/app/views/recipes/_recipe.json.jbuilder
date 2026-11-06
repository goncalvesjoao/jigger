Globalize.with_locale(recipe.language == "und" ? I18n.default_locale : recipe.language) do
  json.extract! recipe, :id, :name, :language, :cocktail_id, :source_url, :visibility, :publication_state, :steps, :preparation_time_seconds, :servings, :preparation_method, :source_reference, :published_at, :user_id, :created_at, :updated_at
  json.name recipe.display_name
  json.techniques recipe.techniques do |technique|
    json.extract! technique, :id, :slug, :name, :description, :instructions, :tip
    json.url technique_url(technique)
  end
  json.author recipe_author(recipe)
  json.display_name recipe_heading(recipe)
  json.url recipe_url(recipe, format: :json)

  photo = recipe_photo(recipe)
  json.image_url(photo.image.attached? ? public_send("#{photo.model_name.singular}_image_url", photo, size: :detail) : nil)
end
