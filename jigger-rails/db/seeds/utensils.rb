require "json"
require "stringio"

module UtensilsSeeder
  ROOT = Rails.root.join("db", "seeds", "utensils")

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

    Globalize.with_locale(:en) do
      entries.each do |entry|
        Utensil.transaction do
          translation = Utensil::Translation.find_by(locale: "en", normalized_name: LookupName.normalize(entry.fetch("name")))
          utensil = translation&.globalized_model || Utensil.new(category: entry.fetch("category"))
          utensil.name = entry.fetch("name") unless translation
          utensil.description = entry.fetch("description") if translation.nil? || translation.description.blank?
          unless utensil.image.attached?
            path = ROOT.join("images", "#{entry.fetch("slug")}.png")
            utensil.image.attach(io: StringIO.new(File.binread(path)), filename: path.basename.to_s, content_type: "image/png")
          end
          utensil.save!
        end
      end
    end
  end
end
