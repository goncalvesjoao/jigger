class RecipeImagesController < ApplicationController
  include PhotoDelivery
  allow_unauthenticated_access only: :show
  after_action :verify_authorized

  def show
    recipe = Recipe.find(params[:recipe_id])
    authorize recipe, :show?
    deliver_photo(recipe)
  end
end
