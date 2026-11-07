json.data @techniques do |technique|
  json.extract! technique, :id, :slug, :name, :description, :instructions, :tip
  json.url technique_url(technique, format: :json)
end
json.metadata do
  json.total_count @techniques.size
end
