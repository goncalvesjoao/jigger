json.data @ingredients do |ingredient|
  json.id ingredient.id
  json.name ingredient.display_name
end
json.metadata do
  json.total_count @ingredients.size
end
