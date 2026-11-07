json.data @utensils do |utensil|
  json.id utensil.id
  json.name utensil.display_name
end
json.metadata do
  json.total_count @utensils.size
end
