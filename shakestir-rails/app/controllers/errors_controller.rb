class ErrorsController < ApplicationController
  allow_unauthenticated_access only: :not_found

  def not_found
    render_json_errors("Resource not found.", status: :not_found)
  end
end
