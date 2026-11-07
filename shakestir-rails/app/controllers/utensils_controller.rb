class UtensilsController < ApplicationController
  allow_unauthenticated_access only: :index

  def index
    @utensils = Utensil.usable.with_attached_image.sort_by { |utensil| [ utensil.display_name.downcase, utensil.id ] }
    respond_to :json
  end
end
