# Rails product and design review

Date: 2026-11-06. Scope: all rendered application page families and standalone recovery pages. This review supersedes the earlier page-specific visual findings in `design-qa.md` for the surfaces changed here.

## Outcome

Independent Impeccable finish-review disposition: **ship**. No material fixes remain within the reviewed scope. The review confirmed the implementation against `PRODUCT.md` and `.impeccable/surfaces/jigger-rails.md`; this was a refinement of the existing visual identity, without an approved replacement comp.

Kept Semanticus and the established ivory/olive visual language. Replacing the framework would not itself improve discovery or preparation. Consolidated the cocktail-specific cascade into one shared detail treatment, removing roughly 700 lines of conflicting overrides.

## Findings addressed

| Finding | Result |
| --- | --- |
| Discovery lacked a clear page heading and explanation | Compact task heading, direct availability-search guidance, recoverable no-results state and visible search feedback. |
| Cocktail and recipe pages used different layouts and concealed checklist controls | Shared detail layout, visible native checkboxes, readable instructions, live completion counts and reset controls. |
| Recipe identity, provenance and private/draft state competed with ornamental labels | Factual metadata remains visible; decorative kickers and duplicate decorative titles are removed. |
| Embedded official recipes omitted their own source credits | Recipe-level source credits remain visible alongside cocktail-level provenance. |
| Account forms lacked consistent hierarchy and recovery paths | Consistent form surfaces, direct explanations, submission feedback and links between account flows. |
| Libraries and profiles diverged in scale and surface treatment | Shared heading scale, working surfaces and consistent privacy controls. |
| Catalog administration was visually disconnected and cramped on phones | Jigger colors and typography, usable form controls, stacked phone layouts and horizontally scrollable data regions. |
| Phone filter search consumed excessive vertical space | Explicit search-field height; options receive the flexible scrolling area. Menus fit within the viewport. |
| Default Rails error pages lacked Jigger identity and recovery actions | Self-contained branded 400, 404, 406, 422 and 500 pages with truthful explanations and working home links. |

## Coverage

- Explore and flat recipe discovery; canonical cocktail detail; published recipe detail; private draft detail.
- Personal recipes and their filters, new/edit recipe forms and publication errors.
- Collection index, empty and populated detail, new/edit forms, validation errors, save/remove dialog.
- Owner profile, profile editing, public profile and public collection views with owner controls excluded.
- Sign in, registration, password-reset request and password-update forms.
- Cocktail, ingredient, utensil and recipe catalog administration: index, show, new and edit page families.
- Standalone recovery pages: 400, 404, unsupported browser, 422 and 500.

The main route matrix captured 33 routes at 1440px and 390px: 66 successful checks, no horizontal page overflow, no broken images and no browser JavaScript exceptions. Additional admin show/edit checks covered 320px and 768px as well as desktop and phone widths; public views were also checked at 320px and 768px. Source images and full-page renders were inspected, with the collection dialog recaptured after entrance motion settled.

Interaction checks passed for ingredient text filtering, availability selections, live results, removable filter chips, Escape dismissal, empty-search recovery, ingredient/step completion and reset, reversible collection saves, invalid collection and recipe submissions, and public owner-control exclusion.

Temporary evidence: `.impeccable/review/` at the repository root (ignored screenshots, route metrics and interaction results). Local-only catalog fixtures included a small black test raster to exercise the required utensil-photo field; it is not a shipping asset.

## Validation

- Rails: 171 tests, 2,207 assertions, zero failures or errors.
- Vite: development, test and production builds passed.
- Zeitwerk eager-loading check passed.
- Changed Ruby test files: RuboCop passed. Full-project RuboCop still reports six pre-existing comment-indentation offenses in untouched `config/initializers/content_security_policy.rb`.
- JavaScript syntax checks and `git diff --check` passed.
- Mechanical Impeccable detector: no findings on the main UI. Added standalone error pages passed manual craft-floor review.

## Product limits retained

The public recipe editor does not yet author ingredient or utensil requirements. It now explains that limitation and the draft-saving path; existing requirements are preserved. Building the missing authoring workflow remains separate product work. Session queues, taste discovery, ingredient substitution and prose extraction remain product direction, not advertised shipping features.

Seed photos, exact preparation prose, multilingual content, access rules and source credits are retained. No new shipping raster assets were created.
