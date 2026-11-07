require "json"
require "stringio"

module UtensilsSeeder
  ROOT = Rails.root.parent.join("db", "seeds", "utensils")

  def self.catalog
    JSON.parse(ROOT.join("catalog.json").read)
  end

  def self.seed!
    entries = catalog
    # Fail before writing any records if the checked-in asset set is incomplete.
    entries.each do |entry|
      path = ROOT.join("images", "#{entry.fetch("slug")}.png")
      raise "Missing utensil seed image: #{path}" unless path.file?
    end

    entries.each do |entry|
      Utensil.transaction do
        existing = Utensil.find_by(normalized_name: LookupName.normalize(entry.fetch("name")))
        utensil = existing || Utensil.new(category: entry.fetch("category"))
        utensil.name = entry.fetch("name") unless existing
        utensil.description = entry.fetch("description") if existing.nil? || existing.description.blank?
        unless utensil.image.attached?
          path = ROOT.join("images", "#{entry.fetch("slug")}.png")
          utensil.image.attach(io: StringIO.new(File.binread(path)), filename: path.basename.to_s, content_type: "image/png")
        end
        utensil.save!
      end
    end
  end
end
