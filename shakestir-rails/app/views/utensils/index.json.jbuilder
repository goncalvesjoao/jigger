json.data @utensils do |utensil|
  json.description utensil.description
  json.image_url(utensil.image.attached? ? utensil_image_url(utensil, size: :card) : nil)
  json.id utensil.id
  json.name utensil.display_name
end
json.metadata do
  json.total_count @utensils.size
end
