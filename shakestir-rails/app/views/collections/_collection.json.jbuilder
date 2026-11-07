owned = saved_collection.user_id == Current.user&.id
json.extract! saved_collection, :id, :name, :visibility, :system_key
json.owner do
  json.extract! saved_collection.user, :id, :handle
  json.name saved_collection.user.profile_name
end
json.owned owned
json.can_edit owned
json.can_delete(owned && saved_collection.system_key != "favorites")
json.can_change_visibility(owned && saved_collection.system_key != "favorites")
json.recipe_count recipe_count
json.previews previews do |recipe|
  json.id recipe.id
  json.image_url(recipe.image.attached? ? recipe_image_url(recipe, size: :card) : nil)
end
