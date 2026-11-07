# Rails → React parity and JSON map

Reviewed `PRODUCT.md`, Rails routes, every controller, JSON builders, user-facing view templates and existing tests. React uses the established Rails session cookie and CSRF token. Mutations remain server-authorized; there is no client-only permission substitute.

| Rails route / controller / HTML views | React page | Read and mutation contracts |
|---|---|---|
| `/`, `/recipes` · Recipes#index · index/_recipe/_personal_card/_requirements/shared search | Explore | `GET /recipes.json`, paginated `{data,metadata}`; q, ingredient/utensil IDs + include/only modes, optional taste filters |
| `/recipes/:id` · Recipes#show · show/_details/_techniques/_star | Exact recipe with author, original requirements/steps, techniques, canonical sidebar, stars, collection picker and mixing action | `GET /recipes/:id.json`; top-level detail + `can_edit`, `can_delete`, saved IDs |
| `/recipes/new`, `/recipes/:id/edit` · Recipes#new/edit · new/edit/_form | Complete authoring: ingredient identities/exact wording, optional quantity/unit/note/role, tools, ordered original steps, techniques, image, sources, taste, visibility/status | `POST /recipes.json`, `PATCH /recipes/:id.json`, multipart `recipe[...]`; additive nested attributes; `DELETE /recipes/:id.json` |
| `/my/recipes` · Account#recipes · recipes | Private notebook with name/status filters and pagination | `GET /my/recipes.json`, counts + pagination |
| `/cocktails` · Cocktails#index · index/_cocktail | Canonical catalog/search/pagination | `GET /cocktails.json` |
| `/cocktails/:id` · Cocktails#show · show/_hero/_background/_recipes/_section_nav | Canonical description, history, source and eligible exact recipe links; context also appears in recipe sidebar | `GET /cocktails/:id.json` |
| `/techniques`, `/techniques/:slug` · Techniques#index/show · show/_content | Catalog and standalone guide, plus native modal from preparation | `GET /techniques.json`, `GET /techniques/:slug.json` |
| `/ingredients`, `/utensils` · Ingredients/Utensils#index (JSON-only Rails catalogs) | Searchable illustrated catalogs linking to real recipe filters | `GET /ingredients.json`, `/utensils.json`; additive description/image fields |
| `/session/new` · Sessions#new · new | Sign in | `POST /session.json` email_address/password; `GET /session.json` returns user or null and CSRF; `DELETE /session.json` signs out |
| `/registration/new` · Registrations#new · new | Registration | `POST /registration.json`, nested user email/password/confirmation |
| `/passwords/new`, `/passwords/:token/edit` · Passwords#new/edit · new/edit | Password recovery and reset | `POST /passwords.json`; `GET /passwords/:token/edit.json` token validity; `PATCH /passwords/:token.json` password/confirmation; reset rotates CSRF and invalidates sessions |
| `/my/collections`, `/collections` · Collections#index · index/_card/_artwork | Private collection library | `GET /my/collections.json` |
| `/my/lists` · Rails redirect | Redirect to My collections | Legacy destination retained |
| `/collections/new`, `/collections/:id/edit` · Collections#new/edit · new/edit/_form | Create/edit name/visibility, guarded delete | `POST /collections.json`, `PATCH /collections/:id.json`, `DELETE /collections/:id.json` |
| `/collections/:id` · Collections#show · show/_picker | Public/owned collection with exact recipe links, owner removal | `GET /collections/:id.json`, wrapped `{data}`; server-readable recipes only |
| `/collection_recipes`, `/collections/:id/collection_recipes` · CollectionRecipes#create/destroy | Recipe save picker and collection removal | `POST /collections/:id/collection_recipes.json` recipe_id; `DELETE /collections/:id/collection_recipes/:recipe_id.json`; top-level create also remains supported by Rails |
| `/recipes/:id/star` · RecipeStars#create/destroy | Image-overlay star toggles / public totals | POST/DELETE `.json`; existing private system Favorites membership and cached count; no new star storage |
| `/profiles/:id`, `/my/profile` · Profiles#show · show | Public biography, photo/avatar, eligible public recipes and collections (also for owner) | `GET /profiles/:id.json`, `/my/profile.json`; email excluded |
| `/my/profile/edit` · Profiles#edit/update · edit | Handle/name/bio, optional photo upload/replace/remove | `PATCH /my/profile.json`, multipart `user[...]` |
| `/my/account` · Account#show/destroy · show | Private email/account identity and password-confirmed permanent deletion | GET/DELETE `/my/account.json`; password required; transactional backend cascade unchanged |
| Recipe/Cocktail/Ingredient/Utensil/ProfileImages#show; PhotoDelivery; ActiveStorage disk | Original record photography, also on private owner pages | Backend image URLs pass through same-origin API proxy and signed disk redirects; existing permission/exclusive attachment checks retained |
| Errors#not_found; ApplicationController JSON rescue handlers | Retry, loading, empty, permission and 404 states | Structured `{errors:{field:[messages]}}` 400/401/403/404/422/429; retry for reads; backend rate limits unchanged |
| `/mixing` (new React-only page) | Session mixing queue with readable step controls | sessionStorage only; no collection mutation or invented backend queue |

