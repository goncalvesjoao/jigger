# Seed data

Shared seed catalogs, images, and source notes live here. Rails seed loaders remain in `shakestir-rails/db/seeds.rb` and `shakestir-rails/db/seeds/` and resolve this directory relative to the repository root.

From `shakestir-rails/`, run `bin/rails db:seed` to load the checked-in data offline.

Recipe-specific [editorial taste expectations](taste/README.md) cover cached imported and fictional demo recipes, with explicit provenance and conservative fill-missing behavior.

Seed photo reruns preserve uploads, fill missing attachments for known system/demo recipes and their matching canonical identities, and restore a missing original file only when the local cache has the exact same checksum and size as its existing blob. Nonmatching lost uploads are not replaced with unrelated pictures. Missing cache assets are logged. Demo photos intentionally use the relevant canonical cached photograph (for example, Snowfall Sidecar uses `thecocktaildb/images/cocktails/sidecar.jpg`); no external replacement asset is needed.

Taste backfills lock a separate recipe instance so they do not clear ActiveStorage's pending uploads before an outer seed transaction commits. The committed-file regression test uses an isolated database and storage service because transactional fixture tests cannot prove after-commit file delivery.
