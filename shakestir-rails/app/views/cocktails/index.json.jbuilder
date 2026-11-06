json.array! @pagination do |cocktail|
  json.extract! cocktail, :id, :description, :history
  json.name cocktail.display_name
  json.url cocktail_url(cocktail, format: :json)
  json.image_url(cocktail.image.attached? ? cocktail_image_url(cocktail) : nil)
end
