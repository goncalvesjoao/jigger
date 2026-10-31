class ImageUploadValidator < ActiveModel::EachValidator
  MAX_BYTES = 10_000_000
  MAX_PIXELS = 25_000_000
  CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze

  def validate_each(record, attribute, _attachment)
    change = record.attachment_changes[attribute.to_s]
    return unless change.is_a?(ActiveStorage::Attached::Changes::CreateOne)
    if change.blob.byte_size > MAX_BYTES
      record.errors.add(attribute, "must be 10 MB or smaller")
      return
    end

    require "vips"
    upload = change.attachable
    io = upload.is_a?(Hash) ? upload.fetch(:io) : upload
    io = io.open if io.is_a?(Pathname)
    io.rewind
    begin
      Tempfile.create([ "catalog-photo", ".upload" ], binmode: true) do |file|
        IO.copy_stream(io, file, MAX_BYTES + 1)
        file.flush
        inspect_image(record, attribute, change.blob, file)
      end
    ensure
      io.rewind
      io.close if upload.is_a?(Pathname)
    end
  rescue LoadError
    record.errors.add(attribute, "cannot be checked because libvips is unavailable; install libvips")
  rescue Vips::Error, ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError
    record.errors.add(attribute, "must be a readable JPEG, PNG, or WebP image")
  end

  private
    def inspect_image(record, attribute, blob, file)
      if file.size > MAX_BYTES
        record.errors.add(attribute, "must be 10 MB or smaller")
        return
      end
      content_type = Marcel::MimeType.for(Pathname.new(file.path))
      unless CONTENT_TYPES.include?(content_type)
        record.errors.add(attribute, "must be a JPEG, PNG, or WebP image")
        return
      end

      decoded = Vips::Image.new_from_file(file.path, access: :sequential, fail_on: :warning)
      if decoded.width * decoded.height > MAX_PIXELS
        record.errors.add(attribute, "must be 25 megapixels or smaller")
        return
      end
      if decoded.get_typeof("n-pages") != 0 && decoded.get("n-pages") > 1
        record.errors.add(attribute, "must be a still image")
        return
      end
      # Force a sequential decode after the header limits pass, without retaining a full raster.
      decoded.avg
      blob.content_type = content_type
      blob.metadata = blob.metadata.merge(width: decoded.width, height: decoded.height, analyzed: true)
    end
end
