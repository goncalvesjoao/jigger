class ProfileImagesController < ApplicationController
  include PhotoDelivery
  allow_unauthenticated_access only: :show

  def show
    profile = User.find(params[:id])

    deliver_photo(profile)
  end
end
