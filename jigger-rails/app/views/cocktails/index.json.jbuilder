json.array! @groups.to_a do |identity, recipes|
  json.cocktail_id(identity.is_a?(Cocktail) ? identity.id : nil)
  json.name identity.display_name
  json.image_url(identity.is_a?(Cocktail) && identity.image.attached? ? cocktail_image_url(identity) : nil)
  json.matching_recipe_count recipes.size
  json.recipes recipes, partial: "recipes/recipe", as: :recipe
end
