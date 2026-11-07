# ShakeStir React — the bar notebook

Scope: `shakestir-react` only. Rails' existing design documentation and HTML remain independent.

## Product and audience

Home enthusiasts come first, with full creator and professional bartender workflows retained. Discovery opens an exact authored preparation; a canonical cocktail is background knowledge, never a substitute recipe. During mixing, instructions and relevant requirements take priority over story content. No ads, invented popularity claims, translated prose, or unlabelled inferred taste values.

## Verified skill research

Applied `/Users/goncalvesjoao/.agents/skills/ui-ux-pro-max/SKILL.md` on 2026-11-07.

- `search.py "cocktail recipes warm editorial" --design-system -p "ShakeStir React"`: inspected the top identity, Minimalism & Swiss Style. Functional grid, spacious controls, low-cost effects, contrast/focus/reduced-motion guidance fit this web product. Its enterprise-oriented font/pink palette and conversion funnel were not adopted; the user explicitly chose warm editorial direction.
- Narrower `"recipe editorial photography" --design-system`: top identity Motion-Driven / Scroll-Triggered Storytelling was off-topic for active drink preparation. No verified complete editorial recipe preset was found. This output is not persisted as a prescribed design system; the visual direction below is project-specific design judgment implementing the user's explicit direction.
- `"forms routing async accessibility" --stack react`: verified React categories Concurrency, ErrorHandling and Forms. Controlled input state and caught asynchronous errors apply; task mutations use React Query invalidation to keep canonical server state current.
- `"error summary validation" --domain ux`: verified Forms / Accessibility, Focusable Error Summary. Failed submissions retain field values, announce and focus an error summary, and provide links to matching field controls. HTML validation supplies immediate required/type feedback.

## Visual system

- Ivory `#f7f5ed`: background. Deep botanical ink `#202d28`: primary text and actions. Paper `#fffef8`: form surfaces. Citrus `#d9e881`: selected and saved accents. Muted `#5e665e`: secondary text. Danger `#9b302c`: destructive actions.
- Playfair Display headings and italic editorial emphasis; DM Sans controls/body. Local Georgia and sans-serif fallbacks preserve legibility if Google Fonts cannot load.
- Expressive headlines, a distinctive arched photograph, generous spacing, fine rules and quiet 6–8px surface corners. Recipe photography drives cards; missing images have an explicit typographic fallback.
- Three-column discovery on desktop, two columns on phone; catalogs collapse to one. Recipe preparation uses a readable central column, requirements on the left and canonical context/save controls on the right; all stack on phone.
- Native form controls, visible keyboard focus, skip link, route focus, modal technique guides, reduced-motion support. Buttons are at least 44px; mixing navigation is 64px.
- No animation-dependent information, floating decorative overlays, or hover-only actions.

## Session mixing

`sessionStorage['shakestir-mixing']` is separate from backend collections. Each exact recipe is added once and snapshots its original preparation and requirements. Current step and completed status survive reloads in that tab. Users can switch drinks, go backward/forward, finish and remove entries. The session queue is available signed out; it is device/tab-local and does not sync. A queued snapshot does not silently change when an author edits a recipe; remove/re-add to refresh it. Do not queue private recipes on a shared device; signing out clears the queue.

## Taste discovery

Optional author-provided `sweetness`, `sourness`, `bitterness`: integer 0 (none), 1 (very low), 2 (low), 3 (moderate), 4 (high), 5 (very high). SQL NULL explicitly means not assessed, not zero. These are subjective intensity notes, not ratings or calculated scores. Ordinary recipes remain unknown until their owner supplies values. The 30 imported and five fictional demo seed preparations now have explicit recipe-specific, untested editorial expectations documented in `../db/seeds/taste/README.md`; these are not TheCocktailDB scores or tasting results. Seed backfills require unchanged exact specs and seed ownership, fill only NULL fields, and preserve existing zeroes and other curation. Recipe prose and source credits remain unchanged. Discovery combines exact selected intensities (AND across selected dimensions), or unknown, with existing eligibility/name/availability filters. Owners edit taste alongside their preparation. Scales are documented here as a first product vocabulary and can evolve through explicit migrations.

## Photography

Hero asset `src/assets/hero-cocktail.jpg` copies the repository's cached TheCocktailDB Negroni image. Recipe/catalog/profile photography remains backend content, preserving source credits and permissions. No external stock photograph substitutes for a recipe's identity.

Image failures preserve layout and meaning: recipe cards/details try the backend-authorized canonical photo after a failed preferred photo, then show the typographic placeholder if both fail. Cached canonical photographs used by fictional demo variations are illustrative photographs of that drink family, not new photographs claimed to document the demo spec's exact garnish.
