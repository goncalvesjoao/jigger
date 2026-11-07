json.data @collections do |collection|
  json.partial! "collections/collection", saved_collection: collection,
    recipe_count: @recipe_counts.fetch(collection.id, 0), previews: @previews.fetch(collection.id, []).map(&:recipe)
end
json.metadata do
  json.total_count @collections.size
end
