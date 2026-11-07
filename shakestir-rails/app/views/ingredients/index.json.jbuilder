json.data @ingredients do |ingredient|
  json.description ingredient.description
  json.image_url(ingredient.image.attached? ? ingredient_image_url(ingredient, size: :card) : nil)
  json.id ingredient.id
  json.name ingredient.display_name
end
json.metadata do
  json.total_count @ingredients.size
end
