# Jigger

<!-- impeccable:product-schema 1 -->

## Scope

This product record applies across the monorepo and its implementations. Current implementation evidence refers to `jigger-rails/`; planned capabilities remain product direction across implementations.

## Platform

web

## Users

Jigger serves home cocktail enthusiasts discovering and making drinks, recipe creators sharing and organizing their work, and professional bartenders managing and finding recipes. All three audiences are confirmed; their relative priority remains open.

A central usage situation is someone actively preparing a drink who needs to follow instructions, check an ingredient or utensil, or quickly find their next drink.

## Product Purpose

Help people find the drink they want and prepare it with minimal interruption. During mixing, success means finding the relevant recipe and following its steps without ads or unrelated content competing for attention.

Support discovering, creating, organizing, and sharing both alcoholic and non-alcoholic drinks.

## Positioning

Jigger is a recipe-sharing marketplace with no sales. Professional bartenders and home creators can publish recipes and build public profiles; people can also browse published recipes while keeping their own profiles and recipes private.

The product promise is relevance at the moment of mixing: give people what they are looking for, when they need it, without ads or extra fluff.

The intended combination is practical discovery based on available ingredients and tools, a queue for the drinks being made now, taste-based discovery, and recipes whose ingredients and utensils can be understood in context. These are product commitments and direction, not a claim that every capability already ships or is unique in the market.

## Operating Context

People may be mixing a drink while using the app and may need to search for another drink during preparation. Instructions and controls should remain easy to read and operate in that situation. The active mixing interface takes inspiration from point-of-sale systems: large, easy-to-tap controls, readable instructions, and a session queue for drinks someone plans to make.

Browsing and authoring can involve more detail; the active mixing experience should prioritize the recipe instructions and directly relevant help. Background stories and other secondary information should not interrupt preparation.

## Capabilities and Constraints

### Established behavior

- A **Cocktail** is a canonical drink identity; a **Recipe** is a particular preparation. The association is optional so original recipes work independently. Automatic canonical matching is a future capability.
- Marketplace search returns individual eligible published public recipes and opens the exact recipe, including for broad cocktail queries. Recipe names and linked canonical names remain searchable. Owners find drafts and private recipes in **My Recipes**.
- Recipe results and pages identify the recipe as **@handle / Recipe title**. Handles remain visible on public recipes even if the author's profile is private; private profiles are not linked. Every recipe has an author. Seeded recipes belong to the public **@jigger** account and follow the same discovery, filtering, and permission rules as every other author’s recipes. Handles start from the email local part, with normalization and collision suffixes, and can be changed in profile settings. The Jigger handle is reserved for the Jigger account.
- Recipe pages prioritize ingredients, tools, and steps. Photos prefer the recipe's image, falling back to its readable linked cocktail. Canonical history and background appear below instructions in a collapsed **More about this cocktail** section.
- Signed-in users star and unstar individual recipes through membership in their existing private **Favorites** collection. This collection keeps a stable identity even when renamed, remains private, and cannot be deleted. No separate star storage is introduced. Public star totals appear beside an image-overlay star toggle in marketplace results and recipe details. Star totals use a cached counter maintained when Favorites memberships change. Individual Favorites memberships remain private; star-based ranking remains open. Forking is outside the agreed scope.
- Discovery supports recipe/name search and filtering by available ingredient and utensil identities. Availability matching does not currently compare quantities or substitute ingredients.
- **Collections** are user-curated groups of recipes, analogous to playlists. They can be public or private and default to private. New users receive a private **Favorites** collection. Saving a recipe to a collection is reversible.
- Recipes have separate visibility and publication state. Public discovery shows complete, published, public recipes; owners can also access their own drafts and private recipes.
- Profiles can be public or private and default to private. Public profiles list public collections and published public recipes. Owners see all their own content and management controls. Email addresses stay off public profiles.
- Ingredient and utensil records, ordered recipe steps, and step mentions provide structured foundations. Automatic extraction from prose and alternative recommendations are not established user-facing capabilities.
- Cocktail and recipe names support translations. Preserve multilingual content and original preparation prose.
- Rails renders the app, with Turbo/Stimulus interactions and Vite-managed assets. React adoption was deferred. Existing Rails implementation details and operational commands live in `jigger-rails/README.md`.

### Confirmed product direction; not yet shipped as complete workflows

- A queue for drinks the user wants to prepare in the current session. Its relationship to persistent Collections is undecided.
- Taste-based recipe discovery, including sweetness and sourness. Taste vocabulary, scales, and how values are obtained remain open.
- Discovery by alcoholic or non-alcoholic drink. Ingredient alcohol classifications exist; a complete recipe-level discovery workflow remains to be built.
- Smart recipe creation that analyzes preparation steps, infers ingredient and utensil references, and identifies them in the presented recipe.
- Clickable ingredient and utensil references that explain the item and help users find alternatives. Matching rules and handling of uncertain inference remain open.

## Brand Commitments

The product name is **Jigger**. Keep product language direct and useful, with a clean interface serving the act of making a drink. Ad-free use and freedom from distracting extra content are explicit promises.

Previous UI work used the Apple design skill. No new palette, typography, or visual world is established by this product record; the existing implementation remains the design evidence for scoped refinements.

## Evidence on Hand

The Rails application, views, models, tests, and `jigger-rails/README.md` document current implementation behavior. The root `README.md` records the product vision. Seed content and cached photos originate from TheCocktailDB; source credits are part of recipe and cocktail records.

The audience and product direction above come from the product owner's init interview. No user-study results, adoption metrics, testimonials, or competitive superiority claims have been supplied.

## Product Principles

1. Serve the moment of mixing: prioritize the next useful instruction or action.
2. Make discovery practical: connect the desired drink to what the user has available.
3. Preserve agency: make saves reversible and distinguish private work from public sharing.
4. Keep recipe knowledge connected: preserve the relationship between instructions, ingredients, utensils, and their explanations.
5. Represent capabilities honestly: distinguish implemented workflows from product direction and uncertain inference.

## Accessibility & Inclusion

Support reading and operating the app while preparing a drink through clear text and comfortably sized controls. Alcoholic and non-alcoholic drinks both belong in discovery. Preserve multilingual recipe content. No specific compliance standard or tested accessibility conformance has been established.
