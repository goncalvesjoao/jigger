class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    frontend = ENV["SHAKESTIR_FRONTEND_URL"].presence if params[:frontend]
    @reset_url = if frontend && frontend.match?(/\Ahttps?:\/\/[^\s]+\z/)
      "#{frontend.chomp('/')}#{Rails.application.routes.url_helpers.edit_password_path(user.password_reset_token)}"
    else
      nil
    end
    mail subject: "Reset your password", to: user.email_address
  end
end
