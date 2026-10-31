# Jigger Rails

## Database and models

This implementation uses SQLite and Globalize 7.1.3, verified with Rails 8.1.4 and Ruby 4.0.9. The [Globalize documentation](https://github.com/globalize/globalize#model-translations) describes its model translation and locale APIs.

The migrations target a fresh database, with no backfill for previous schemas. To recreate your local development database from the checked-in schema, run these commands separately from `jigger-rails`. This deletes its existing data:

```sh
RAILS_ENV=development bin/rails db:drop
RAILS_ENV=development bin/rails db:create
RAILS_ENV=development bin/rails db:schema:load
```

`Cocktail`, `Ingredient`, and `Utensil` are shared, admin-managed identities. `Cocktail` groups owned `UserCocktail` recipe variations through `cocktail.user_cocktails` and `user_cocktail.cocktail`. Each variation preserves its personal name and language independently of the canonical cocktail.

## Canonical translations and alternative names

Globalize exposes translated `name` and `description` on each canonical model. Only `Cocktail` also has translated `history`. All content, including English, lives in `cocktail_translations`, `ingredient_translations`, or `utensil_translations`. The base identity tables have no duplicated name, content, or language columns. Translation rows use `locale`, a canonical foreign key, and a derived `normalized_name`. Unique indexes permit one translation per identity and locale, and foreign keys protect ownership.

English is the default locale and its name is required. Descriptions are optional. Cocktail history is also optional. Localized fields fall back independently to English when absent or blank. No historical claims, reference dates, or source records have been added.

```ruby
gin = Ingredient.create!(name: "Gin", description: "English description")
Globalize.with_locale(:ja) do
  gin.update!(name: "ジン", description: "日本語の説明")
  gin.name # "ジン"
end
gin.name # "Gin"
gin.display_name # "Gin", retained for compatibility
```

The same API applies to `Cocktail` and `Utensil`. Use `Globalize.with_locale` for scoped reads and writes. Canonical models have no `language` attribute. Translation records remain available through `translations` and `translation_for(:ja, false)` for explicit inspection without display fallback.

`CocktailAlias`, `IngredientAlias`, and `UtensilAlias` hold accepted alternative names only, with `name`, `language`, `normalized_name`, and a canonical foreign key. There is no default alias, and no alias is automatically created for a canonical translation or user submission.

```ruby
gin.ingredient_aliases.create!(name: "Gim", language: "pt")
Ingredient.lookup("ジン", language: "ja")
Ingredient.lookup("Gim", language: "pt")
```

`.lookup(text, language:)` searches canonical translation names with that exact locale and accepted aliases with that language. It returns all matching usable identities, including ambiguous names. Display fallback never makes an English name appear to be an actual Japanese translation in lookup. Normalization applies Unicode NFKC, lowercase, trimmed text and collapsed whitespace; the submitted display text remains unchanged. Repeated normalized aliases are prohibited only within the same identity and language.

Model validation requires a usable English name. English translation names cannot be blank, and normal model writes cannot delete the English translation or move translation rows between identities or locales. Deleting an unreferenced canonical identity removes its translations and aliases. Use model writes rather than callback-skipping bulk operations. A record without an English name is unusable, safely displays nil in English, and cannot qualify for lookup, publication, or marketplace results even if other locales exist.

## Owned recipes and availability

`UserCocktailIngredient` stores each recipe ingredient line's identity, exact `submitted_text`, language, fractional quantity and measuring unit. Repeated ingredient identities are allowed for mixing and garnish. `UserCocktailUtensil` stores explicit utensil requirements with submitted text and language, with one row per utensil per recipe. Ice is an ingredient. Canonical translations never replace these submissions.

`RecipeStep` stores unchanged prose in zero-based `position` order. `StepMention` links a character range, with inclusive `start_offset`, exclusive `end_offset`, and `quoted_text`, to exactly one ingredient or utensil. Mentions do not establish requirements. Model updates to step text delete mentions in the same transaction; mention saves check the current saved prose under a step lock. Use model writes for steps and mentions.

New variations default to private drafts. Drafts may omit a name, canonical cocktail, ingredients, or steps. Their personal language defaults to `und`, meaning undetermined. Publication requires a personal name, specified language, a usable canonical cocktail, ingredients, and preparation steps. All ingredient and utensil identities must also have usable English names. Quantities are optional, positive when supplied, and require a measuring unit.

`UserCocktail.marketplace` includes only complete, public, published recipes. `UserCocktail.readable_by(user)` also includes the user's own variations. Direct HTML and JSON reads apply marketplace eligibility or allow the owner; only owners can edit or delete.

```ruby
UserCocktail.makeable_with(ingredient_ids: [gin.id, ice.id], utensil_ids: [jigger.id])
```

This returns marketplace variations with no missing ingredient or utensil identities. Extras and repeated available IDs are harmless. It checks possession, not quantities, substitutions, or mentions in prose. A recipe can have no utensil requirements.

## Routes and current UI limits

Recipe browsing and authoring use `UserCocktailsController` at `/user_cocktails`, with helpers such as `user_cocktail_path`. The root page lists readable variations. Forms and JSON write requests use the `user_cocktail` parameter root. JSON responses use `cocktail_id` for the canonical reference. There is no canonical CRUD route.

The form edits a personal name, language, preparation time and one free-text step, creating private drafts. Multiple structured steps are read-only in this form to prevent flattening. Canonical management and translations, requirement authoring, alias management, publication, and multi-step editing currently require model access. There is no admin or translation UI, availability-search UI, machine translation, or AI integration.

## Authentication and verification

Public registration is at `/registration/new` and sign-in is at `/session/new`. Password resets require Action Mailer delivery and URL host configuration.

Load a fresh test database and run the suite:

```sh
RAILS_ENV=test bin/rails db:drop
RAILS_ENV=test bin/rails db:create
RAILS_ENV=test bin/rails db:schema:load
VITE_RUBY_AUTO_BUILD=false PARALLEL_WORKERS=1 bin/rails test
bin/rubocop
```

The test command disables automatic Vite builds. It does not verify production assets or browser appearance.
