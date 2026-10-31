class IngredientImagesController < ApplicationController
  include PhotoDelivery
  allow_unauthenticated_access only: :show

  def show
    deliver_photo(Ingredient.usable.find(params[:ingredient_id]))
  end
end
