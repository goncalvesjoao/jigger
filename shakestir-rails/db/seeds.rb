require "json"
require "pathname"
require "stringio"
require "digest"
require_relative "seeds/taste_estimates"

module TheCocktailDbSeeder
  ROOT = Rails.root.parent.join("db", "seeds", "thecocktaildb")

  def self.seed!
    seed_shakestir_account!
    seed_ingredients!
    seed_cocktails!
    seed_canonical_content!
    seed_variants!
  end

  def self.seed_shakestir_account!
    attributes = JSON.parse(Rails.root.parent.join("db/seeds/system_account.json").read)
    User.find_or_create_by!(system_key: attributes.fetch("system_key")) do |user|
      user.assign_attributes(attributes.except("system_key"))
    end
  end

  def self.seed_variants!
    load_json("canonical_cocktails.json").each do |name, content|
      next unless content["parent_cocktail"]

      cocktail = find_cocktail(name)
      parent = find_cocktail(content.fetch("parent_cocktail"))
      cocktail.update!(parent_cocktail: parent) if cocktail && parent && cocktail.parent_cocktail_id.nil?
    end
  end

  def self.find_cocktail(name)
    Cocktail.find_by(normalized_name: LookupName.normalize(name))
  end

  def self.seed_canonical_content!
    load_json("canonical_cocktails.json").each do |name, content|
      cocktail = Cocktail.find_by(normalized_name: LookupName.normalize(name))
      next unless cocktail

      Cocktail.transaction do
        cocktail.update!(content.slice("description", "history").select { |field, _| cocktail[field].blank? })
        sources = %w[source_reference source_url source_published_on source_date_note]
        # Keep citations together rather than mixing seeded and curated sources.
        cocktail.update!(content.slice(*sources)) if sources.all? { |field| cocktail[field].blank? }
      end
    end
  end

  def self.seed_cocktails!
    data = load_json("cocktails.json")
    Array(data["drinks"]).each do |drink|
      name = drink["strDrink"].to_s.strip
      next if name.empty?
      next unless local_image_available?("cocktails", name)

      source_url = "https://www.thecocktaildb.com/drink/#{drink.fetch("idDrink")}"
      recipe = Recipe.find_by(source_url: source_url)
      # Preserve existing imports, curation, and recipes reassigned to another author.
      if recipe
        if recipe.user == User.shakestir_account && recipe.source_reference == "TheCocktailDB"
          attach_seed_image!(recipe, "cocktails", name)
          if recipe.cocktail&.normalized_name == LookupName.normalize(name)
            attach_seed_image!(recipe.cocktail, "cocktails", name)
          end
        end
        TasteEstimatesSeeder.fill_missing!(recipe, key: source_url, owner: User.shakestir_account)
        next
      end
      recipe = Recipe.new(user: User.shakestir_account)

      previous_published_at = recipe.published_at
      Recipe.transaction do
        recipe.publication_state = "draft"
        recipe.name = name
        recipe.source_reference = "TheCocktailDB"
        recipe.source_url = source_url
        attach_seed_image!(recipe, "cocktails", name)
        identity = recipe.cocktail
        if identity.nil?
          identity = Cocktail.find_by(normalized_name: LookupName.normalize(name))
          identity ||= Cocktail.create!(name: name)
          recipe.cocktail = identity
        end
        attach_seed_image!(identity, "cocktails", name)
        identity.save!
        recipe.save!
        recipe.recipe_ingredients.destroy_all
        (1..15).each do |position|
          ingredient_name = drink["strIngredient#{position}"].to_s.strip
          next if ingredient_name.empty?
          ingredient = find_or_initialize_ingredient(ingredient_name)
          ingredient.name = ingredient_name
          attach_seed_image!(ingredient, "ingredients", ingredient_name)
          ingredient.save!
          measure = drink["strMeasure#{position}"].to_s.strip
          recipe.recipe_ingredients.create!(ingredient: ingredient, position: position,
            submitted_text: [ measure.presence, ingredient_name ].compact.join(" "))
        end
        recipe.recipe_steps.destroy_all
        instructions = drink["strInstructions"].to_s.strip
        recipe.recipe_steps.create!(position: 0, body: instructions) if instructions.present?
        recipe.visibility = "public"
        recipe.publication_state = "published"
        unless recipe.save
          recipe.publication_state = "draft"
          recipe.save!
        end
        recipe.update_columns(published_at: previous_published_at) if previous_published_at
      end
      TasteEstimatesSeeder.fill_missing!(recipe, key: source_url, owner: User.shakestir_account)
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
      ingredient.name = name
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
    Ingredient.find_by(normalized_name: normalized) || Ingredient.new
  end

  def self.attach_seed_image!(record, collection_name, name)
    # Already-pending attachments must finish uploading at outer commit.
    return true if record.attachment_changes["image"]
    return true if record.image.attached? && record.image.blob.service.exist?(record.image.blob.key)

    extension = local_image_extension(collection_name, name)
    unless extension
      Rails.logger.warn("Missing cached seed image for #{collection_name}/#{name}")
      return false
    end
    path = ROOT.join("images", collection_name, "#{slugify(name)}#{extension}")
    bytes = path.binread

    if record.image.attached?
      blob = record.image.blob
      # Restore missing original bytes only when the cache is byte-identical.
      # Never replace an upload with a different seed picture, even if lost.
      unless blob.checksum == Digest::MD5.base64digest(bytes) && blob.byte_size == bytes.bytesize
        Rails.logger.warn("Preserving nonmatching missing upload for #{record.class} #{record.id}")
        return false
      end
      blob.service.upload(blob.key, StringIO.new(bytes), checksum: blob.checksum)
    else
      record.image.attach(io: StringIO.new(bytes), filename: path.basename.to_s, content_type: mime_type_for(path))
    end
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

require_relative "seeds/demo_accounts"
DemoAccountsSeeder.seed! if Rails.env.development? || Rails.env.test?

require_relative "seeds/profile_images"
ProfileImagesSeeder.seed!

require_relative "seeds/utensils"
UtensilsSeeder.seed!

require_relative "seeds/techniques"
TechniquesSeeder.seed!
