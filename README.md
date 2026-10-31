# Jigger

Jigger is a cocktail "marketplace" for discovery, with no buying or selling. This monorepo is intended to contain multiple implementations of the same product.

This README records the initial product vision. It does not describe the current implementation status.

## Product vision

Users create accounts and add their own cocktail recipes. Different users can have their own variations of the same cocktail.

Recipes have separate visibility and publication readiness states. Visibility is private or public. Publication readiness is draft or published; drafts are recipes that are not ready to publish.

Landing-page searches for a cocktail name should find its shared cocktail identity and show associated variations that are both public and published. Private recipes and drafts do not appear in the public marketplace.

## Search by availability

Users can enter the ingredients and utensils currently available to them, for example three ingredients plus their equipment. Jigger resolves that input to canonical ingredient and utensil identities.

The marketplace returns public, published recipe variations whose required ingredients and utensils are all available. It checks each variation's own requirements. Extra available items do not disqualify a recipe. Ice counts as an ingredient.

## Domain concepts

| Concept | Meaning |
| --- | --- |
| Canonical cocktail | A shared identity for a cocktail, connecting different users' recipe variations. |
| Recipe variation | A user's owned recipe, associated with a canonical cocktail. It contains ingredients and ordered, free-text preparation steps, with separate visibility and publication readiness states. |
| Canonical ingredient | A stable, unique ingredient identity shared across recipes. Ice is an ingredient. |
| Utensil | An explicit domain object with its own database table or equivalent persistent collection. Utensils include jiggers, glasses and other glassware, and other cocktail equipment. |
| Mention | Text in a preparation step associated with a system object, such as a canonical ingredient or utensil. The association preserves the submitted prose. |

## Preserve submitted text

Each recipe preserves every ingredient's exact submitted text and its language, including native-language names and misspellings. Internally, that text maps to a canonical ingredient identity shared across recipes. Matching must not replace or correct what the user wrote.

Each user's recipe variation similarly maps to a canonical cocktail identity. This allows different variations to belong to the same cocktail without treating the recipes as identical.

Preparation steps remain ordered, free-text instructions. Jigger should recognize mentions within those steps and associate the relevant text with system objects while preserving the original prose. Utensil mentions should resolve to utensil identities.

## Proposed entity matching

Jev, identified by the user as the AI decision-making model developed by TypeSafe AI, is a proposed component for entity matching. Its task would be to associate submitted ingredient, utensil, and cocktail names with their unique canonical database representations, while preserving the original submitted text and language alongside the matches.

Jev is optional. A sufficiently fast open-source alternative could serve the same purpose. No dependency has been chosen or integration implemented as part of this proposal. A proposed match does not guarantee the correct identity.

## Open questions

- How should ambiguous matches be resolved, and who confirms the intended identity?
- What should happen when an ingredient, cocktail, or utensil mention has no match? When should Jigger create a new identity or leave a mention unresolved?
