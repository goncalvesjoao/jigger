class TechniquesController < ApplicationController
  allow_unauthenticated_access only: %i[index show]

  def index
    @techniques = Technique.order(:slug)
    respond_to :json
  end

  def show
    @technique = Technique.find_by!(slug: params[:id])
  end
end
