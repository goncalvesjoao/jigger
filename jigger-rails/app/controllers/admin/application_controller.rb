module Admin
  class ApplicationController < Administrate::ApplicationController
    include Authentication

    before_action :require_admin
    around_action :with_content_locale
    helper_method :content_locale

    def default_url_options
      params[:content_locale].present? ? super.merge(content_locale: content_locale) : super
    end

    private
      def require_admin
        head :forbidden unless Current.user&.admin?
      end

      def content_locale
        params[:content_locale].presence || "en"
      end

      def with_content_locale(&block)
        raise ActionController::BadRequest, "Invalid language code" unless content_locale.match?(/\A[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})*\z/)
        Globalize.with_locale(content_locale, &block)
      end

      def scoped_resource
        resource_class.with_attached_image.includes(:translations)
      end

      def filter_resources(resources, search_term:)
        return resources if search_term.blank?
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(LookupName.normalize(search_term))}%"
        translations = resource_class.translation_class.where("normalized_name LIKE ?", pattern)
        resources.where(id: translations.select(resource_class.translation_options[:foreign_key]))
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
