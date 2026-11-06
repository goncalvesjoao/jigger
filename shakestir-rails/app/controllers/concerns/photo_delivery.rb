module PhotoDelivery
  extend ActiveSupport::Concern
  include ActiveStorage::SetCurrent

  included do
    before_action :prevent_photo_caching
    rescue_from ActiveStorage::FileNotFoundError, with: -> { head :not_found }
  end

  private
    def prevent_photo_caching
      response.headers["Cache-Control"] = "private, no-store"
      response.headers["Vary"] = "Cookie"
    end

    def deliver_photo(record)
      return head :not_found unless record.exclusive_photo?
      size = params.fetch(:size, "detail")
      return head :not_found unless %w[original card detail].include?(size)
      asset = size == "original" ? record.image.blob : record.image.variant(size.to_sym).processed
      redirect_to asset.url(disposition: :inline), allow_other_host: true
    end
end
