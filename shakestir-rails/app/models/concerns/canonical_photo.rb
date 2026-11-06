module CanonicalPhoto
  extend ActiveSupport::Concern
  include PhotoAttachment

  included do
    validate :requires_one_image
    scope :with_required_image, -> {
      exclusive_blobs = ActiveStorage::Attachment.group(:blob_id).having("COUNT(*) = 1").select(:blob_id)
      owners = ActiveStorage::Attachment.where(record_type: base_class.name, name: "image", blob_id: exclusive_blobs)
        .group(:record_id).having("COUNT(*) = 1").select(:record_id)
      where(id: owners)
    }
  end

  def required_photo?
    return false unless exclusive_photo?
    count = persisted? ? ActiveStorage::Attachment.where(record: self, name: "image").count : 0
    return count <= 1 if attachment_changes["image"].is_a?(ActiveStorage::Attached::Changes::CreateOne)
    count == 1
  end

  private
    def requires_one_image
      errors.add(:image, "must have exactly one photo with its own uploaded file") unless required_photo?
    end
end
