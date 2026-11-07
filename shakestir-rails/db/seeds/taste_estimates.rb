require "json"
require "digest"

# Explicit, untested editorial expectations for the exact checked-in seed specs.
# Source recipe credit and prose are never changed by this loader.
module TasteEstimatesSeeder
  FIELDS = %w[sweetness sourness bitterness].freeze
  DEMO_EMAILS = %w[leo@shakestir.example alex@shakestir.example].freeze

  def self.entries
    @entries ||= JSON.parse(Rails.root.parent.join("db/seeds/taste/recipe_estimates.json").read).fetch("recipes").tap do |entries|
      entries.each_value do |entry|
        raise "Invalid editorial taste entry" unless FIELDS.all? { |field| entry[field].is_a?(Integer) && (0..5).cover?(entry[field]) } && entry.fetch("rationale").present?
      end
    end
  end

  def self.fingerprint(recipe)
    ingredients = recipe.recipe_ingredients.map { |line| [ LookupName.normalize(line.ingredient.name), line.submitted_text, line.quantity&.to_s("F"), line.measuring_unit, line.optional, line.role, line.preparation_note ] }
    Digest::SHA256.hexdigest(JSON.generate([ ingredients, recipe.recipe_steps.map(&:body) ]))
  end

  def self.fill_missing!(recipe, key:, owner:)
    entry = entries[key]
    return unless entry

    # lock! reloads its receiver, clearing ActiveStorage's pending after-commit
    # uploads. Keep the seed caller's instance intact inside outer transactions.
    stored_recipe = Recipe.find(recipe.id)
    stored_recipe.with_lock do
      return unless stored_recipe.user_id == owner.id
      if key.start_with?("https://www.thecocktaildb.com/drink/")
        return unless owner == User.shakestir_account && stored_recipe.source_url == key && stored_recipe.source_reference == "TheCocktailDB"
      else
        return unless DEMO_EMAILS.include?(owner.email_address) && key == "demo:#{owner.email_address}:#{stored_recipe.name}" && stored_recipe.source_url.blank?
      end
      # A matching title or URL alone cannot justify estimating a curated spec.
      return unless fingerprint(stored_recipe) == entry.fetch("spec_fingerprint")

      missing = FIELDS.select { |field| stored_recipe[field].nil? }.index_with { |field| entry.fetch(field) }
      stored_recipe.update_columns(missing) if missing.any?
    end
  end
end
