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

English is the default locale and its name is required. Each canonical identity also requires exactly one image. Descriptions are optional. Cocktail history is also optional. Localized fields fall back independently to English when absent or blank. No historical claims, reference dates, or source records have been added.

```ruby
gin = File.open("/absolute/path/to/gin.png", "rb") do |file|
  Ingredient.create!(name: "Gin", description: "English description", image: { io: file, filename: "gin.png" })
end
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

New variations default to private drafts. Drafts may omit a name, canonical cocktail, ingredients, or steps. Their personal language defaults to `und`, meaning undetermined. Publication requires a personal name, specified language, a usable canonical cocktail, ingredients, and preparation steps. All canonical cocktail, ingredient and utensil identities must have usable English names and their required photos. Quantities are optional, positive when supplied, and require a measuring unit.

`UserCocktail.marketplace` includes only complete, public, published recipes. `UserCocktail.readable_by(user)` also includes the user's own variations. Direct HTML and JSON reads apply marketplace eligibility or allow the owner; only owners can edit or delete.

```ruby
UserCocktail.makeable_with(ingredient_ids: [gin.id, ice.id], utensil_ids: [jigger.id])
```

This returns marketplace variations with no missing ingredient or utensil identities. Extras and repeated available IDs are harmless. It checks possession, not quantities, substitutions, or mentions in prose. A recipe can have no utensil requirements.

## Recipe photos

Each `UserCocktail` can have one optional `image` through Active Storage. The user variation owns the photo, not canonical `Cocktail`. The existing form accepts a photo and replaces it when a new upload succeeds. Failed image or recipe validation keeps the previously saved photo. Photos are not required for publication, and there is no gallery or photo-removal control.

Accepted uploads are still JPEG, PNG and WebP images, at most 10,000,000 bytes and 25,000,000 pixels in the original. SVG, GIF, HEIC and animated images are rejected. The validator identifies the actual bytes, reads dimensions before decoding, and forces a sequential libvips decode to reject corrupt images without retaining an entire decoded raster. Client MIME type and supplied metadata cannot bypass inspection; an allowed image with a wrong MIME declaration gets its actual content type stored.

Libvips is required alongside the existing `image_processing` gem. It was installed locally and verified as version 8.18.7. On macOS:

```sh
brew install vips
bundle exec ruby -e 'require "vips"; puts Vips.version_string'
```

The Dockerfile already declares libvips packages; its image build was not verified for this change. Missing processing support rejects uploads instead of skipping validation. No additional validation gem or cloud service is configured.

`GET /user_cocktails/:user_cocktail_id/image?size=card` returns an authorized WebP thumbnail within 320 by 240 pixels. `size=detail` returns a WebP within 1200 by 1200, and `size=original` returns the validated original. Variants do not upscale and are generated on demand. All three check the current recipe read policy before issuing a redirect, so only owners can obtain new URLs for private/draft photos, and guests can obtain URLs for public, published eligible recipes. The redirect endpoint returns `Cache-Control: private, no-store`. JSON includes this recipe-based photo URL rather than an issued storage URL.

After authorization and exclusive-attachment checks, the controller redirects to `asset.url(disposition: :inline)` with the normal Active Storage service expiry, currently five minutes. An issued URL is bearer access until it expires: it remains usable after logout or a recipe privacy change, and the storage download does not recheck recipe permissions. New requests to the recipe photo endpoint still check the current policy. Already downloaded files cannot be revoked.

Local Disk URLs serve through Rails' signed disk controller. A future private storage service such as S3 can return its own signed URL through the same interface without proxying every file byte through the recipe controller. The first variant request still processes and stores its derivative normally. No S3 service is configured.

Default Active Storage routes remain disabled globally. The only mounted storage route is GET `/rails/active_storage/disk/:encoded_key/*filename`, named `rails_disk_service`, targeting Rails' `active_storage/disk#show`. Rails verifies its signature, purpose and expiry before serving originals or stored variants. Blob/representation redirect and proxy routes, disk upload routes, and direct-upload routes remain unavailable. Use recipe/catalog endpoints to obtain temporary signed download URLs.

Development uses the `local` Disk service under `storage/`; tests use `tmp/storage/`. The existing production configuration is also local disk, with a production provider still undecided. Back up database records and the entire corresponding storage directory together, keep the directory out of public web roots, and preserve it across app restarts or deployments. Originals and generated variants use disk space. Active Storage jobs purge replaced or deleted attachments; the configured job backend must run to reclaim old files. No remote backup or storage provisioning is included.

## Canonical catalog photos

`Cocktail`, `Ingredient`, and `Utensil` each require exactly one `image` through `CanonicalPhoto`. They share `PhotoAttachment` and `ImageUploadValidator` with `UserCocktail`, including the same still-image formats, original byte/pixel limits, synchronous decoding, bounded variants, and failed-replacement behavior. The personal `UserCocktail` image remains optional.

Catalog photos are public for usable canonical identities through `GET /cocktails/:cocktail_id/image`, `GET /ingredients/:ingredient_id/image`, and `GET /utensils/:utensil_id/image`, with the same `size=original`, `card`, or `detail` options and temporary signed storage redirects. The recipe detail page displays these photos beside its structured ingredient and utensil requirements, preserving submitted labels and their languages. There is no catalog index or catalog authoring UI. Catalog image writes remain model/console/seed operations; ordinary users receive no catalog editing routes or permissions.

Attach or replace with fresh file bytes, for example from a console or seed:

```ruby
ingredient = Ingredient.lookup("Gin", language: "en").first!
File.open("/absolute/path/to/gin.png", "rb") do |file|
  ingredient.update!(image: { io: file, filename: "gin.png" })
end
utensil = Utensil.lookup("Jigger", language: "en").first!
File.open("/absolute/path/to/jigger.jpg", "rb") do |file|
  utensil.update!(image: { io: file, filename: "jigger.jpg" })
end
```

Use `create!` with the same `image` hash during canonical creation; omitting it fails validation. The same interface applies to all three canonical models. Existing `ActiveStorage::Blob` objects, signed IDs, and arbitrary strings are rejected before assignment for all three photo owners. There is no existing-blob selection flow. This prevents reassigning a private recipe attachment into the public catalog. Delivery additionally refuses blobs attached to another record, including malformed/imported shared attachments. Use new file uploads, not direct writes to attachment tables.

Canonical creation and ordinary updates validate image presence, content and single ownership. Assigning `image: nil` or `image: ""` cannot remove a required photo through a normal save. Active Storage's low-level `detach`, `purge`, direct attachment deletion, and raw SQL bypass parent model validations. Public usability checks independently require exactly one image attachment with an exclusively owned blob, so missing, duplicated or shared canonical photos exclude the identity from lookup and recipes from public reads, publication and availability results. Owners can still view and edit their incomplete drafts. This is a model/query invariant, not a database guarantee that files can never be removed. Attach a valid replacement to restore usability.

Catalog photos use the same local Disk service and backup requirements as recipe photos. Back up the database and storage directory together. No new migration, cloud configuration, or native dependency is required for this extension.

## Routes and current UI limits

Recipe browsing and authoring use `UserCocktailsController` at `/user_cocktails`, with helpers such as `user_cocktail_path`. The root page lists readable variations. Forms and JSON write requests use the `user_cocktail` parameter root. JSON responses use `cocktail_id` for the canonical reference. Canonical image routes are read-only; there are no canonical create/update/delete routes.

The form edits a personal name, language, preparation time, an optional photo and one free-text step, creating private drafts. Multiple structured steps are read-only in this form to prevent flattening. Canonical management and translations, requirement authoring, alias management, publication, and multi-step editing currently require model access. There is no admin or translation UI, availability-search UI, machine translation, or AI integration.

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
