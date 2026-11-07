class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create show ]
  before_action :prevent_session_caching, only: %i[show create destroy]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { respond_to_rate_limit(new_session_path) }

  def new
  end

  def show
    resume_session
    @user = Current.user
    respond_to :json
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      respond_to do |format|
        format.html { redirect_to after_authentication_url }
        format.json do
          @user = user
          render :show
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to new_session_path, alert: "Try another email address or password." }
        format.json { render json: { errors: { base: [ "Try another email address or password." ] } }, status: :unauthorized }
      end
    end
  end

  def destroy
    terminate_session
    respond_to do |format|
      format.html { redirect_to new_session_path, status: :see_other }
      format.json do
        @user = nil
        render :show
      end
    end
  end

  private
    def prevent_session_caching
      response.headers["Cache-Control"] = "private, no-store"
    end
end
