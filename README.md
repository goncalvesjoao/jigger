# ShakeStir

ShakeStir is a cocktail "marketplace" for discovery, with no buying or selling. This monorepo is intended to contain multiple implementations of the same product.

This README records the initial product vision. It does not describe the current implementation status.

## Product vision

Users create accounts and add their own cocktail recipes. Different users can have their own variations of the same cocktail.

Recipes have separate visibility and publication readiness states. Visibility is private or public. Publication readiness is draft or published; drafts are recipes that are not ready to publish.

Landing-page searches return individual complete, public, published recipes with author handles and exact recipe links. Recipe names and linked cocktail names are searchable. Every recipe belongs to an author; seeded recipes belong to `@shakestir` and follow the same filtering and permission rules as all other recipes. Owners find private recipes and drafts in My Recipes.

## Search by availability

Users can enter the ingredients and utensils currently available to them, for example three ingredients plus their equipment. ShakeStir resolves that input to canonical ingredient and utensil identities.

The marketplace returns public, published recipe variations whose required ingredients and utensils are all available. It checks each variation's own requirements. Extra available items do not disqualify a recipe. Ice counts as an ingredient.

## Domain concepts

| Concept | Meaning |
| --- | --- |
| Cocktail | A canonical drink identity shared by recipes, with names, description and history. |
| Recipe | A particular way to make a drink, optionally assigned to a cocktail and owned by a user. |
| Canonical ingredient | A stable, unique ingredient identity shared across recipes. Ice is an ingredient. |
| Utensil | An explicit domain object with its own database table or equivalent persistent collection. Utensils include jiggers, glasses and other glassware, and other cocktail equipment. |
| Mention | Text in a preparation step associated with a system object, such as a canonical ingredient or utensil. The association preserves the submitted prose. |

## Preserve submitted text

Each recipe preserves every ingredient's exact submitted text, including names in any writing system and misspellings. Internally, that text maps to a canonical ingredient identity shared across recipes. Matching must not replace or correct what the user wrote.

Original recipes need no canonical cocktail. Seeds or trusted model access maintain canonical identities and assignments; publishing does not automatically create a cocktail. Cocktails hold an optional photo, description, history, their sources and historical publication dates. Cached seeds populate missing cocktail photos independently of recipe photos and preserve existing uploads. Recipes retain optional source references and URLs crediting their quantities and instructions.

Preparation steps remain ordered, free-text instructions. ShakeStir should recognize mentions within those steps and associate the relevant text with system objects while preserving the original prose. Utensil mentions should resolve to utensil identities.

Canonical cocktail seed content includes researched English descriptions, histories and citations, with uncertainty stated explicitly. Re-running seeds fills missing content and preserves curated text and source groups; see the [seed source notes](db/seeds/thecocktaildb/CANONICAL_SOURCES.md).

## Proposed entity matching

Jev, identified by the user as the AI decision-making model developed by TypeSafe AI, is a proposed component for entity matching. Its task would be to associate submitted ingredient and utensil names with their unique canonical database representations, while preserving the original submitted text alongside the matches.

Jev is optional. A sufficiently fast open-source alternative could serve the same purpose. No dependency has been chosen or integration implemented as part of this proposal. A proposed match does not guarantee the correct identity.

## Open questions

- How should ambiguous matches be resolved, and who confirms the intended identity?
- What should happen when an ingredient, cocktail, or utensil mention has no match? When should ShakeStir create a new identity or leave a mention unresolved?

Marketplace search expands from the navbar into searchable ingredient and utensil selections with removable chips. By default, results contain every selected ingredient and utensil, with additional items allowed. “Only show recipes I can make” instead treats selections as the user's available ingredients and utensils: all required items must be available, while optional ingredients are ignored. Text search combines with either mode; filters remain in detail and pagination links. Clearing filters returns to all marketplace recipes. Each closed ingredient and utensil picker shows “Add ingredients/utensils” when empty, a selected count for include mode, or an available count with “Only these” for availability mode; mode explanations remain inside the pickers.

## Catalog maintenance

Catalog records and canonical assignments are maintained through seeds or trusted model access. Authors manage their own recipes through the recipe editor.

## Cocktail and recipe detail pages

Cocktail pages show canonical background and a single list of public recipes from all authors. Search and availability filters apply equally to every recipe. Recipe pages focus on ingredients, tools and preparation, with canonical background in a collapsed “More about this cocktail” section below instructions. Related recipes exclude the current recipe, private recipes and drafts. Recipe photos fall back to the linked readable cocktail’s photo, then to a placeholder.

History and sources use native disclosure controls. The layouts adapt to narrow screens and larger text, retain keyboard focus indicators, and respect reduced-motion, reduced-transparency and increased-contrast preferences.
