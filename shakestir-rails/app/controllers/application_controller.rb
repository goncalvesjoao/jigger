class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError do
    request.format.json? ? render_json_errors("You are not allowed to perform this action.", status: :forbidden) : head(:forbidden)
  end
  rescue_from ActiveRecord::RecordNotFound do |error|
    raise error unless request.format.json?
    render_json_errors("Resource not found.", status: :not_found)
  end
  rescue_from ActionController::BadRequest, ActionController::ParameterMissing, ActionDispatch::Http::Parameters::ParseError do |error|
    raise error unless request.format.json?
    render_json_errors("Invalid request parameters.", status: :bad_request)
  end
  rescue_from ActionController::InvalidAuthenticityToken do |error|
    raise error unless request.format.json?
    render_json_errors("CSRF token is missing or invalid. Refresh your session and try again.", status: :unprocessable_content)
  end
  rescue_from ActiveRecord::RecordInvalid do |error|
    raise error unless request.format.json?
    render_json_errors(error.record.errors.to_hash, status: :unprocessable_content)
  end
  rescue_from ActiveRecord::RecordNotDestroyed do |error|
    raise error unless request.format.json?
    render_json_errors("Resource could not be deleted.", status: :unprocessable_content)
  end
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def render_json_errors(errors, status:)
    response.headers["Cache-Control"] = "private, no-store"
    render json: { errors: errors.is_a?(Hash) ? errors : { base: Array(errors) } }, status: status
  end

  def respond_to_rate_limit(path)
    if request.format.json?
      response.headers["Retry-After"] = "180"
      render_json_errors("Try again later.", status: :too_many_requests)
    else
      redirect_to path, alert: "Try again later."
    end
  end

  def pundit_user
    resume_session
    Current.user
  end
end
