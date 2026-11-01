json.extract! @cocktail, :id, :description, :history, :source_reference, :source_url, :source_published_on, :source_date_note
json.name @cocktail.display_name
json.matching_recipe_count @recipes.size
json.recipes @recipes, partial: "recipes/recipe", as: :recipe
json.filters_applied @filtered
if @filtered
  json.other_recipes @other_recipes, partial: "recipes/recipe", as: :recipe
end
