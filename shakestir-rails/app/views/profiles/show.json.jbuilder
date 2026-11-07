json.data do
  json.extract! @profile, :id, :handle, :display_name, :bio, :created_at
  json.name @profile.profile_name
  json.owned @owned
  json.image_url(@profile.image.attached? ? profile_image_url(@profile, size: :card) : nil)
  json.avatar do
    if @profile.image.attached?
      json.url profile_image_url(@profile, size: :card)
      json.initials nil
    elsif @owned
      json.url gravatar_url(@profile)
      json.initials nil
    else
      json.url nil
      json.initials(@profile.display_name.to_s.split.first(2).map { |part| part.first }.join.upcase.presence || "J.")
    end
  end
  json.collections @collections do |collection|
    json.extract! collection, :id, :name, :visibility
    json.recipe_count @recipe_counts.fetch(collection.id, 0)
    json.previews(@previews.fetch(collection.id, []).map(&:recipe)) do |recipe|
      json.id recipe.id
      json.image_url(recipe.image.attached? ? recipe_image_url(recipe, size: :card) : nil)
    end
  end
  json.recipes @recipes, partial: "recipes/recipe", as: :recipe
end
