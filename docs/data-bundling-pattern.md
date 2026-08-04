# My Little Inverts — immutable bundle pattern

This app treats committed `.rds` files as a read-only, content-addressed release.
The older “skip existing files, fall back to a live API, then push refreshed data”
recipe is retired. It could mix source vintages, hide failed sites, bypass review,
and make the running app scientifically unreproducible.

## Release shape

The exact derived family is:

```text
data/source_receipt.json
data/release_contract.rds
data/sites/<34 canonical sites>.rds
data/site_index.rds
data/cross_site.rds
data/search_index.rds
data-sample/demo.rds
manifest.json
release/production-identity.json
docs/release.json
```

Each site file contains one schema-`2.1.0` object with:

```text
opportunities  event_strata  taxon_strata  site_summary
meta  metric_contract  qc  provenance
```

The app loads these files only. A missing, malformed, legacy, or identity-mismatched
bundle fails closed; runtime never queries NEON.

## Why one file per site

- Site selection loads only the relevant observations.
- Native R classes and evidence fields survive without CSV type inference.
- `xz` compression keeps the deploy family compact.
- Each site has an independent SHA-256 in the release contract.
- The validator can stream one full site at a time and hold memory use constant.

The release contract still binds all 34 files as one family. A single-site edit
is not an independent release and cannot be combined with 33 files from another
source receipt.

## Authoritative build flow

### 1. Fetch once, manually

`scripts/fetch_inv_all.R` requests exact `RELEASE-2026`, basic package, all sites
and time, provisional disabled. It writes outside the repository:

```text
DP1.20120.001_all.rds
DP1.20120.001_fetch_evidence.json
DP1.20120.001_source_receipt.json   # only after source-contract success
```

The raw RDS is immutable. Fetch evidence is retained even if validation fails,
but it explicitly forbids publication until the authoritative receipt exists.

### 2. Produce from the receipt-bound raw artifact

`scripts/build_inv_data.R` removes the entire prior generated family in a scoped
workspace and rebuilds all 34 sites from one source. It delegates science and
serialization to `scripts/inv_producer.R`; no site is resumed from an older run.

The producer writes primitive evidence and derived summaries together, creates
the source/release contract, and reports exact reconciliation totals.

### 3. Validate from a clean checkout

The validator receives only the allowlisted producer archive and raw
source/receipt artifact. It then:

- checks archive membership before extraction;
- reruns source-to-release reconciliation against the raw bytes;
- verifies every site schema, metric contract, QC contract, and bundle hash;
- rebuilds support indexes and the canonical demo;
- regenerates and independently checks the Connect manifest;
- writes one identity across runtime, data, poster, Pages, and manifest; and
- repeats the final release verifier.

The validated archive, not the producer workspace, is publication input.

### 4. Publish a review branch, never production

The publisher stages only the generated allowlist, requires the candidate to be
a direct child of the reviewed source head, and uses force-with-lease on the fixed
review branch. It never pushes `main` or authenticates its own PR.

A human-reviewed, literal-head-green candidate may merge to `main`. Connect
Cloud watches `main`; GitHub Pages deploys the matching poster. Post-deploy checks
must byte-compare the served Pages cover/art/social image, render the cover at
desktop and 390/320 px seams, prove Connect exposes the exact release identity,
and complete a live Shiny round trip without browser or same-origin resource
errors.

## Determinism and memory rules

- Sort every source projection and derived table with explicit stable keys.
- Never use wall-clock time, locale-dependent formatting, or filesystem order in
  release bytes.
- Do not modify source tables by reference. Strip only the documented volatile
  `data.table` self-reference during canonical materialization.
- Rebuild twice from the same raw authority and compare all release-family bytes.
- Stream bundle verification and assert that at most one fully loaded site bundle
  is retained.
- Keep derived `site_index`, `cross_site`, and `search_index` support-only; they
  cannot introduce a biological metric absent from the site family.

## Manifest discipline

`manifest.json` is part of the release identity. Regenerate it only in the clean
validator under R 4.5.2 and the pinned 2026-07-15 package lane. Ordinary packages
must resolve to that dated RSPM lane; exact allowlisted URL packages retain their
reviewed source URLs. Moving repositories, unpinned remotes, validator clocks,
extra runtime paths, or an MD5 mismatch fail publication.

Do not run `rsconnect::writeManifest()` casually in a docs-only or UI-only
working tree. A new manifest claims a new deploy family and requires the full
release workflow.

## Safe maintenance checklist

1. Decide whether the change affects source, science, serialization, runtime, or
   docs only.
2. For source/science/data changes, run all offline contract tests and an exact
   raw replay in a disposable checkout.
3. Dispatch the manual full fetch only from the immutable reviewed head.
4. Require producer, clean validator, deterministic replay, and restricted
   publisher success.
5. Review the candidate allowlist and direct-parent relation.
6. Merge only the exact checked head.
7. Verify exact Pages bytes and responsive renders, Connect identity/resources,
   and a live Shiny round trip.
8. Record immutable evidence in the handoff and Driver package.

If any boundary is uncertain, retain the evidence and stop before publication.
