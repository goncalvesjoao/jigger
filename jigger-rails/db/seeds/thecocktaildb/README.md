# Local TheCocktailDB seed cache

This directory stores cached JSON responses and default image files used by `db/seeds.rb`.

The seed task intentionally does not call the public API at runtime. It reads only the files in this directory so local and CI runs remain deterministic and do not break when TheCocktailDB changes or its images disappear.

To refresh the cache, run:

`ruby db/seeds/thecocktaildb/build_seed_cache.rb`
