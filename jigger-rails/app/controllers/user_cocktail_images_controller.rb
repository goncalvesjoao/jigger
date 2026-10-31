class UserCocktailImagesController < ApplicationController
  include PhotoDelivery
  allow_unauthenticated_access only: :show
  after_action :verify_authorized

  def show
    recipe = UserCocktail.find(params[:user_cocktail_id])
    authorize recipe, :show?
    deliver_photo(recipe)
  end
end
