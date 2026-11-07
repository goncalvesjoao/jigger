json.data do
  json.partial! "collections/collection", saved_collection: @collection, recipe_count: @recipes.size, previews: @recipes.first(4)
  json.recipes @recipes, partial: "recipes/recipe", as: :recipe
end
