# NEON My Little Inverts

An unofficial R/Shiny explorer for NEON’s **Macroinvertebrate collection**
(`DP1.20120.001`): aquatic invertebrates recorded in streams, rivers, and
lake-bottom samples. It is part of the Desert Data Labs NEON series.

The app is field-first. Every non-metabarcoding field row is an opportunity,
including rows where sampling was impractical or later processing did not
produce a quantitative community record. The interface keeps missing, unknown,
and a reported laboratory zero distinct.

## Scientific contract

- The source is the exact public `RELEASE-2026` product with provisional data
  disabled. The fetch produces an immutable raw RDS artifact and SHA-256 source
  receipt before any derived bundle is built.
- `inv_fieldData` is the opportunity ledger. Every canonical `inv_persample`
  child reconciles to one practical field opportunity, while a practical
  opportunity may legitimately lack that child. Taxonomy rows still reconcile
  to their practical field parent. `.DNA` field rows are inventoried separately
  as metabarcoding material.
- `GRAB`, `BRYOZOAN`, and `MACROALGAE` special-ID records remain auditable as
  nonstandard collections but are excluded from the primary quantitative
  strata.
- The quantitative grain is always
  `site × event × aquaticSiteType × habitatType × samplerType`. The app never
  replaces habitat or sampler with a modal label.
- Count eligibility and density eligibility are separate. Density requires a
  usable benthic area; missing area does not erase count or occurrence records.
- Taxon support is zero-filled only across count-valid processed samples in the
  same exact stratum. A processed sample without taxonomy stays unknown.
- Identification rank is retained. “Taxa recorded” can mix ranks and must not be
  interpreted as a species-only total.
- EPT is a descriptive taxonomic grouping. Unknown-order positive counts remain
  in the composition denominator, and order-classification support is displayed
  beside the EPT share.
- Expanded counts and collection density are properties of the sampled record,
  not population estimates. Cross-site views compare effort and record counts
  only; the app does not calculate a condition or quality score.

## Loaded experience

- A national map and by-name picker for the 34 aquatic sites.
- An **Opportunity ledger** that shows every mutually exclusive processing
  status and a status-by-year view. Separate support flags retain overlapping
  conditions such as reported zero plus unavailable benthic area.
- **Event strata** charts that compare events only after water type, habitat,
  and sampler are fixed. Count, composition, and density denominators remain
  visible.
- **Taxon records** inside one exact stratum: sample support, expanded laboratory
  count sum, mixed identification rank, EPT membership, order-classification
  status, and separate count/density denominators.
- A **Network effort** view containing opportunity, event, sample-eligibility,
  processing-status, and mixed-rank record counts—no raw biological ranking.
- **QC + provenance** tables with the complete opportunity ledger, metric
  contract, source receipt, reconciliation counts, and contextual source-quality
  evidence. Source flags are displayed and retained; they are not automatic
  row-exclusion rules.
- CSV exports and a one-page field-first PDF report.
- One content-addressed production identity binds the source receipt/artifact,
  34-bundle hash family, derived indexes, runtime files, Pages poster, and
  canonical Connect manifest. The app exposes that exact ID in its initial HTML;
  Pages publishes a byte-identical minimal receipt at `docs/release.json`.

## Data pipeline

```text
scripts/fetch_inv_all.R
  exact RELEASE-2026 fetch -> raw RDS + evidence; immutable source receipt only
  after validation

scripts/build_inv_data.R
  verified source -> field-first science contract -> 34 site bundles
  + site_index.rds + cross_site.rds + search_index.rds
  + release_contract.rds + source_receipt.json

scripts/build_cross_site.R / scripts/build_search_index.R
  rebuild support-only indexes from exact hashed site bundles; no live fetch

scripts/verify_refresh_candidate.R
  independent candidate, provenance, schema, roster, and scientific-contract gate

scripts/write_release_identity.R
  clean-validator-only Pages + Connect identity, followed by final-manifest verify

scripts/post_deploy_smoke.sh
  wait for both public hosts to expose the exact validated ID; reject error shells

scripts/post_deploy_browser.mjs
  byte-compare the live Pages cover/art/social image, render-check it at
  1280/390/320 px with keyboard focus, then require Connect's exact 34-site
  roster, local art/styles, SYCA bundle, and help-modal server round trip
```

Each site bundle uses schema `2.1.0` and contains:

```text
opportunities  event_strata  taxon_strata  site_summary  meta
metric_contract  qc  provenance
```

The loaded app fails closed on a legacy or malformed bundle. It makes no live
NEON request; all data and provenance are committed release artifacts.

## QC evidence

The refresh preserves contextual fields from all three source layers where
available:

- field: `dataQF`
- per-sample: `dataQF`, `qcSortDate`, `qcSortingEfficacy`,
  `qcIterationCount`, `qcPercentSimilarity`, `qcSortedBy`,
  `qcEnumerationDifference` (PDE), and `qcTaxonomicDifference` (PTD)
- taxonomy: `qcChecked` and `dataQF`

These fields are evidence for review, not an automatic exclusion policy.

## Refresh and deployment

Connect Cloud watches `main`; a reviewed merge is the deployment. The scheduled
workflow rebuilds derived indexes from the committed site family. A fresh NEON
download is manual (`workflow_dispatch` with `skip_download=false`) and must pass
the source, science, candidate, and exact-head review gates before the restricted
publisher can update the review branch. The automation cannot write directly to
`main` or approve its own candidate. Manual fetches preserve one 90-day
raw-plus-evidence artifact even on contract drift; without the authoritative
source receipt it can never enter candidate publication. A bounded, token-safe
authentication preflight retries transport/429/5xx failures and distinguishes
401/403 rejection without printing request headers, response bodies, or secret
material. The pinned `neonUtilities` 4.0.1 fetch then uses a guarded, process-local
`getAPI` compatibility binding with the same two-argument response contract, the
preflight-proven stable user agent and timeout, bounded transport retries, and
automatic restoration when the fetch exits. It also initializes and verifies the
package's exact official API base URL in its process-local namespace, which 4.0.1
otherwise leaves unset for a namespace-only call, and restores the prior field on
exit. A transport failure cannot masquerade as fetched source data.

## Run locally

```r
shiny::runApp(".")
```

Use the locked runtime and dependencies recorded by the release workflow. Data:
NEON Macroinvertebrate collection (`DP1.20120.001`). Not affiliated with NEON,
Battelle, or the NSF. Built by Desert Data Labs in Tucson, Arizona.
