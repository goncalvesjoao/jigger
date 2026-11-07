json.data @recipes, partial: "recipes/recipe", as: :recipe
json.metadata do
  json.partial! "shared/pagination", pagination: @pagination
  json.state @publication_state
  json.q params[:q]
  json.counts do
    json.all @recipe_counts.values.sum
    json.draft @recipe_counts.fetch("draft", 0)
    json.published @recipe_counts.fetch("published", 0)
  end
end
