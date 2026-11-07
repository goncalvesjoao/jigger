# Technique catalog

17 techniques with original English descriptions, instructions and beginner tips. `Technique` uses a stable unique slug and direct content fields; name, description and instructions are required. No image is required. `RecipeTechnique` connects any number of techniques to a recipe, with a unique database constraint on each pair. Deleting an assigned technique is restricted; deleting a recipe removes its links.

`bin/rails db:seed` loads the catalog offline. To seed it alone, run from `shakestir-rails/`:

```sh
mise exec ruby@4.0.9 -- ruby bin/rails runner 'require Rails.root.join("db/seeds/techniques"); TechniquesSeeder.seed!'
```

Repeat runs match by slug and fill missing fields without overwriting curation. Keep slugs stable. Recipe mappings were reviewed against the checked-in TheCocktailDB preparation text. They apply only to the matching ShakeStir-owned import with unchanged English instructions and no technique links. Ambiguous preparations are omitted. No general prose extraction is performed. Existing assignments and user-owned recipes are preserved. Removing every assignment from an unchanged system import permits its seed mapping to be added again on a later run.

Authors select techniques in the recipe editor. Recipe pages show only their assigned techniques below preparation; each link opens beginner help in a native dialog and falls back to a standalone public technique page without JavaScript.

The copy is original practical guidance, checked against [Difford's technique directory](https://www.diffordsguide.com/cocktails/how-to-make), its [rolling guide](https://www.diffordsguide.com/g/1150/how-to-make-cocktails/roll-or-tumble), and the [Oxford Companion entry for dry shaking](https://www.spiritsanddistilling.com/dictionary/acref-9780199311132-e-893). Shake variations are distinguished by ice quantity and sequence; foaming steps are not automatically assigned just because a drink is called a sour.
