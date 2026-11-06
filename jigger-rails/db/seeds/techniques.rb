require "json"

module TechniquesSeeder
  ROOT = Rails.root.join("db", "seeds", "techniques")

  def self.seed!
    Globalize.with_locale(:en) do
      JSON.parse(ROOT.join("catalog.json").read).each do |entry|
        Technique.transaction do
          technique = Technique.find_or_initialize_by(slug: entry.fetch("slug"))
          english = technique.translations.detect { |translation| translation.locale.to_s == "en" }
          %w[name description instructions tip].each do |field|
            technique.public_send("#{field}=", entry.fetch(field)) if english.nil? || english[field].blank?
          end
          technique.save!
        end
      end
    end
    seed_recipe_links!
  end

  def self.seed_recipe_links!
    # Only apply reviewed mappings to unchanged system imports. Never infer
    # technique assignments from arbitrary user prose or rewrite curated links.
    links = JSON.parse(ROOT.join("recipe_links.json").read)
    drinks = JSON.parse(Rails.root.join("db/seeds/thecocktaildb/cocktails.json").read).fetch("drinks")
    system_user = User.find_by(system_key: "jigger")
    return unless system_user

    drinks.each do |drink|
      slugs = links[drink.fetch("strDrink")]
      next unless slugs
      recipe = system_user.recipes.find_by(source_url: "https://www.thecocktaildb.com/drink/#{drink.fetch("idDrink")}")
      next unless recipe && recipe.language == "en" && recipe.steps == drink.fetch("strInstructions").strip
      next if recipe.recipe_techniques.exists?

      recipe.transaction do
        slugs.each { |slug| recipe.recipe_techniques.create!(technique: Technique.find_by!(slug: slug)) }
      end
    end
  end
end
