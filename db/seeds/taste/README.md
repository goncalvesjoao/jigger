# Editorial taste expectations

`recipe_estimates.json` is ShakeStir's explicit recipe-level editorial mapping: 30 cached TheCocktailDB preparations and 5 fictional demo-account preparations. Each entry has a rationale tied to its actual ingredient quantities and a SHA-256 fingerprint of the ordered ingredient identities/submitted wording and original ordered preparation bodies. Structured quantity/unit, optionality, role and preparation notes also participate in the fingerprint. Recipe source credits and prose remain unchanged. Demo entries run only in development/test, as before.

These are **untested editorial sensory expectations**, not TheCocktailDB-provided values, measured chemistry, tasting-panel results or author tasting claims. Source verification and sensory prediction are separate. The 0–5 intensity vocabulary is: none, very low, low, moderate, high, very high. NULL remains unknown; 0 is a deliberate absence expectation, not missing data. Fruit ripeness, citrus yield, liqueur sugar/proof, unspecified syrup concentration, serving temperature, ice and dilution can shift the perceived balance. Treat adjacent levels as rough discovery guidance, not calibrated precision.

The editor evaluated each checked-in spec, not its canonical name. For example:

- Negroni's full ounce of Campari predicts dominant bitterness, whereas French Negroni has Lillet and vermouth without Campari and receives a much lower bitterness expectation.
- The cached Espresso Martini and both coffee-named demo specs do **not** list fresh espresso; their modest bitterness comes only from Kahlua, without inventing an espresso dose.
- The cached Pina Colada uses coconut milk, not sweetened cream of coconut; it receives a lower sweetness expectation than Whitecap Margarita with a quarter cup cream of coconut.
- Banana Strawberry Shake Daiquiri contains fruit and apple juice without a spirit; the mapping follows that exact fruit drink, without changing the recipe or inferring alcohol from its name.

## Safe reruns

The importer fills only NULL taste fields for the system account and the two known fictional demo accounts, with exact source identity and exact fingerprint matches. Existing zeroes and other populated values remain untouched, including partial author curation. Reassigned recipes, changed ingredients/quantities/steps, changed source credit, unrelated source URLs and unmatched specs are not backfilled. Matching is intentionally conservative; if the seed recipe spec changes, review its rationale/values and regenerate the explicit fingerprint before expecting a backfill. No blanket defaults, name-based inference or random scores run during seeding.

The preexisting importer still preserves all existing recipe content and does not duplicate imported source URLs. The small taste-only backfill runs before its existing-record skip. Demo lookups remain scoped to each demo owner; reassigned original records are untouched. Taste backfills run under a recipe row lock and do not change publication timestamps or modification dates.
