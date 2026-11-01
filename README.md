# Jigger

Jigger is a cocktail "marketplace" for discovery, with no buying or selling. This monorepo is intended to contain multiple implementations of the same product.

This README records the initial product vision. It does not describe the current implementation status.

## Product vision

Users create accounts and add their own cocktail recipes. Different users can have their own variations of the same cocktail.

Recipes have separate visibility and publication readiness states. Visibility is private or public. Publication readiness is draft or published; drafts are recipes that are not ready to publish.

Landing-page searches filter complete, public, published recipes, then group matches by canonical cocktail. Each cocktail card counts matching non-official recipes and hides the counter when it is zero; unassigned recipes appear individually with a count of one. System-managed and user-owned recipes appear together, with official Jigger recipes identified. Private recipes and drafts do not appear in the public marketplace. Public, published official recipes always appear in full within the cocktail details, regardless of search or availability filters. They are excluded from matching counts and both community recipe-card lists. Each cocktail can have at most one official recipe, across all visibility and publication states. Every non-official recipe must belong to a user.

## Search by availability

Users can enter the ingredients and utensils currently available to them, for example three ingredients plus their equipment. Jigger resolves that input to canonical ingredient and utensil identities.

The marketplace returns public, published recipe variations whose required ingredients and utensils are all available. It checks each variation's own requirements. Extra available items do not disqualify a recipe. Ice counts as an ingredient.

## Domain concepts

| Concept | Meaning |
| --- | --- |
| Cocktail | A canonical drink identity shared by recipes, with names, aliases, description and history. |
| Recipe | A particular way to make a drink, optionally assigned to a cocktail and optionally owned by a user. |
| Official recipe | A recipe presented as Jigger’s reference recipe, independently of its owner. For now, userless TheCocktailDB seed imports are official. |
| Canonical ingredient | A stable, unique ingredient identity shared across recipes. Ice is an ingredient. |
| Utensil | An explicit domain object with its own database table or equivalent persistent collection. Utensils include jiggers, glasses and other glassware, and other cocktail equipment. |
| Mention | Text in a preparation step associated with a system object, such as a canonical ingredient or utensil. The association preserves the submitted prose. |

## Preserve submitted text

Each recipe preserves every ingredient's exact submitted text and its language, including native-language names and misspellings. Internally, that text maps to a canonical ingredient identity shared across recipes. Matching must not replace or correct what the user wrote.

Original recipes need no canonical cocktail. Admins curate canonical identities and assignments; publishing does not automatically create a cocktail. Cocktails hold an optional photo, description, history, their sources and historical publication dates. Admins upload cocktail photos; cached seeds populate missing cocktail photos independently of recipe photos and preserve existing uploads. Recipes retain optional source references and URLs crediting their quantities and instructions.

Preparation steps remain ordered, free-text instructions. Jigger should recognize mentions within those steps and associate the relevant text with system objects while preserving the original prose. Utensil mentions should resolve to utensil identities.

Canonical cocktail seed content includes researched English descriptions, histories and citations, with uncertainty stated explicitly. Re-running seeds fills missing content and preserves curated text and source groups; see the [seed source notes](jigger-rails/db/seeds/thecocktaildb/CANONICAL_SOURCES.md).

## Proposed entity matching

Jev, identified by the user as the AI decision-making model developed by TypeSafe AI, is a proposed component for entity matching. Its task would be to associate submitted ingredient and utensil names with their unique canonical database representations, while preserving the original submitted text and language alongside the matches.

Jev is optional. A sufficiently fast open-source alternative could serve the same purpose. No dependency has been chosen or integration implemented as part of this proposal. A proposed match does not guarantee the correct identity.

## Open questions

- How should ambiguous matches be resolved, and who confirms the intended identity?
- What should happen when an ingredient, cocktail, or utensil mention has no match? When should Jigger create a new identity or leave a mention unresolved?

Marketplace search expands from the navbar into searchable ingredient and utensil selections with removable chips. By default, results contain every selected ingredient and utensil, with additional items allowed. “Only show recipes I can make” instead treats selections as the user's available ingredients and utensils: all required items must be available, while optional ingredients are ignored. Text search combines with either mode; filters remain in detail and pagination links. Clearing filters returns to all marketplace cocktails.
