# Jigger Rails

## Local development

With the project's mise Ruby active and npm dependencies installed, set up the
Ruby dependencies, Foreman, and database:

```sh
bin/setup --skip-server
bin/dev
```

This starts Rails at `http://localhost:3000` and the Vite dev server at
`http://localhost:3036`, with combined logs. Press Ctrl+C to stop both processes.
`bin/setup` installs Foreman if it is missing. `bin/dev` reports an error with
setup instructions when Foreman is unavailable; it does not install dependencies.
Foreman runs outside the application's bundle and does not need a Gemfile entry.

To use a different Rails port, run `PORT=3001 bin/dev`. Vite's port is configured
separately in `config/vite.json`.

## Recipes and ownership

`Cocktail` represents a canonical drink identity with translated names, description, history. It has many recipes. An optional `parent_cocktail_id` links a variant to its parent cocktail; `variants` exposes its children. Cycles are rejected, and deleting a parent clears the link on its variants. Admin cocktail forms can edit the parent.

`Recipe` represents a preparation shared by its author. It contains required `user_id` and optional `cocktail_id`, preparation metadata, ingredients, utensils, ordered steps, translations, and an optional photo. Servings default to one.

Every recipe belongs to a user. Seeded recipes belong to the public `@jigger` account, identified by a trusted `system_key` of `jigger`. Jigger-authored recipes follow the same rules and appear in the same lists as every other recipe. Recipes have no parent or variant relationship; cocktail assignment groups versions of the same drink.

`RecipePolicy` permits public reads of complete, public, published recipes. Owners can read their own drafts and private recipes and edit their recipes. Admins can read and manage every recipe. Set `User#admin` through trusted model/console access; public registration cannot set it. The authoring endpoint always assigns new recipes to the signed-in user. Seeds create the Jigger account with a random password; public forms cannot set its system identity or administrator access.

## Database setup

The migrations create canonical cocktails and recipes directly, including recipe requirements, translations and steps. They assume a fresh database; there is no migration to convert the previous combined cocktail model. For an existing local database, `bin/rails db:reset` deletes it and recreates it from the schema and seeds. Use `bin/rails db:migrate` to build an empty database from migrations. Profile, handle, Favorites identity and cocktail parent fields are folded into their original create migrations. These edits target a fresh database; existing databases must be recreated. Development and production databases were not reset during implementation.

## Marketplace and sources

The homepage at `/cocktails` filters `Recipe.marketplace`, searching recipe names and linked canonical cocktail names. Results are individual recipes with exact recipe links and author handles, paginated 24 at a time in stable newest-first order. Lazy Turbo Frames preserve filters and provide a normal next-page link. JSON returns an array of recipe objects. Private recipes and drafts stay out of the marketplace even for owners and admins; owners use My Recipes. `/recipes` also retains a flat recipe listing and the authoring endpoints. Cocktail pages list recipes from every author together; all filters apply equally. Cocktail JSON exposes matching `recipes` and filtered `other_recipes`, with no separate author category.

Handles are unique, editable in profile settings, and public attribution on published public recipes. New handles start from a normalized email local part; collisions receive a random suffix and unusable names fall back to `member`. The `jigger` handle is reserved. Every author has a public profile. Profile pages always list only published public recipes and public collections, including for owners and admins. Collection previews also exclude private recipes and drafts; owners manage those in My Recipes and My Collections. Email appears only in the owner-only My account page. Recipe photos take priority over linked readable cocktail photos, and canonical background is collapsed below the preparation.

