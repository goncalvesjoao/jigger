require "test_helper"
require_relative "../test_helpers/photo_test_helper"
require "vips"

class RecipeImageTest < ActiveSupport::TestCase
  include PhotoTestHelper

  test "a photo is optional and supported formats are inspected synchronously" do
    recipe = Recipe.create!(user: users(:one))
    assert_not recipe.image.attached?
    [ [ "photo.png", "image/png" ], [ "photo.jpg", "image/jpeg" ], [ "photo.webp", "image/webp" ] ].each do |filename, type|
      recipe.update!(image: photo_upload(filename, type))
      assert_equal type, recipe.reload.image.blob.content_type
      assert_equal 640, recipe.image.blob.metadata["width"]
      assert_equal 480, recipe.image.blob.metadata["height"]
      assert recipe.image.blob.analyzed?
      assert_equal 1, ActiveStorage::Attachment.where(record: recipe, name: "image").count
    end
  end

  test "spoofed nonimages corrupt images and unsupported formats are rejected" do
    recipe = recipes(:one)
    [ [ "pretend.jpg", "<html>not a photo</html>" ],
      [ "vector.svg", '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"></svg>' ],
      [ "photo.gif", Base64.decode64("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7") ],
      [ "photo.heic", "\x00\x00\x00\x18ftypheic".b + "\x00".b * 12 ],
      [ "broken.png", "\x89PNG\r\n\x1a\n".b ] ].each do |filename, bytes|
      recipe.image = { io: StringIO.new(bytes), filename: filename, content_type: "image/jpeg" }
      assert_not recipe.save, filename
      assert recipe.errors[:image].any?, filename
      recipe.reload
    end
    recipe.image = photo_upload("truncated.jpg", "image/jpeg")
    assert_not recipe.save
    assert recipe.errors[:image].any?
    recipe.reload.image = photo_upload("animated.webp", "image/webp")
    assert_not recipe.save
    assert_includes recipe.errors[:image], "must be a still image"
  end

  test "content type comes from actual bytes rather than the supplied MIME type" do
    recipe = recipes(:one)
    recipe.update!(image: photo_upload("photo.png", "image/jpeg"))
    assert_equal "image/png", recipe.reload.image.blob.content_type
  end

  test "limits apply to the original bytes and pixel dimensions before decoding" do
    recipe = recipes(:one)
    Tempfile.create([ "too-large", ".png" ], binmode: true) do |file|
      file.write(File.binread(Rails.root.join("test/fixtures/files/photo.png")))
      file.truncate(ImageUploadValidator::MAX_BYTES + 1)
      file.rewind
      recipe.image = { io: file, filename: "large.png" }
      assert_not recipe.save
      assert_includes recipe.errors[:image], "must be 10 MB or smaller"
    end
    recipe.reload
    Tempfile.create([ "too-many-pixels", ".png" ]) do |file|
      Vips::Image.black(5001, 5000).pngsave(file.path)
      file.rewind
      recipe.image = { io: file, filename: "large.png" }
      assert_not recipe.save
      assert_includes recipe.errors[:image], "must be 25 megapixels or smaller"
    end
  end

  test "failed photo or recipe validation preserves the previous attachment" do
    recipe = recipes(:one)
    recipe.update!(image: photo_upload)
    original = recipe.reload.image.blob
    assert_not recipe.update(image: photo_upload("truncated.jpg", "image/jpeg"))
    assert_equal original.id, recipe.reload.image.blob.id
    assert_equal original.download, recipe.image.download
    assert_not recipe.update(image: photo_upload("photo.webp", "image/webp"), preparation_time_seconds: -1)
    assert_equal original.id, recipe.reload.image.blob.id
    recipe.update!(image: photo_upload("photo.webp", "image/webp"))
    assert_not_equal original.id, recipe.reload.image.blob.id
    assert_equal 1, ActiveStorage::Attachment.where(record: recipe, name: "image").count
  end
end
