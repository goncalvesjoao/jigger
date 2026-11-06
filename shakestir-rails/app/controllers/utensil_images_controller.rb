class UtensilImagesController < ApplicationController
  include PhotoDelivery
  allow_unauthenticated_access only: :show

  def show
    deliver_photo(Utensil.usable.find(params[:utensil_id]))
  end
end