Starring uses existing Favorites collection memberships. The `favorites` system key survives renaming, keeps the collection private, and prevents deletion. Saving through the collection picker and starring affect the same membership. Image-overlay controls show public Favorites-based star totals and update without page navigation. Counts include only memberships in system Favorites collections, regardless of their display name; other collections do not count. `recipes.stars_count` caches this total using transactional, atomic Active Record counter updates on Favorites membership creation and destruction. A standard unconditional association counter cache would include ordinary collection saves, so the callbacks filter to Favorites. Membership identities and collection system keys cannot be reassigned; remove and recreate memberships to move them. Views read the cached count and load only the current user’s starred recipe IDs once per request. Signed-out visitors can see totals and follow the star link to sign in. Star controls and the collection picker synchronize after changes, and ordinary form submissions work without JavaScript. Star ranking, forking, and automatic canonical matching are not implemented.

Publication requires a name in at least one locale, a specified `language`, ingredient lines, and preparation steps. It does not require a cocktail assignment, owner, English translation, or recipe photo. Referenced ingredients and utensils must remain usable shared catalog identities with English names and exclusive photos. Missing catalog content excludes affected recipes from public reads and availability searches.

`Recipe#published_at` records publication on Jigger. Both cocktails and recipes have optional `source_reference` and `source_url`: cocktail sources support identity, description and history; recipe sources credit quantities and instructions. Only cocktails have historical source dates. `source_published_on` stores an exact historical publication date when known; use `source_date_note` for approximate years, uncertain dates, or discovery context instead of inventing a day. Source URLs accept only HTTP or HTTPS.

## Translations and requirements

Globalize exposes translated cocktail `name`, `description` and `history`, and recipe `name`. Each translation table has one row per record and locale. Use `Globalize.with_locale(:ja)` for scoped writes. `display_name` falls back to another available translation if the current locale has no name. Recipes need no English translation; shared `Ingredient` and `Utensil` still require English names and protect their English translations.

`.lookup(text, language:)` matches exact normalized translated names in that language. Recipe lookup is an internal matching operation; use `.marketplace.search(text)` for public discovery and `.readable_by(user)` when resolving a readable recipe. Normalization applies Unicode NFKC, lowercase, trimming, and collapsed whitespace, preserving display text.

`RecipeIngredient` preserves exact `submitted_text`, language, position, optionality, role, preparation notes, and optional positive quantity with measuring unit. Repeated ingredients are allowed. `RecipeUtensil` stores explicit requirements with submitted text and language. Ice is an ingredient.

`RecipeStep` stores ordered prose. `StepMention` associates character ranges with an ingredient or utensil, preserving the prose. Mentions do not establish requirements. Updating a step invalidates its mentions in the same transaction; mention saves check current prose under a lock.

```ruby
Recipe.makeable_with(ingredient_ids: [gin.id, ice.id], utensil_ids: [jigger.id])
```

Availability checks required ingredient and utensil identities, ignores optional ingredients, and accepts repeated/extra available IDs. It does not compare quantities or substitute ingredients.

## Seeds

`bin/rails db:seed` reads the checked-in TheCocktailDB JSON and cached photos without network calls. It imports system-managed recipes with source URLs, ingredient lines containing the original measurements, and preparation instructions. Imported recipes are public when complete and explicitly linked to canonical identities by normalized English name. Seeds preserve all existing recipes and avoid duplicate recipes, requirements, steps, and attachments on repeated runs.

Ingredient photos must exist in the cache for referenced ingredients. Refresh using `ruby db/seeds/thecocktaildb/build_seed_cache.rb`, which downloads the selected cocktail responses plus ingredients and photos required by those recipes. Imported measurement wording is preserved in `submitted_text`; numeric quantities are not inferred from ambiguous source measurements.

The seeds also load a [59-entry utensil catalog](db/seeds/utensils/README.md) with original English descriptions and a separate generated photo for each entry. It covers mixing, measuring, straining, prep, ice, specialty tools and glassware. Repeat runs preserve existing utensil curation and fill missing descriptions or photos. All assets are checked in; seeding needs no image-generation credentials or network access.

## Photos

