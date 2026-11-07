# ShakeStir React

A complete React frontend for ShakeStir's established Rails workflows, plus session mixing and optional author-supplied taste discovery. Uses React Router, TanStack Query, TypeScript, native accessible controls, Vitest and Playwright.

## Run locally

Start Rails with the project's mise Ruby. Taste columns are folded into the original recipe migration for fresh databases (the separate taste migration has been removed):

```sh
cd ../shakestir-rails
mise exec -- ruby bin/rails db:migrate
mise exec -- ruby bin/rails server
```

Then in `shakestir-react`:

```sh
npm install
npm run dev
```

Open the printed Vite URL. The development `/api` proxy forwards requests to localhost:3000, including sessions, CSRF, protected images and signed storage redirects. Configure `SHAKESTIR_FRONTEND_URL=http://localhost:5173` in Rails and its job environment when password recovery mail should open React; HTML-requested recovery links retain Rails behavior.

The frontend now implements discovery, exact recipes, canonical cocktail pages, technique/ingredient/tool catalogs, sessions/registration/recovery, private recipe authoring, collections, Favorites, profiles/photos and password-confirmed account deletion. See [route parity and contracts](ROUTE_PARITY.md) and [React design decisions](DESIGN.md).

Taste intensity is optional recipe metadata. The 30 imported recipes and five fictional demo recipes receive explicitly curated, untested editorial expectations from their exact specs; these are not source-provided scores or tasting results. Reruns fill only missing fields of unchanged seed-owned specs and preserve populated values, including zero. Other recipes remain unknown unless their owners supply notes. See [seed taste provenance](../db/seeds/taste/README.md). The mixing queue uses this browser tab's session storage independently of collections, survives reloads and clears on sign out/account deletion. Seed values are explicitly documented editorial predictions; no tasting results are claimed.

## Verification

```sh
npm run build
npm run lint
npm test
# Requires seeded Rails :3000 and Vite :5173; creates and cleans up its own QA account.
npm run test:e2e
```

Browser tests use an installed Playwright Chromium browser. If absent, run `npx playwright install chromium`. Screenshots go to ignored `artifacts/`; failure details go to ignored `test-results/`. Tests cover discovery/history/filtering/pagination/failure retry, real taste query contracts, queue identity/prose persistence, desktop/mobile navigation, full authenticated authoring/collection/profile/photo/account flows. Rails' own test suite covers policies, private content, CSRF and deletion rollback, plus new nested authoring/taste/mail integration tests.

## Deployment contract

Serve React deep links and proxy `/api/*` to Rails with the prefix removed. Forward session cookies, the real public Host/Origin and CSRF headers; route protected record images and their signed ActiveStorage disk redirects through the same origin. Vite's development proxy is not part of a production build or `vite preview`. Use backend mail/job infrastructure for password delivery and photo purge jobs.

Optional build variables: `VITE_API_BASE_URL` (default `/api`) and `VITE_BACKEND_URL` (default `http://localhost:3000`, used to map generated media URLs into the API proxy). Set these consistently with Rails URL generation. For a different production topology, provide the corresponding same-origin media/redirect rewrite in your reverse proxy; do not disable CSRF.

The hero photograph is the repository's cached TheCocktailDB Negroni image; other photography is live record content. Google Fonts has local system fallbacks.
