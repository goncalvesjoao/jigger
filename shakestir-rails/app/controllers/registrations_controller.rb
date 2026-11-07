class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    response.headers["Cache-Control"] = "private, no-store"
    @user = User.new(params.expect(user: [ :email_address, :password, :password_confirmation ]))

    if @user.save
      start_new_session_for @user
      respond_to do |format|
        format.html { redirect_to root_path }
        format.json { render "sessions/show", status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: { errors: @user.errors.to_hash }, status: :unprocessable_content }
      end
    end
  end
end
