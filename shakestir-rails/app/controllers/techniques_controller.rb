class TechniquesController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    @technique = Technique.find_by!(slug: params[:id])
  end
end
