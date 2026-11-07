json.data @recipes, partial: "recipes/recipe", as: :recipe
json.metadata do
  json.partial! "shared/pagination", pagination: @pagination
end
