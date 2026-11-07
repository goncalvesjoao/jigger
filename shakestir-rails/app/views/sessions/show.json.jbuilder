if @user
  json.data do
    json.extract! @user, :id, :handle, :display_name
    json.name @user.profile_name
    json.image_url(@user.image.attached? ? profile_image_url(@user, size: :card) : nil)
    json.avatar do
      json.url(@user.image.attached? ? profile_image_url(@user, size: :card) : gravatar_url(@user))
      json.initials nil
    end
    json.favorites_collection_id @user.favorites_collection.id
  end
else
  json.data nil
end
json.metadata do
  json.csrf_token form_authenticity_token
end
