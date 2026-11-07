# Utensil catalog

59 English entries cover hand tools, small appliances, preparation and service accessories, and cocktail glassware. This is a broad practical catalog rather than every brand, size or specialist laboratory instrument. Existing schema categories are retained: preparation, ice and dispensing tools use `other`. Capacities are intentionally unset because they vary by model; the jigger description identifies the pictured example.

Run the complete seeds with `mise exec ruby@4.0.9 -- ruby bin/rails db:seed`, or just this catalog with:

```sh
mise exec ruby@4.0.9 -- ruby bin/rails runner 'require Rails.root.join("db/seeds/utensils"); UtensilsSeeder.seed!'
```

The seeder matches normalized names, creates each utensil with its own Active Storage photo, and fills missing descriptions/photos. Existing names, descriptions, categories, capacities and photos are preserved. It preflights all image files before writing. Renaming a seeded name changes its matching identity; keep seed names stable to avoid re-creating renamed records.

## Editorial references

Descriptions are original bartender-oriented summaries. Core equipment selection and terminology were checked against [Difford's basic equipment guide](https://www.diffordsguide.com/g/1150/how-to-make-cocktails/basic-cocktail-equipment) and [basic tools guide](https://www.diffordsguide.com/g/1162/cocktails-made-easy/basic-tools-and-equipment). Specialist items extend the basic kit. Glass capacities and spoon/drop/dash volumes are not treated as universal measures.

## Generated images and prompts

Images are AI-generated catalog illustrations, not manufacturer product photographs. Generated with the built-in image generation tool. Each file is named `images/<slug>.png`. The current PNGs use transparent alpha backgrounds, edited from the original catalog images while preserving their utensils and framing. The per-item subject is preserved in `catalog.json` as `image_subject`.

Original creation prompt template (substitute each item's subject):

> Use case: product-mockup. Asset type: cocktail utensil catalog photo. Subject: {image_subject}. Style: realistic premium studio product photograph, square composition, utensil centered fully visible with generous margins, subtle soft shadow on a plain warm off-white background. Accurate functional construction. No text, labels, logos, watermark, hands, ingredients or unrelated objects. Show only the requested utensil or its components.

The first jigger image used the same style with the subject: “a stainless steel double-sided Japanese cocktail jigger, 30 ml and 60 ml conical cups joined at a narrow waist.”

Clear-glass images received an additional matting instruction to remove the original background visible through their bowls while retaining rims, bases, facets and reflections. The exact final edit prompts and per-file assignments are recorded in [edit_prompts.json](edit_prompts.json).

Transparent-background edit prompt (one built-in edit per original image, with `transparent_background: true`):

> Use case: background-extraction. Edit target: the supplied utensil catalog photograph. Remove only the warm off-white background and the floor/cast shadow, replacing them with genuine transparent alpha. Preserve the identical utensil and every component: same shape, proportions, count, placement, orientation, camera angle, size within the square frame, materials, colors, surface details, highlights and reflections. Do not redesign, redraw, relight, recompose or add anything. Keep edges crisp with natural antialiasing, retain holes and openings as transparent, and preserve the natural translucency of glass or mesh if present. No opaque backdrop, no painted checkerboard, no text or watermark. Output a transparent PNG with the original framing.
