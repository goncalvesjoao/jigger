require "test_helper"
require_relative "../test_helpers/photo_test_helper"
require "vips"

class CatalogImageTest < ActiveSupport::TestCase
  include PhotoTestHelper

  test "canonical photos are required and replacements validate all supported formats" do
    [ Cocktail, Ingredient, Utensil ].each do |type|
      catalog = type.create!(image: photo_upload, name: "Catalog item")
      assert catalog.image.attached?
      [ [ "photo.png", "image/png" ], [ "photo.jpg", "image/jpeg" ], [ "photo.webp", "image/webp" ] ].each do |filename, mime|
        catalog.update!(image: photo_upload(filename, mime))
        assert_equal mime, catalog.reload.image.blob.content_type
        assert_equal 640, catalog.image.blob.metadata["width"]
        assert_equal 1, ActiveStorage::Attachment.where(record: catalog, name: "image").count
      end
      original = catalog.image.blob
      [ [ "truncated.jpg", "image/jpeg" ], [ "animated.webp", "image/webp" ] ].each do |filename, mime|
        assert_not catalog.update(image: photo_upload(filename, mime))
        assert catalog.errors[:image].any?
        assert_equal original.id, catalog.reload.image.blob.id
      end
      assert_not catalog.update(image: { io: StringIO.new("Not a JPEG"), filename: "photo.jpg", content_type: "image/jpeg" })
      assert_equal original.id, catalog.reload.image.blob.id
      assert_not catalog.update(name: "", image: photo_upload)
      assert_equal original.id, catalog.reload.image.blob.id
      catalog.update!(image: photo_upload)
      assert_not_equal original.id, catalog.reload.image.blob.id
    end
  end

  test "catalog uploads have the same original size and pixel limits" do
    [ Cocktail, Ingredient, Utensil ].each do |type|
      catalog = type.create!(image: photo_upload, name: "Catalog item")
      Tempfile.create([ "oversize", ".png" ], binmode: true) do |file|
        file.write(File.binread(Rails.root.join("test/fixtures/files/photo.png")))
        file.truncate(ImageUploadValidator::MAX_BYTES + 1)
        file.rewind
        assert_not catalog.update(image: { io: file, filename: "photo.png" })
        assert_includes catalog.errors[:image], "must be 10 MB or smaller"
      end
      catalog.reload
      Tempfile.create([ "large-pixels", ".png" ]) do |file|
        Vips::Image.black(5001, 5000).pngsave(file.path)
        file.rewind
        assert_not catalog.update(image: { io: file, filename: "photo.png" })
        assert_includes catalog.errors[:image], "must be 25 megapixels or smaller"
      end
    end
  end

  test "existing blobs and signed IDs cannot be reassigned across any photo owners" do
    source = user_cocktails(:one)
    source.update!(visibility: "private", image: photo_upload)
    blob = source.image.blob
    [ cocktails(:margarita), ingredients(:one), utensils(:jigger), user_cocktails(:two) ].each do |target|
      target.update!(image: photo_upload("small.png"))
      previous = target.image.blob.id
      [ blob, blob.signed_id, "invalid-signed-id", { io: blob, filename: "stolen.png" }, { blob: blob.id } ].each do |assignment|
        assert_raises(ArgumentError) { target.update!(image: assignment) }
        assert_equal previous, target.reload.image.blob.id
      end
      assert_raises(ArgumentError) { target.image.attach(blob) }
      assert_equal previous, target.reload.image.blob.id
    end
  end
  test "all canonical identities require one photo on creation and normal removal fails" do
    [ Cocktail, Ingredient, Utensil ].each do |type|
      missing = type.new(name: "English name")
      assert_not missing.save
      assert missing.errors[:image].any?
      assert_no_difference(type.name + ".count") do
        assert_raises(ActiveRecord::RecordInvalid) { type.create!(name: "No image") }
      end
      catalog = type.create!(name: "With image", image: photo_upload)
      original_id = catalog.image.blob.id
      assert catalog.usable?
      assert_not catalog.update(image: nil)
      assert_equal original_id, catalog.reload.image.blob.id
      assert_not catalog.update(image: "")
      assert_equal original_id, catalog.reload.image.blob.id
    end
  end

  test "low-level purge removes canonical usability and recipe marketplace eligibility" do
    recipe = user_cocktails(:one)
    [ cocktails(:margarita), ingredients(:one), utensils(:jigger) ].each do |catalog|
      catalog.update!(image: photo_upload)
      assert catalog.usable?
      assert_includes UserCocktail.marketplace, recipe
      catalog.image.purge
      assert_not catalog.reload.image.attached?
      assert_not catalog.usable?
      assert_not catalog.valid?
      assert catalog.errors[:image].any?
      assert_not_includes catalog.class.usable, catalog
      assert_empty catalog.class.lookup(catalog.name, language: "en")
      assert_not recipe.reload.valid?
      assert_not recipe.marketplace?
      assert_not_includes UserCocktail.marketplace, recipe
      assert_not_includes UserCocktail.makeable_with(ingredient_ids: Ingredient.ids, utensil_ids: Utensil.ids), recipe
      assert recipe.update(publication_state: "draft")
      catalog.update!(image: photo_upload)
      recipe.reload.update!(publication_state: "published")
    end
  end

  test "duplicate imported photos do not count as a usable single canonical photo" do
    catalog = ingredients(:one)
    File.open(Rails.root.join("test/fixtures/files/small.png")) do |file|
      extra_blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: "extra.png")
      extra = ActiveStorage::Attachment.create!(record: catalog, name: "image", blob: extra_blob)
      assert_not catalog.reload.valid?
      assert_not catalog.usable?
      assert_not_includes Ingredient.usable, catalog
      assert_not catalog.update(image: photo_upload)
      extra.delete
      assert catalog.reload.valid?
    end
  end
end
