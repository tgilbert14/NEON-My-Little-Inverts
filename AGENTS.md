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
Suite-wide rules live in `NEON-Driver-Cascade/docs/neonize-playbook.md`; the local
`docs/neonize-playbook.md` is a pointer to it.

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

## Validator lanes

Every independent-validator lane reconstructs derived indexes and manifest,
validates the allowlisted producer/committed receipt-and-bundle family, checks
the loaded app, creates the content identity, and repeats the release verifier.
Only the manual full-fetch lane additionally receives immutable raw bytes and
independently replays raw-to-release reconciliation. A producer success is not
sufficient in either lane.

The normal fixture family is offline. A full raw replay is intentionally separate
and must use a scoped temporary checkout so it cannot overwrite reviewed working
tree data.

## Change routing

| Change | Minimum evidence |
| --- | --- |
| `docs/BUILD-TEST-HANDOFF.md` only | Link/placeholder scan and `git diff --check`; its exact path is the sole authored Pages file excluded from release identity |
| Any other root `docs/*.md` | Link/placeholder scan, `git diff --check`, identity regeneration in the clean validator, and an exact candidate; a new raw fetch is not required when source/data are unchanged |
| Poster/CSS/client JS | Cover check at desktop/mobile/reduced motion, client handler tests, release-identity test |
| Shiny UI/server | Loaded-app contract, focused runtime test, browser round trip |
| Science/eligibility | Science-contract version review, adversarial fixture, whole offline contract family, expert-review update |
| Source/fetch | Real-class round trip, source fixtures, exact raw replay, no secret/body logging |
| Bundle/manifest/release | Full producer, clean validator, deterministic second build, exact-head release workflow |

The manifest, production identity and Pages receipt are generated only by the
pinned validator. For a source change on a branch, dispatch **Propose immutable
NEON invert refresh** on that branch with `skip_download=true`; a dispatch off
`main` validates and uploads `invert-refresh-<sha>` but publishes nothing. Commit
exactly the `manifest.json`, `release/production-identity.json` and
`docs/release.json` from that artifact; the pull-request validator then
recomputes them and rejects any byte difference.

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

## Hard stops

Stop rather than publish when any of the following is true:

- source release, citation, artifact hash, schema, classes, or required rows do
  not reconcile;
- a fetch produced evidence but no authoritative source receipt;
- one opportunity lacks a unique status or one practical opportunity lacks a
  unique processing/count outcome;
- count, density, zero, or taxon support cannot be reconstructed from primitive
  evidence;
- the 34-site roster, bundle allowlist, direct-parent relation, or exact reviewed
  candidate is uncertain;
- a build depends on a moving package lane or unpinned nonstandard remote;
- release-family bytes differ on a deterministic replay; or
- Pages and Connect do not expose the exact merge identity.