Recipe images are optional; catalog ingredient and utensil images are required. Uploads must be fresh file bytes, not existing blobs or signed IDs. Still JPEG, PNG, and WebP are accepted, up to 10 MB and 25 megapixels. The validator decodes bytes with libvips, rejects corrupt/animated files, and retains the saved image when a replacement fails.

`GET /recipes/:recipe_id/image?size=card` authorizes the recipe before redirecting to a temporary storage URL. `card` bounds WebP images to 320 by 240, `detail` to 1200 by 1200, and `original` delivers the validated original. Catalog endpoints are `/ingredients/:ingredient_id/image` and `/utensils/:utensil_id/image`. Delivery refuses shared blobs and returns `Cache-Control: private, no-store`.

Issued storage URLs remain bearer access until expiry, normally five minutes, even if permissions subsequently change. Default Active Storage routes are disabled except signed disk downloads. Development uses `storage/`; tests use `tmp/storage/`. Back up database and storage together. Active Storage jobs must run to reclaim replaced files. Production remote storage is not configured.

## Current UI limits and checks

The form edits recipe content, source credits, visibility, publication state, and an optional photo. Admins can assign or clear the canonical cocktail and manage recipe ownership in catalog administration. Canonical identities can be created at `/admin/cocktails/new` and edited at `/admin/cocktails/:id/edit` by admins. Deleting an identity leaves its recipes unassigned and discoverable. Multiple structured steps are read-only in this form to prevent flattening. Ingredient/utensil requirement authoring, translations, and system-owned recipe creation currently use model access. Availability filters are available in Explore for ingredients and utensils, with include-selected and use-only-available modes. Catalog administration provides list and editing pages; automatic extraction from preparation prose is not implemented. The product/design review and page coverage are recorded in `design-review.md`.

Profile settings support optional JPEG, PNG, or WebP photo uploads with the same 10 MB / 25 megapixel validation as recipe photos. `GET /profiles/:id/image` publicly delivers profile photos through the existing validated-image endpoint. The profile page and account menu use the uploaded image, with the existing Gravatar fallback for the owner and initials for public visitors. Owners can remove a photo to restore the fallback. Profile images use existing Active Storage tables, so no migration is needed. Seeds attach cached fictional portraits for Leo and Alex and a still-life image for Jigger; existing uploads are preserved. Generation prompts and asset details live in `db/seeds/avatars/README.md`.

`GET /my/account` shows the current user’s email; both it and `DELETE /my/account` require authentication and prevent page caching. The account dropdown links to this private page. Deletion requires the current password, uses the session’s user regardless of submitted IDs, and cascades through owned recipes, structured recipe data and translations, collections, memberships, legacy likes, and all sessions in one transaction. Other users’ saves of deleted recipes are removed; stars on surviving recipes are decremented when Favorites memberships are removed. Profile and recipe attachments are detached on deletion and their blobs/files are purged through Active Storage jobs after commit. Run background jobs to complete file cleanup. Shared catalog records and other users’ content remain. Success clears the login cookie and session; dependency failures roll back data and retain the session.

Public registration is at `/registration/new`; sign-in is at `/session/new`. Password resets require Action Mailer configuration.

```sh
VITE_RUBY_AUTO_BUILD=false PARALLEL_WORKERS=1 bin/rails test
bin/rubocop
bin/rails zeitwerk:check
```

Use the project's mise Ruby. Tests do not verify production assets or browser appearance.

Development/test seeds also create fictional demo accounts (never seeded in production):

| Account | Email | Password | Content |
| --- | --- | --- | --- |
| Leo Sterling, fictional star bartender | leo@jigger.example | password | Public profile, three published signature recipes, Halloween Special, Christmas, and House Signatures collections |
| Alex Morgan, home bartender | alex@jigger.example | password | Public profile, two private drafts, four private collections mixing personal and public recipes |

Demo seeds preserve existing accounts and recipes, including changed passwords, and fill missing collection memberships on repeat runs. Variant seeds use names rather than database IDs and preserve existing parent assignments.
