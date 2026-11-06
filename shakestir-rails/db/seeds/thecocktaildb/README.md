# Local TheCocktailDB seed cache

This directory stores cached JSON responses and default image files used by `db/seeds.rb`.

The seed task intentionally does not call the public API at runtime. It reads only the files in this directory so local and CI runs remain deterministic and do not break when TheCocktailDB changes or its images disappear.

To refresh the cache, run:

`ruby db/seeds/thecocktaildb/build_seed_cache.rb`

## Canonical cocktail content

`canonical_cocktails.json` contains researched English descriptions, histories and source references, keyed by the cached drink names. It is maintained separately from the API cache and is not replaced by the refresh script. See [CANONICAL_SOURCES.md](CANONICAL_SOURCES.md) for evidence and uncertainty notes.

Seeds fill missing English descriptions and histories, including existing cocktails whose imported recipes have since been curated. They preserve nonblank text and other locales. Source fields are populated only when the entire source group is blank, so an admin's citations are never mixed with seeded citations. Dates describe source publication, not the cocktail's invention; unknown dates remain empty.

Imported recipes belong to the public `@shakestir` account, while retaining TheCocktailDB attribution. Every recipe requires an author; all authors follow the same recipe rules. Re-running seeds preserves existing imports and recipes reassigned to other users. The seed account receives a random password and does not receive administrator privileges.
