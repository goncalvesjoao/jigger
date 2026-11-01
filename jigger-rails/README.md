# Jigger Rails

## Recipes and ownership

`Cocktail` represents a canonical drink identity with translated names, description, history and aliases. It has many recipes.

`Recipe` is the model for system-managed recipes, community recipes, and official recipes. It contains optional `user_id` and `cocktail_id`, an independent `official` flag, preparation metadata, ingredients, utensils, ordered steps, translations, aliases, and an optional photo. Servings default to one.

A missing owner means Jigger manages the recipe. Official means Jigger endorses the recipe; an import is not automatically official. Recipes have no parent or variant relationship; cocktail assignment groups versions of the same drink.

`RecipePolicy` permits public reads of complete, public, published recipes. Owners can read their own drafts and private recipes and edit their non-official recipes. Admins can read and manage every recipe, including official and system-managed recipes. Set `User#admin` through trusted model/console access; public registration cannot set it. The authoring endpoint always assigns new recipes to the signed-in user. Create ownerless recipes through seeds or trusted model access.

## Database setup

The migrations create canonical cocktails and recipes directly, including recipe requirements, translations, aliases and steps. They assume a fresh database; there is no migration to convert the previous combined cocktail model. For an existing local database, `bin/rails db:reset` deletes it and recreates it from the schema and seeds. Use `bin/rails db:migrate` to build an empty database from migrations. Development and production databases were not reset during implementation.

## Marketplace and sources

The homepage at `/cocktails` filters `Recipe.marketplace`, with optional `q` search against recipe and canonical cocktail names and aliases. It groups matches by cocktail and shows matching-recipe counts; unassigned recipes appear individually. The marketplace uses Kaminari to paginate 24 cocktail groups at a time in stable newest-first order. Lazy Turbo Frames load subsequent pages as they enter the viewport, with a normal next-page link when JavaScript is unavailable. Search and availability filters persist across pages, and each group retains all matching recipes and its full count. HTML and JSON accept `page`; JSON keeps its existing array shape. Cocktail detail pages list matching recipes and preserve search filters. Optional `ingredient_ids[]` and `utensil_ids[]` query parameters restrict results to makeable recipes; omitted availability lists are treated as empty when either parameter is supplied. `/recipes` retains a flat recipe listing and the authoring endpoints. It displays official status. Private recipes and drafts stay out of homepage results even for their owner.

Publication requires a name in at least one locale, a specified `language`, ingredient lines, and preparation steps. It does not require a cocktail assignment, owner, English translation, or recipe photo. Referenced ingredients and utensils must remain usable shared catalog identities with English names and exclusive photos. Missing catalog content excludes affected recipes from public reads and availability searches.

`Recipe#published_at` records publication on Jigger. Both cocktails and recipes have optional `source_reference` and `source_url`: cocktail sources support identity, description and history; recipe sources credit quantities and instructions. Only cocktails have historical source dates. `source_published_on` stores an exact historical publication date when known; use `source_date_note` for approximate years, uncertain dates, or discovery context instead of inventing a day. Source URLs accept only HTTP or HTTPS.

## Translations and requirements

Globalize exposes translated cocktail `name`, `description` and `history`, and recipe `name`. Each translation table has one row per record and locale. Use `Globalize.with_locale(:ja)` for scoped writes. `display_name` falls back to another available translation if the current locale has no name. Recipes need no English translation; shared `Ingredient` and `Utensil` still require English names and protect their English translations.

`CocktailAlias`, `RecipeAlias`, `IngredientAlias`, and `UtensilAlias` contain accepted alternative names. `.lookup(text, language:)` matches exact normalized translation names or accepted aliases in that language. Recipe lookup is an internal matching operation; use `.marketplace.search(text)` for public discovery and `.readable_by(user)` when resolving a readable recipe. Normalization applies Unicode NFKC, lowercase, trimming, and collapsed whitespace, preserving display text.

`RecipeIngredient` preserves exact `submitted_text`, language, position, optionality, role, preparation notes, and optional positive quantity with measuring unit. Repeated ingredients are allowed. `RecipeUtensil` stores explicit requirements with submitted text and language. Ice is an ingredient.

`RecipeStep` stores ordered prose. `StepMention` associates character ranges with an ingredient or utensil, preserving the prose. Mentions do not establish requirements. Updating a step invalidates its mentions in the same transaction; mention saves check current prose under a lock.

```ruby
Recipe.makeable_with(ingredient_ids: [gin.id, ice.id], utensil_ids: [jigger.id])
```

Availability checks required ingredient and utensil identities, ignores optional ingredients, and accepts repeated/extra available IDs. It does not compare quantities or substitute ingredients.

## Seeds

`bin/rails db:seed` reads the checked-in TheCocktailDB JSON and cached photos without network calls. It imports system-managed recipes with source URLs, ingredient lines containing the original measurements, and preparation instructions. Imported recipes are public when complete and explicitly linked to canonical identities by normalized English name. Seeds preserve official recipes and user-owned recipes and avoid duplicate recipes, requirements, steps, and attachments on repeated runs.

Ingredient photos must exist in the cache for referenced ingredients. Refresh using `ruby db/seeds/thecocktaildb/build_seed_cache.rb`, which downloads the selected cocktail responses plus ingredients and photos required by those recipes. Imported measurement wording is preserved in `submitted_text`; numeric quantities are not inferred from ambiguous source measurements.

## Photos

Recipe images are optional; catalog ingredient and utensil images are required. Uploads must be fresh file bytes, not existing blobs or signed IDs. Still JPEG, PNG, and WebP are accepted, up to 10 MB and 25 megapixels. The validator decodes bytes with libvips, rejects corrupt/animated files, and retains the saved image when a replacement fails.

`GET /recipes/:recipe_id/image?size=card` authorizes the recipe before redirecting to a temporary storage URL. `card` bounds WebP images to 320 by 240, `detail` to 1200 by 1200, and `original` delivers the validated original. Catalog endpoints are `/ingredients/:ingredient_id/image` and `/utensils/:utensil_id/image`. Delivery refuses shared blobs and returns `Cache-Control: private, no-store`.

Issued storage URLs remain bearer access until expiry, normally five minutes, even if permissions subsequently change. Default Active Storage routes are disabled except signed disk downloads. Development uses `storage/`; tests use `tmp/storage/`. Back up database and storage together. Active Storage jobs must run to reclaim replaced files. Production remote storage is not configured.

## Current UI limits and checks

The form edits recipe content, source credits, visibility, publication state, and an optional photo. Admins can change official status and assign or clear the canonical cocktail. Canonical identities can be created at `/admin/cocktails/new` and edited at `/admin/cocktails/:id/edit` by admins. Deleting an identity leaves its recipes unassigned and discoverable. Multiple structured steps are read-only in this form to prevent flattening. Ingredient/utensil requirement authoring, translations, aliases, and system-owned recipe creation currently use model access. There is no admin dashboard, automatic matching, or availability-search UI.

Public registration is at `/registration/new`; sign-in is at `/session/new`. Password resets require Action Mailer configuration.

```sh
VITE_RUBY_AUTO_BUILD=false PARALLEL_WORKERS=1 bin/rails test
bin/rubocop
bin/rails zeitwerk:check
```

Use the project's mise Ruby. Tests do not verify production assets or browser appearance.
