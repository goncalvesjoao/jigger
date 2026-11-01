class CocktailImagesController < ApplicationController
  include PhotoDelivery
  allow_unauthenticated_access only: :show
  after_action :verify_authorized

  def show
    cocktail = Cocktail.find(params[:cocktail_id])
    authorize cocktail, :show?
    deliver_photo(cocktail)
  end
end
