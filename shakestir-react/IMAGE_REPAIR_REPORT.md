# Seed image repair — Snowfall Sidecar and demo coverage

## Root cause and affected scope

The user reported “Snowfall Sidebar”; the actual recipe is Snowfall Sidecar, ID 33. Read-only inspection of the recreated development database found all five demo recipes had ActiveStorage attachment/blob metadata but missing original service files: Midnight Velvet (31), Ruby Masquerade (32), Snowfall Sidecar (33), My Weekend Margarita (34), and After Dinner Experiment (35). Snowfall's image endpoint returned HTTP 404. The 30 imported recipe originals were intact. All relevant local cached assets exist and are valid JPEGs, including the exact `sidecar.jpg`; no external asset or unrelated replacement photograph was needed.

The regression came from the taste backfill's `with_lock` on the same recipe instance holding an image upload inside the outer demo seed transaction. Rails `lock!` reloads that instance; ActiveStorage's reload clears `@attachment_changes`, so the after-commit upload is lost even though attachment metadata was already persisted. Imported recipes were unaffected because their taste backfill ran after their transaction committed. Existing-record seed branches also skipped image repair.

## Fix

- Taste backfills lock a separate persisted recipe instance, preserving the caller's pending attachment upload while still rechecking ownership and NULL-only taste updates under the lock.
- Seed attachments use in-memory IO retained through transaction commit, avoiding deferred upload lifetime issues and leaking file handles.
- Existing demo and system-import branches now fill missing image attachments; matching canonical identities are repaired too. Reassigned imports are excluded.
- If an attachment's original file is missing, restore it in place only when the local cache is byte-identical by checksum and byte size. Existing live uploads remain untouched. Missing custom uploads whose bytes do not match the cache are preserved rather than replaced with a different image. Missing cache assets are logged instead of silently succeeding.
- Recipe JSON supplies `fallback_image_url` only for a readable linked canonical photo. React cards/details try it after a preferred-photo HTTP failure, then show the accessible placeholder if both fail. Raw storage keys remain private and canonical policy checks remain authoritative.

## Development database repair

Restored the five demo original files from the existing exact canonical cache photographs using their existing blob keys and matching checksums. A complete before/after snapshot confirmed all Recipe, Cocktail, ActiveStorage::Blob and ActiveStorage::Attachment database records were unchanged: no photos replaced, new blobs attached, prose rewritten, source credits altered, taste values changed or timestamps modified. No database was dropped/rebuilt and no full seed run was used to modify unrelated catalog content.

Current coverage: **35/35 recipe originals and 30/30 canonical originals present**. Verified real HTTP delivery of all 35 recipe originals and all five demo detail variants: **HTTP 200 with image content**. Private demo recipes were checked using a separate temporary demo login session that was then signed out.

## Verification

- Backend full suite: **239 tests, 2865 assertions, zero failures/errors/skips** against an isolated fixture database.
- Final expanded committed-file regression: **1 test, 3 assertions**, with subprocess checks for all 35 fresh recipes and canonical originals, missing demo original recovery, missing demo/import/canonical attachment recovery, idempotent record counts/keys, curation preservation, intact upload preservation and refusal to replace a nonmatching lost upload.
- The committed-file test creates its own temporary database and ActiveStorage service: ordinary rollback-only fixtures cannot validate after-commit upload delivery.
- Frontend production build and ESLint pass; Vitest covers HTTP failure → permitted canonical image → placeholder and changed-source recovery.
- Browser verification loaded Snowfall's own repaired photo at 700px natural width. Intercepting and failing that request correctly rendered `/api/cocktails/28/image?size=detail` as the canonical fallback, on mobile too, with no page errors.
- Local screenshots: `artifacts/snowfall-repaired-desktop.png` and `artifacts/snowfall-canonical-fallback-mobile.png`.
- `git diff --check` passes. No commits/deployment.

## Changed files for this repair

- `shakestir-rails/db/seeds.rb`
- `shakestir-rails/db/seeds/demo_accounts.rb`
- `shakestir-rails/db/seeds/taste_estimates.rb`
- `shakestir-rails/app/views/recipes/_recipe.json.jbuilder`
- `shakestir-rails/test/models/seed_image_delivery_test.rb`
- `shakestir-rails/test/controllers/recipe_images_controller_test.rb`
- `shakestir-react/src/api.ts`
- `shakestir-react/src/ui.tsx`
- `shakestir-react/src/pages.tsx`
- `shakestir-react/src/photo.test.tsx`
- Seed/Rails README and React DESIGN/ROUTE_PARITY/IMPLEMENTATION_REPORT documentation.
