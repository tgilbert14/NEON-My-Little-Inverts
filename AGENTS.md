# My Little Inverts repository contract

These instructions apply to the entire repository. This app is a released-data
viewer, so scientific meaning, source authority, and deploy identity are part of
the product—not optional documentation.

## Non-negotiable scientific boundaries

- The source is NEON `DP1.20120.001`, exact `RELEASE-2026`, basic package,
  provisional data disabled. A full fetch is manual only.
- `inv_fieldData` is the opportunity population. Retain every non-`.DNA` field
  row, including sampling-impractical and unresolved processing outcomes.
- Keep the comparison grain exactly
  `site × event × aquaticSiteType × habitatType × samplerType`. Never replace a
  missing grain field with a modal or inferred value.
- Keep count, density, composition, and taxonomy availability as separate
  contracts. Missing is unknown, never zero. Zero-fill taxon support only among
  count-valid processed samples inside one exact stratum.
- Preserve identification rank. “Taxa recorded” is mixed-rank and is not species
  richness. EPT summaries are descriptive, not condition or quality scores.
- Keep cross-site products effort-only. Do not add raw biological rankings,
  density rankings, richness rankings, or causal environmental inference.

The complete estimand and edge-case rules are in
`docs/SCIENCE-CONTRACT.md`. Update that file and its adversarial tests together
whenever scientific meaning changes.

## Source and release authority

- A raw fetch is evidence, not publishable authority. Only the immutable raw RDS
  plus a source receipt that passes `scripts/inv_source_contract.R` may enter the
  producer.
- Preserve the raw object classes and nonvolatile attributes. The one sanctioned
  normalization removes only `data.table`'s volatile `.internal.selfref`; do not
  coerce or mutate source tables by reference.
- App runtime is bundle-only and network-free. Do not add a live NEON fallback.
- The release family is exactly 34 `data/sites/<SITE>.rds` files plus the derived
  indexes, demo, source receipt, release contract, manifest, and release identity.
  Treat `data/release_contract.rds`, `data/source_receipt.json`,
  `release/production-identity.json`, and `docs/release.json` as generated
  authority.
- Do not hand-edit or casually regenerate `data/`, `data-sample/`,
  `manifest.json`, or either release receipt. Use the producer → clean independent
  validator → restricted review-branch workflow.
- Identity-bound documentation may retain an already closed ancestor candidate
  and PR as lineage when those facts exist before the current change begins.
  Keep the current change's generated candidate and every later PR, merge,
  Pages, and Connect identifier or status out of identity-bound documentation.
  Record those only in `docs/BUILD-TEST-HANDOFF.md` and the central Driver
  register.
- Connect Cloud watches `main`. A reviewed exact-head merge is the deploy. The
  workflow must never push directly to `main`, create/approve its own PR, or
  publish a candidate whose parent is not the reviewed source head.

## Required checks

For source, science, or producer changes, run the relevant focused test and then
the whole offline contract family:

```sh
Rscript --vanilla scripts/test_inv_source_contract.R
Rscript --vanilla scripts/test_inv_science_contract.R
Rscript --vanilla scripts/test_inv_producer.R
Rscript --vanilla scripts/test_inv_release_verifier.R
Rscript --vanilla scripts/check_loaded_app_contract.R
```

For cover or browser changes, also run:

```sh
npm ci --ignore-scripts --no-audit --no-fund
npm run check:cover
Rscript --vanilla scripts/test_release_identity.R
```

Always run `git diff --check`. A full release is complete only after the exact
candidate, literal-head PR checks, expected-head merge, Pages identity, Connect
identity, and a bidirectional Shiny browser round trip are all recorded in
`docs/BUILD-TEST-HANDOFF.md`.

## Change hygiene

- Preserve unrelated work and useful historical evidence.
- Use explicit names for denominators and grains in code, UI, exports, and docs.
- Update `docs/DATA-TAKEAWAYS.md` only from a receipt-bound verified release.
- Update `docs/EXPERT-REVIEW.md` when an estimator, eligibility rule, source
  reconciliation, or public claim changes.
- Update `docs/DRIVER-KNOWLEDGE-PACKAGE.md` before candidate generation when a
  reusable lesson or ancestor release fact changes; it is identity-bound and may
  not carry post-candidate status. Record later candidate/production status only
  in `docs/BUILD-TEST-HANDOFF.md` and the suite Driver register.
- Do not claim production closure from an HTTP 200 alone. Both public hosts must
  expose the exact release identity, and Connect must complete a real server
  round trip.
