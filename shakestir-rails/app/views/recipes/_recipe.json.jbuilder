json.extract! recipe, :id, :name, :cocktail_id, :source_url, :visibility, :publication_state, :steps, :servings, :source_reference, :published_at, :user_id, :created_at, :updated_at
json.name recipe.display_name
json.techniques recipe.techniques do |technique|
  json.extract! technique, :id, :slug, :name, :description, :instructions, :tip
  json.url technique_url(technique)
end
json.author recipe_author(recipe)
json.author_profile do
  json.extract! recipe.user, :id, :handle
  json.name recipe.user.profile_name
end
json.display_name recipe_heading(recipe)
json.url recipe_url(recipe, format: :json)
json.star_count recipe.stars_count
json.starred(authenticated? ? recipe_starred?(recipe) : false)
json.can_edit policy(recipe).edit?
json.can_delete policy(recipe).destroy?

photo = recipe_photo(recipe)
json.image_url(photo.image.attached? ? public_send("#{photo.model_name.singular}_image_url", photo, size: :detail) : nil)
json.own_image_url(recipe.image.attached? ? recipe_image_url(recipe, size: :detail) : nil)

if local_assigns[:detail]
  json.saved_collection_ids(authenticated? ? Current.user.collections.joins(:collection_recipes)
    .where(collection_recipes: { recipe_id: recipe.id }).order(:created_at).pluck(:id) : [])
  json.recipe_ingredients recipe.recipe_ingredients do |line|
    json.extract! line, :id, :ingredient_id, :position, :quantity, :measuring_unit, :submitted_text, :preparation_note, :optional, :role
  end
  json.recipe_utensils recipe.recipe_utensils do |requirement|
    json.extract! requirement, :id, :utensil_id, :submitted_text, :role
  end
  json.recipe_steps recipe.recipe_steps do |step|
    json.extract! step, :id, :position, :body
  end
  json.steps_editable recipe.recipe_steps.size <= 1
  if recipe.cocktail && policy(recipe.cocktail).show?
    json.cocktail do
      json.id recipe.cocktail.id
      json.name recipe.cocktail.display_name
      json.url cocktail_url(recipe.cocktail, format: :json)
    end
  else
    json.cocktail nil
  end
end
