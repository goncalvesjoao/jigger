json.extract! user_cocktail, :id, :name, :language, :cocktail_id, :visibility, :publication_state, :steps, :preparation_time_seconds, :user_id, :created_at, :updated_at
json.url user_cocktail_url(user_cocktail, format: :json)

json.image_url(user_cocktail.image.attached? ? user_cocktail_image_url(user_cocktail, size: :detail) : nil)
