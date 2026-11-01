require "json"
require "pathname"

module TheCocktailDbSeeder
  ROOT = Rails.root.join("db", "seeds", "thecocktaildb")

  def self.seed!
    seed_ingredients!
    seed_cocktails!
  end

  def self.seed_cocktails!
    data = load_json("cocktails.json")
    Array(data["drinks"]).each do |drink|
      name = drink["strDrink"].to_s.strip
      next if name.empty?
      next unless local_image_available?("cocktails", name)

      source_url = "https://www.thecocktaildb.com/drink/#{drink.fetch("idDrink")}"
      cocktail = Cocktail.find_by(source_url: source_url) ||
        Cocktail.where(user_id: nil, source_url: nil).find_by(id: Cocktail.lookup(name, language: :en).select(:id)) || Cocktail.new
      # Re-running seeds must not overwrite an admin's curated recipe.
      next if cocktail.official? || cocktail.user_id.present?

      previous_published_at = cocktail.published_at
      Cocktail.transaction do
        cocktail.publication_state = "draft"
        cocktail.language = "en"
        Globalize.with_locale(:en) { cocktail.name = name }
        cocktail.source_reference = "TheCocktailDB"
        cocktail.source_url = source_url
        attach_seed_image!(cocktail, "cocktails", name)
        cocktail.save!
        cocktail.cocktail_ingredients.destroy_all
        (1..15).each do |position|
          ingredient_name = drink["strIngredient#{position}"].to_s.strip
          next if ingredient_name.empty?
          ingredient = find_or_initialize_ingredient(ingredient_name)
          Globalize.with_locale(:en) { ingredient.name = ingredient_name }
          attach_seed_image!(ingredient, "ingredients", ingredient_name)
          ingredient.save!
          measure = drink["strMeasure#{position}"].to_s.strip
          cocktail.cocktail_ingredients.create!(ingredient: ingredient, position: position,
            submitted_text: [ measure.presence, ingredient_name ].compact.join(" "), language: "en")
        end
        cocktail.recipe_steps.destroy_all
        instructions = drink["strInstructions"].to_s.strip
        cocktail.recipe_steps.create!(position: 0, body: instructions) if instructions.present?
        cocktail.visibility = "public"
        cocktail.publication_state = "published"
        unless cocktail.save
          cocktail.publication_state = "draft"
          cocktail.save!
        end
        cocktail.update_columns(published_at: previous_published_at) if previous_published_at
      end
    end
  end

  def self.seed_ingredients!
    data = load_json("ingredients.json")
    seen = {}

    Array(data["ingredients"]).each do |ingredient_data|
      name = ingredient_data["strIngredient"].to_s.strip
      next if name.empty?
      next if seen[name.downcase]
      next unless local_image_available?("ingredients", name)
      seen[name.downcase] = true

      ingredient = find_or_initialize_ingredient(name)
      Globalize.with_locale(:en) { ingredient.name = name }
      ingredient.category = normalize_category(ingredient_data["strType"])
      ingredient.alcohol_status = normalize_alcohol_status(ingredient_data)
      attach_seed_image!(ingredient, "ingredients", name)
      ingredient.save!
    end
  end

  def self.load_json(filename)
    file_path = ROOT.join(filename)
    raise "Missing TheCocktailDB seed file: #{file_path}" unless file_path.exist?

    JSON.parse(File.read(file_path))
  end

  def self.find_or_initialize_ingredient(name)
    normalized = LookupName.normalize(name)
    Ingredient::Translation.find_by(locale: "en", normalized_name: normalized)&.globalized_model || Ingredient.new
  end

  def self.attach_seed_image!(record, collection_name, name)
    return true if record.image.attached?

    extension = local_image_extension(collection_name, name)
    return true if extension.nil?

    path = ROOT.join("images", collection_name, "#{slugify(name)}#{extension}")
    return true unless path.exist?

    record.image.attach(
      io: File.open(path, "rb"),
      filename: path.basename.to_s,
      content_type: mime_type_for(path)
    )
    true
  rescue StandardError => e
    Rails.logger.warn("Could not attach cached image for #{name}: #{e.class}: #{e.message}")
    false
  end

  def self.local_image_available?(collection_name, name)
    !local_image_extension(collection_name, name).nil?
  end

  def self.local_image_extension(collection_name, name)
    entries = Dir.glob(ROOT.join("images", collection_name, "#{slugify(name)}.*").to_s)
    entries.first&.split(".")&.last&.downcase.then { |ext| ext.nil? ? nil : ".#{ext}" }
  end

  def self.slugify(name)
    name.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-+|-+$/, "")
  end

  def self.mime_type_for(path)
    case path.extname.downcase
    when ".jpg", ".jpeg" then "image/jpeg"
    when ".png" then "image/png"
    else "image/jpeg"
    end
  end

  def self.normalize_category(str_type)
    return "other" if str_type.to_s.strip.empty?

    type = str_type.to_s.downcase
    return "spirit" if type.match?(/spirit|rum|gin|vodka|whiskey|bourbon|brandy|tequila|mezcal|cognac/)
    return "liqueur" if type.match?(/liqueur|amaro|cordial|triple sec|apercitif/)
    return "wine" if type.match?(/wine|vermouth|sherry|champagne/)
    return "beer" if type.match?(/beer/)
    return "juice" if type.match?(/juice|soda|citrus|acid/)
    return "syrup" if type.match?(/syrup|sweetener|grenadine/)
    return "fruit" if type.match?(/fruit|herb|fresh|vegetable/)
    return "dairy" if type.match?(/milk|cream|dairy/)
    return "herb" if type.match?(/herb|mint|basil|cilantro/)
    return "spice" if type.match?(/spice|bitters/)
    return "mixer" if type.match?(/mixer|water|tonic|soda|club soda|ginger beer|cola/)

    "other"
  end

  def self.normalize_alcohol_status(ingredient_data)
    alcohol = ingredient_data["strAlcohol"].to_s.strip.downcase
    return "non_alcoholic" if alcohol.include?("non alcoholic") || alcohol.include?("non-alcoholic")
    return "alcoholic" if alcohol.include?("alcoholic") || ingredient_data["strABV"].to_s.strip.present?

    "unknown"
  end
end

TheCocktailDbSeeder.seed!
