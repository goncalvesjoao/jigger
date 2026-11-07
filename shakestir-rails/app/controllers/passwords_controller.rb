class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  before_action -> { response.headers["Cache-Control"] = "private, no-store" }
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { respond_to_rate_limit(new_password_path) }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      mailer = request.format.json? && ENV["SHAKESTIR_FRONTEND_URL"].present? ? PasswordsMailer.with(frontend: true) : PasswordsMailer
      mailer.reset(user).deliver_later
    end

    message = "Password reset instructions sent (if user with that email address exists)."
    respond_to do |format|
      format.html { redirect_to new_session_path, notice: message }
      format.json { render json: { data: { message: message } } }
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.json { render json: { data: { valid: true } } }
    end
  end

  def update
    if request.format.json?
      missing = %i[password password_confirmation].select { |field| params[field].blank? }
      if missing.any?
        return render_json_errors(missing.index_with { [ "can't be blank" ] }, status: :unprocessable_content)
      end
    end
    if @user.update(params.permit(:password, :password_confirmation))
      resume_session
      resetting_current_user = Current.user == @user
      @user.sessions.destroy_all
      if resetting_current_user
        cookies.delete(:session_id)
        Current.session = nil
      end
      reset_csrf_token(request)
      respond_to do |format|
        format.html { redirect_to new_session_path, notice: "Password has been reset." }
        format.json do
          render json: { data: { message: "Password has been reset." }, metadata: { csrf_token: form_authenticity_token } }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to edit_password_path(params[:token]), alert: "Passwords did not match." }
        format.json { render_json_errors(@user.errors.to_hash, status: :unprocessable_content) }
      end
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      if request.format.json?
        render_json_errors("Password reset link is invalid or has expired.", status: :unprocessable_content)
      else
        redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
      end
    end
end
