module Admin
  class ApplicationController < Administrate::ApplicationController
    include Authentication

    before_action :require_admin
    private
      def require_admin
        head :forbidden unless Current.user&.admin?
      end

      def scoped_resource
        resource_class.with_attached_image
      end

      def filter_resources(resources, search_term:)
        return resources if search_term.blank?
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(LookupName.normalize(search_term))}%"
        resources.where("normalized_name LIKE ?", pattern)
      end

      def resource_params
        permitted = super
        if permitted[:image].blank?
          permitted.delete(:image)
        elsif !permitted[:image].is_a?(ActionDispatch::Http::UploadedFile)
          raise ActionController::BadRequest, "image must be an uploaded file"
        end
        permitted
      end

      def after_resource_destroyed_path(_resource)
        [ namespace, resource_class ]
      end
  end
end
