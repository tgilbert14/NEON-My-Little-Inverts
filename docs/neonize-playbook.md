# My Little Inverts — safe product playbook

This is the app-local maintenance guide. The former copy-forward suite playbook
described direct-main refreshes, live fallbacks, old flagship styling, and legacy
deploy paths that are unsafe for this repository. Suite-wide standards belong in
NEON Driver Cascade; this file records only how to preserve this product.

## Product promise

The app opens on a static artistic Living Poster, then moves into an instant
bundle-only Shiny explorer. The loaded experience starts with a national picker
and one site, answers “what sampling and processing happened?” before showing
taxon composition, keeps every denominator visible, and gives users the exact
ledger/QC evidence behind each summary.

Preserve these product qualities:

- one global selected-site state shared by every tab;
- answer-first summaries followed by progressively deeper evidence;
- no animation dependency in the poster or primary flow;
- persistent caveats next to the metric they constrain;
- keyboard-usable controls, visible focus, responsive tables/charts, and
  `prefers-reduced-motion` support;
- theme-independent data palettes and tab-resize dispatch for hidden widgets;
- useful empty states that distinguish unknown, zero, unavailable, and not
  selected; and
- exports/PDF that carry grain, denominator, source identity, and QC context.

## Build in this order

### 1. Define the scientific question

Name the opportunity table, observation children, exact comparison grain, metric
denominators, exclusion/quarantine rules, and claims the data cannot support.
For this app, `docs/SCIENCE-CONTRACT.md` is authoritative.

### 2. Make source authority immutable

Fetch exact `RELEASE-2026` only through the manual workflow. Preserve raw bytes
and nonauthoritative fetch evidence even on drift. Generate the source receipt
only after schema, class, citation, release, timestamp, table, and reconciliation
checks pass. Never derive a candidate from unreceipted bytes.

### 3. Build field-first

Run the producer from the verified raw RDS. It must emit exactly 34 site bundles,
the release contract, source receipt copy, support indexes, and canonical demo.
All joins and flags must be recomputable from primitive evidence.

### 4. Validate in a clean checkout

Every independent-validator lane reconstructs derived indexes and manifest,
validates the allowlisted producer/committed receipt-and-bundle family, checks
the loaded app, creates the content identity, and repeats the release verifier.
Only the manual full-fetch lane additionally receives immutable raw bytes and
independently replays raw-to-release reconciliation. A producer success is not
sufficient in either lane.

### 5. Publish only a review candidate

The restricted publisher may update only `automation/invert-data-refresh`, and
only with a validated direct-child commit of the immutable source head. Review
the exact file inventory and direct-parent relationship, open a human-authored
PR, require literal-head checks, and merge only with expected-head protection.

### 6. Prove both public products

After merge, Pages and Connect must expose the same recomputed release identity.
Connect must also load the exact site family, open the canonical site, and
complete a client/server help-modal round trip. An HTTP 200 or a provider build
badge alone is not closure.

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

## Local contract commands

```sh
Rscript --vanilla scripts/test_inv_source_contract.R
Rscript --vanilla scripts/test_inv_science_contract.R
Rscript --vanilla scripts/test_inv_producer.R
Rscript --vanilla scripts/test_inv_release_verifier.R
Rscript --vanilla scripts/check_loaded_app_contract.R
Rscript --vanilla scripts/test_release_identity.R
npm ci --ignore-scripts --no-audit --no-fund
npm run check:cover
git diff --check
```

The normal fixture family is offline. A full raw replay is intentionally separate
and must use a scoped temporary checkout so it cannot overwrite reviewed working
tree data.

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

## Documentation closeout

Before generating a candidate, update the identity-bound knowledge family:

- `docs/DATA-TAKEAWAYS.md` from the verified release, never a legacy bundle;
- `docs/EXPERT-REVIEW.md` for scientific and edge-case decisions; and
- `docs/DRIVER-KNOWLEDGE-PACKAGE.md` with reusable suite lessons and only facts
  already knowable before that candidate exists.

After the current change's candidate is created, record that candidate and its
later PR, merge, Pages, Connect, and live-round-trip receipts only in
`docs/BUILD-TEST-HANDOFF.md` and the central Driver register. The exact handoff
path is intentionally excluded from the release identity. Changing any other
root `docs/*.md` changes the Pages payload hash and requires a newly generated
identity and exact candidate. Already closed ancestor candidate/PR facts may
remain as lineage when they were knowable before the current change began.

Do not copy this file into another app as its scientific plan. Carry the safety
shape, then derive the other product's opportunity, grain, estimands, and edge
cases from its own source.
