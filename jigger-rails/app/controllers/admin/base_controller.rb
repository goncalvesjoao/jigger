module Admin
  class BaseController < ApplicationController
    before_action :verify_admin_user

    private

    def verify_admin_user
      if Current.user.nil? || !Current.user.admin?
        head :forbidden
      end
    end
  end
end
