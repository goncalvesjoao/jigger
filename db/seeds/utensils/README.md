# Utensil catalog

29 English entries cover the checked-in 30 TheCocktailDB recipes and five demo recipes, plus a small essential bar kit. Existing schema categories are retained: preparation and ice tools use `other`. Capacities remain unset because they vary by model.

## Selection rationale

- Shaking and straining: Boston and cobbler shakers are common alternatives for Margaritas, Daiquiris, Sidecars and Espresso Martinis. The Hawthorne strainer serves the Boston shaker and mixing glass; the fine-mesh strainer supports the demo recipes' explicit double strains. A separate julep strainer and third shaker style are unnecessary here.
- Stirring and muddling: mixing glass, bar spoon and muddler cover Manhattan, Negroni, Old Fashioned, Mojito and fruit variations.
- Blending: the blender is required by the frozen Daiquiris, Whitecap Margarita, Mango Mojito and Pina Colada. A spindle drink mixer is not a replacement for these preparations.
- Preparation and essentials: jigger, measuring cup and measuring spoons cover measures, including cups of crushed ice and teaspoons of sugar. Citrus press, Y-peeler, paring knife and cutting board cover juice, twists, wheels and wedges. Cocktail pick, ice scoop, large ice mold and bottle opener provide basic garnish, ice and bottled-mixer service. Lewis bag and mallet provide a manual crushed/cracked-ice option for Mojitos and frozen drinks; they are not required if suitable ice is already available.
- Serving vessels: rocks, highball, Collins, coupe, martini, Margarita and flute glasses plus the lined copper mug cover current serving formats. Coupe and martini glasses are alternatives for generic “cocktail glass” instructions. Frozen Daiquiri explicitly uses a flute. The mug follows Moscow Mule's glass metadata, while its prose permits a highball. Jar-based preparations can use the retained shaker and highball/Collins vessels.

Pruned specialist equipment includes the swizzle stick, filter bag, fine grater, garnish tweezers, ice pick, spindle mixer, siphons, smoking gun and absinthe spoon. Redundant prep/service accessories and glassware for drinks outside the current recipes are also omitted. Salt and sugar rims can be prepared on a small kitchen plate; bottled soda and original bitters bottles cover the current recipes without dedicated dispensing tools.

This is seed-file pruning. Re-running the Rails seeder preserves existing database utensils and their recipe/step associations; it does not delete entries removed from this catalog.

Run the complete seeds with `mise exec ruby@4.0.9 -- ruby bin/rails db:seed`, or just this catalog with (from `shakestir-rails/`):

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
