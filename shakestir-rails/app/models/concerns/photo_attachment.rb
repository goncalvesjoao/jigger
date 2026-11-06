module PhotoAttachment
  extend ActiveSupport::Concern

  included do
    has_one_attached :image do |attachment|
      attachment.variant :card, resize_to_limit: [ 320, 240 ], format: :webp
      attachment.variant :detail, resize_to_limit: [ 1200, 1200 ], format: :webp
    end
    validates :image, image_upload: true
  end

  # Include after associations so this guard precedes Active Storage's generated setter.
  def image=(upload)
    source = upload.is_a?(Hash) ? upload[:io] : upload
    unless upload.nil? || upload == "" || source.is_a?(Pathname) || (source.respond_to?(:read) && source.respond_to?(:rewind))
      raise ArgumentError, "image must be a fresh file upload, not an existing blob or signed ID"
    end
    super
  end

  def exclusive_photo?
    image.attached? && !image.blob.attachments.where.not(record: self).exists?
  end
end
