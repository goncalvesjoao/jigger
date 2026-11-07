require "test_helper"
require_relative "../../db/seeds/utensils"

class UtensilSeedTest < ActiveSupport::TestCase
  test "catalog seeds usable utensils with separate photos and survives repeat runs" do
    utensils(:jigger).update!(category: "measuring")
    UtensilsSeeder.seed!
    entries = UtensilsSeeder.catalog
    assert_equal entries.length, entries.pluck("slug").uniq.length
    records = entries.map do |entry|
      utensil = Utensil.lookup(entry.fetch("name")).sole
      assert utensil.usable?, entry.fetch("name")
      assert_equal entry.fetch("category"), utensil.category
      assert_equal entry.fetch("description"), utensil.description
      assert utensil.exclusive_photo?
      assert_nil utensil.capacity_milliliters
      utensil
    end
    assert_equal entries.length, records.map { |utensil| utensil.image.blob_id }.uniq.length
    before = [ Utensil.count, ActiveStorage::Attachment.count, ActiveStorage::Blob.count ]
    photos = records.map { |utensil| utensil.image.blob_id }
    UtensilsSeeder.seed!
    assert_equal before, [ Utensil.count, ActiveStorage::Attachment.count, ActiveStorage::Blob.count ]
    assert_equal photos, records.map { |utensil| utensil.reload.image.blob_id }
  end

  test "existing curation are preserved while missing descriptions are filled" do
    utensil = utensils(:jigger)
    utensil.update!(description: "Curated description", category: "other", capacity_milliliters: 45)
    photo_id = utensil.image.blob_id
    UtensilsSeeder.seed!
    utensil.reload
    assert_equal "other", utensil.category
    assert_equal 45, utensil.capacity_milliliters
    assert_equal photo_id, utensil.image.blob_id
    assert_equal "Curated description", utensil.description
    utensil.update!(description: nil)
    UtensilsSeeder.seed!
    assert_equal UtensilsSeeder.catalog.first.fetch("description"), utensil.reload.description
  end
end
