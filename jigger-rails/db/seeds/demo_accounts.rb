module DemoAccountsSeeder
  def self.seed!
    Globalize.with_locale(:en) do
      User.transaction do
        bartender = account("leo@jigger.example", "Showtime123!", "Leo Sterling",
          "public", "Fictional world-famous bartender at the Velvet Hour. Seasonal cocktails, dramatic garnishes, and a little everyday magic.")
        home = account("alex@jigger.example", "Homebar123!", "Alex Morgan",
          "private", "Home bartender experimenting with weekend drinks and saving ideas for friends.")

        midnight = recipe(bartender, "Midnight Velvet", "Espresso Martini", "public", "published",
          [ [ "Vodka", "40 ml vodka" ], [ "Kahlua", "20 ml Kahlua" ], [ "Sugar syrup", "5 ml sugar syrup" ] ],
          "Shake all ingredients hard with ice until frothy. Double strain into a chilled coupe and garnish with three coffee beans.")
        ruby = recipe(bartender, "Ruby Masquerade", "Margarita", "public", "published",
          [ [ "Tequila", "45 ml tequila" ], [ "Triple sec", "20 ml triple sec" ], [ "Lime juice", "25 ml lime juice" ], [ "Strawberries", "2 ripe strawberries" ] ],
          "Muddle the strawberries, then shake with the remaining ingredients and ice. Double strain into a chilled glass over fresh ice and garnish with a lime wheel for a ruby-red Halloween sour.")
        snow = recipe(bartender, "Snowfall Sidecar", "Sidecar", "public", "published",
          [ [ "Cognac", "45 ml cognac" ], [ "Triple sec", "20 ml triple sec" ], [ "Lemon juice", "20 ml lemon juice" ] ],
          "Chill a coupe and coat half its rim with fine sugar. Shake the ingredients with ice, strain into the coupe, and finish with a lemon twist.")
        weekend = recipe(home, "My Weekend Margarita", "Margarita", "private", "draft",
          [ [ "Tequila", "40 ml tequila" ], [ "Triple sec", "15 ml triple sec" ], [ "Lime juice", "25 ml lime juice" ] ],
          "Shake with ice and pour over fresh ice. Try a little less lime next time.")
        coffee = recipe(home, "After Dinner Experiment", "Espresso Martini", "private", "draft",
          [ [ "Vodka", "30 ml vodka" ], [ "Kahlua", "20 ml Kahlua" ], [ "Sugar syrup", "5 ml sugar syrup" ] ],
          "Shake with ice and strain into a small glass. Compare the foam with a longer shake next time.")

        collection(bartender, "Halloween Special", "public", [ midnight, ruby, official("Negroni") ])
        collection(bartender, "Christmas", "public", [ snow, midnight, official("Old Fashioned") ])
        collection(bartender, "House Signatures", "public", [ midnight, ruby, snow ])
        collection(home, "Weekend Favorites", "private", [ weekend, official("Mojito"), official("Daiquiri") ])
        collection(home, "Dinner with Friends", "private", [ coffee, weekend, snow, official("Manhattan") ])
        collection(home, "Want to Try", "private", [ ruby, midnight, official("Negroni"), official("Gimlet") ])
        collection(home, "Christmas", "private", [ snow, coffee, official("Old Fashioned") ])
      end
    end
  end

  def self.account(email, password, name, visibility, bio)
    User.find_or_create_by!(email_address: email) do |user|
      user.password = password
      user.display_name = name
      user.profile_visibility = visibility
      user.bio = bio
    end
  end

  def self.recipe(user, name, cocktail_name, visibility, state, ingredients, steps)
    existing = user.recipes.find_by(id: Recipe.lookup(name, language: :en).select(:id))
    return existing if existing

    recipe = user.recipes.create!(name: name, cocktail: TheCocktailDbSeeder.find_cocktail(cocktail_name),
      language: "en", visibility: visibility, preparation_method: "shaken", preparation_time_seconds: 180)
    ingredients.each_with_index do |(ingredient_name, text), position|
      ingredient = Ingredient::Translation.find_by!(locale: "en", normalized_name: LookupName.normalize(ingredient_name)).globalized_model
      recipe.recipe_ingredients.create!(ingredient: ingredient, submitted_text: text, language: "en", position: position)
    end
    recipe.recipe_steps.create!(body: steps, position: 0)
    TheCocktailDbSeeder.attach_seed_image!(recipe, "cocktails", cocktail_name)
    recipe.update!(publication_state: state)
    recipe
  end

  def self.official(name)
    TheCocktailDbSeeder.find_cocktail(name)&.recipes&.marketplace&.find_by(official: true)
  end

  def self.collection(user, name, visibility, recipes)
    collection = user.collections.find_or_create_by!(name: name) { |entry| entry.visibility = visibility }
    recipes.compact.each { |recipe| collection.collection_recipes.find_or_create_by!(recipe: recipe) }
  end
end
