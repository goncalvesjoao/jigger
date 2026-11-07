class IngredientsController < ApplicationController
  allow_unauthenticated_access only: :index

  def index
    @ingredients = Ingredient.usable.with_attached_image.sort_by { |ingredient| [ ingredient.display_name.downcase, ingredient.id ] }
    respond_to :json
  end
end
