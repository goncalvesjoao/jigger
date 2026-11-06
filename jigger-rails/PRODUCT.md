# Jigger

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Jigger serves home cocktail enthusiasts discovering and making drinks, recipe creators sharing and organizing their work, and professional bartenders managing and finding recipes. All three audiences are confirmed; their relative priority remains open.

A central usage situation is someone actively preparing a drink who needs to follow instructions, check an ingredient or utensil, or quickly find their next drink.

## Product Purpose

Help people find the drink they want and prepare it with minimal interruption. During mixing, success means finding the relevant recipe and following its steps without ads or unrelated content competing for attention.

Support discovering, creating, organizing, and sharing both alcoholic and non-alcoholic drinks.

## Positioning

The product promise is relevance at the moment of mixing: give people what they are looking for, when they need it, without ads or extra fluff.

The intended combination is practical discovery based on available ingredients and tools, a queue for the drinks being made now, taste-based discovery, and recipes whose ingredients and utensils can be understood in context. These are product commitments and direction, not a claim that every capability already ships or is unique in the market.

## Operating Context

People may be mixing a drink while using the app and may need to search for another drink during preparation. Instructions and controls should remain easy to read and operate in that situation. Slightly enlarged text and buttons are an explicit usability commitment.

Browsing and authoring can involve more detail; the active mixing experience should prioritize the recipe instructions and directly relevant help. Background stories and other secondary information should not interrupt preparation.

## Capabilities and Constraints

### Established behavior

- A **Cocktail** is a canonical drink identity; a **Recipe** is a particular preparation. Official and community recipes can belong to the same cocktail.
- Discovery supports recipe/name search and filtering by available ingredient and utensil identities. Availability matching does not currently compare quantities or substitute ingredients.
- **Collections** are user-curated groups of recipes, analogous to playlists. They can be public or private and default to private. New users receive a private **Favorites** collection. Saving a recipe to a collection is reversible.
- Recipes have separate visibility and publication state. Public discovery shows complete, published, public recipes; owners can also access their own drafts and private recipes.
- Profiles can be public or private and default to private. Public profiles list public collections and published public recipes. Owners see all their own content and management controls. Email addresses stay off public profiles.
- Ingredient and utensil records, ordered recipe steps, and step mentions provide structured foundations. Automatic extraction from prose and alternative recommendations are not established user-facing capabilities.
- Cocktail and recipe names support translations and aliases. Preserve multilingual content and original preparation prose.
- Rails renders the app, with Turbo/Stimulus interactions and Vite-managed assets. React adoption was deferred. Existing implementation details and operational commands live in the repository and README.md.

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

The running application, Rails views, models, tests, and README.md document current behavior. Seed content and cached photos originate from TheCocktailDB; source credits are part of recipe and cocktail records.

The audience and product direction above come from the product owner's init interview. No user-study results, adoption metrics, testimonials, or competitive superiority claims have been supplied.

## Product Principles

1. Serve the moment of mixing: prioritize the next useful instruction or action.
2. Make discovery practical: connect the desired drink to what the user has available.
3. Preserve agency: make saves reversible and distinguish private work from public sharing.
4. Keep recipe knowledge connected: preserve the relationship between instructions, ingredients, utensils, and their explanations.
5. Represent capabilities honestly: distinguish implemented workflows from product direction and uncertain inference.

## Accessibility & Inclusion

Support reading and operating the app while preparing a drink through clear text and comfortably sized controls. Alcoholic and non-alcoholic drinks both belong in discovery. Preserve multilingual recipe content. No specific compliance standard or tested accessibility conformance has been established.
