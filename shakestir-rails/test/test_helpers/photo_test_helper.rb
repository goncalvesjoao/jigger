module PhotoTestHelper
  def photo_upload(name = "photo.png", content_type = "image/png")
    Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files", name), content_type)
  end
end