Assets, health `/up`, mailer templates, layouts and commented-out PWA routes are not independent React content pages. Rails resource declarations include conventional unimplemented actions (e.g. session edit/password index); React implements the established user-facing workflows, not new behavior for nonexistent controller actions.

## Permission invariants

- Discovery and profiles use eligible published public recipes, including when signed in as owner. Private/draft content lives in My recipes; backend policies still decide every read/write.
- Favorites keeps its identity after rename, stays private and cannot be deleted; controls follow JSON permission flags and backend guards remain authoritative.
- Only owners edit/delete recipes and collections; account email is owner-only. Original author attribution links to public profiles.
- Recipe photo fallback is backend-selected recipe → readable canonical cocktail. Exact prose is neither parsed nor translated.
- Nested editing resolves child IDs through the owner's recipe association. A foreign child ID fails and changes roll back. Published recipes cannot lose their final ingredient or preparation step through nested deletion.

## Genuine operational requirements / boundaries

Taste columns and 0–5 constraints now live in the original CreateRecipes migration; schema version is the newest remaining migration, 20261106000000. The separate taste migration has been removed for the user-authorized fresh database rebuild; no existing developer database was dropped. Seeds supply documented, untested editorial expectations for 30 imported and five fictional demo preparations, not source-provided or tasted scores. Only NULL fields on unchanged seed-owned specs are backfilled, preserving zeroes and curation. Catalog creation and technique maintenance remain trusted backend/seed operations, as in Rails; React consumes the catalog rather than offering unauthorized catalog editors. Availability matching compares identities only, not amounts or substitutions. Alcoholic/non-alcoholic discovery and automated step mention extraction remain product direction outside the confirmed taste/queue scope.

Password email delivery still needs the Rails mailer/job infrastructure. Set `SHAKESTIR_FRONTEND_URL=http://localhost:5173` (or the production React public origin) in the Rails/job environment to send JSON-requested recovery emails to React `/passwords/:token/edit`. HTML-requested emails retain the Rails URL; without this optional setting, JSON emails also fall back to Rails. A production reverse proxy must route JSON `.json` endpoints/API requests and image/signed disk paths to Rails while serving React deep links. Do not disable CSRF or expose Vite as production hosting.

Frontend development uses `/api` → Rails at localhost:3000. The Vite proxy rewrites only its own incoming browser origin to the Rails target and forwards cookies/CSRF, and rewrites Rails photo redirects back through `/api`. Foreign origins are not rewritten. Production should use a same-origin proxy and preserve the actual public Origin/Host to Rails. Optional `VITE_API_BASE_URL` and `VITE_BACKEND_URL` must agree with backend URL generation if deployment uses a different arrangement.

Photo delivery now also exposes `fallback_image_url` for a policy-readable canonical image. React cards/details try this protected URL after a failed preferred image request and display the accessible placeholder only after available sources fail. Seed recovery checks original storage bytes and exact cache checksums, rather than treating attachment metadata alone as proof that an image exists.
