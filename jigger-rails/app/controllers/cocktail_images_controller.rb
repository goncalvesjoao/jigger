class CocktailImagesController < ApplicationController
  include PhotoDelivery
  allow_unauthenticated_access only: :show

  def show
    deliver_photo(Cocktail.usable.find(params[:cocktail_id]))
  end
end
