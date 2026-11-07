require "test_helper"
require "open3"
require "tmpdir"
require "rbconfig"

class SeedImageDeliveryTest < ActiveSupport::TestCase
  test "committed fresh seeds upload real files and reruns repair only matching seed images" do
    # Normal fixture tests roll back outer transactions, hiding after_commit upload
    # failures. A separate database/service verifies actual committed bytes.
    Dir.mktmpdir("shakestir-image-seeds-") do |directory|
      script = File.join(directory, "verify.rb")
      File.write(script, <<~'RUBY')
        require "digest"
        directory = File.dirname(__FILE__)
        configs = { "test" => { "service" => "Disk", "root" => File.join(directory, "images") } }
        ActiveStorage::Blob.services = ActiveStorage::Service::Registry.new(configs)
        ActiveStorage::Blob.service = ActiveStorage::Blob.services.fetch("test")
        ActiveRecord::Migration.verbose = false
        ActiveRecord::Base.connection_pool.migration_context.migrate
        load Rails.root.join("db/seeds.rb")
        def check(value, message)
          raise message unless value
        end
        check(Recipe.count == 35, "Expected all 35 seed recipes")
        (Recipe.all.to_a + Cocktail.all.to_a).each do |record|
          check(record.image.attached?, "Missing attachment: #{record.name}")
          check(record.image.blob.service.exist?(record.image.blob.key), "Missing committed original: #{record.name}")
          check(Digest::MD5.base64digest(record.image.download) == record.image.blob.checksum, "Wrong bytes: #{record.name}")
        end
        snow = Recipe.find_by!(name: "Snowfall Sidecar")
        imported = Recipe.find_by!(source_url: "https://www.thecocktaildb.com/drink/11007")
        canonical = imported.cocktail
        original_key = snow.image.blob.key
        snow.image.blob.service.delete(original_key)
        imported.image.purge
        canonical.image.purge
        weekend = Recipe.find_by!(name: "My Weekend Margarita")
        weekend.image.purge
        # A real upload differs from the cached illustration and must survive.
        ruby = Recipe.find_by!(name: "Ruby Masquerade")
        upload_path = Rails.root.parent.join("db/seeds/thecocktaildb/images/cocktails/blue-margarita.jpg")
        ruby.image.attach(io: StringIO.new(upload_path.binread), filename: "my-upload.jpg", content_type: "image/jpeg")
        upload_id = ruby.image.blob_id
        upload_checksum = ruby.image.blob.checksum
        snow.update!(source_reference: "Curated credit", sweetness: 0)
        prose = snow.steps
        load Rails.root.join("db/seeds.rb")
        check(snow.reload.image.blob.key == original_key, "Missing seed file should be restored in place")
        check(snow.image.blob.service.exist?(original_key), "Missing demo file not restored")
        check(imported.reload.image.attached? && imported.image.blob.service.exist?(imported.image.blob.key), "Missing import attachment not restored")
        check(canonical.reload.image.attached? && canonical.image.blob.service.exist?(canonical.image.blob.key), "Missing canonical attachment not restored")
        check(weekend.reload.image.attached? && weekend.image.blob.service.exist?(weekend.image.blob.key), "Missing demo attachment not restored")
        check(ruby.reload.image.blob_id == upload_id && ruby.image.blob.checksum == upload_checksum, "Uploaded image was overwritten")
        check(snow.steps == prose && snow.source_reference == "Curated credit" && snow.sweetness == 0, "Recipe curation changed")
        before = [ Recipe.count, Cocktail.count, ActiveStorage::Attachment.count, ActiveStorage::Blob.count ]
        keys = Recipe.order(:id).map { |record| record.image.blob.key }
        load Rails.root.join("db/seeds.rb")
        check(before == [ Recipe.count, Cocktail.count, ActiveStorage::Attachment.count, ActiveStorage::Blob.count ], "Rerun duplicated image records")
        check(keys == Recipe.order(:id).map { |record| record.image.blob.key }, "Rerun replaced existing images")
        # Even if a custom upload is lost, a different cached photo must not replace it.
        ruby.image.blob.service.delete(ruby.image.blob.key)
        DemoAccountsSeeder.seed!
        check(ruby.reload.image.blob_id == upload_id && !ruby.image.blob.service.exist?(ruby.image.blob.key), "Lost upload was replaced with unrelated bytes")
        puts "Committed seed images, safe repairs, curation and uploads verified"
      RUBY
      output, status = Open3.capture2e(
        { "DATABASE_URL" => "sqlite3:#{File.join(directory, 'isolated.sqlite3')}", "RAILS_ENV" => "test" },
        RbConfig.ruby, Rails.root.join("bin/rails").to_s, "runner", script, chdir: Rails.root.to_s
      )
      assert status.success?, output
      assert_includes output, "Committed seed images, safe repairs, curation and uploads verified"
    end
  end
end
