json.extract! @technique, :id, :slug, :name, :description, :instructions, :tip
json.url technique_url(@technique, format: :json)
