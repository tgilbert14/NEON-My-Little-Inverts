# NEON My Little Inverts

[Live app](https://019ef4fb-c6c4-7ddf-2667-7e1021b2ef10.share.connect.posit.cloud/) ·
[Landing cover](https://tgilbert14.github.io/NEON-My-Little-Inverts/)

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
  processing-status, and mixed-rank record counts, with no raw biological
  ranking.
- **QC + provenance** tables with the complete opportunity ledger, metric
  contract, source receipt, reconciliation counts, and contextual source-quality
  evidence. Each primary processing status is a clickable flag chip (mouse,
  Enter, or Space) that lists its field rows, with a per-status CSV and a QC
  report CSV. Source flags are displayed and retained; they are not automatic
  row-exclusion rules. Event strata where NEON flagged a field sample are drawn
  as diamonds on the strata charts, with the verbatim flag in the hover.
- Pin cards on the Overview and Event strata charts (tap a point to pin it, then
  save the chart with its pins as a PNG), a PNG camera on every chart, CSV
  exports, and a one-page field-first PDF report.
- A site-picker popup with **Explore this site** and **About this site**, one
  browser-history entry per site you open (Back returns to the picker), and a
  footer that names the NEON release, its DOI, and the latest collection date.
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
`qcSortedBy` is NEON's pseudonymous ID for the person who sorted a sample; it
stays in the bundle for the validator but the app's QC table does not show it.

## Refresh and deployment

Connect Cloud watches `main`; a reviewed merge is the deployment. The scheduled
workflow rebuilds derived indexes from the committed site family. A fresh NEON
download is manual (`workflow_dispatch` with `skip_download=false`) and must pass
the source, science, candidate, and exact-head review gates before the restricted
publisher can update the review branch. The automation cannot write directly to
`main` or approve its own candidate. Only a run on `main` can publish to
`automation/invert-data-refresh`; a dispatch from any other branch validates
and uploads its candidate artifact but publishes nothing. When a validated
branch is waiting and no review PR is open, the publisher opens or updates one
issue labelled `data-refresh` so a person sees it.

Every run first asks NEON's public product endpoint whether a newer release
exists and whether the issue log has entries dated after the committed fetch.
A newer release turns the weekly scheduled run red (a warning on other events);
new issue-log entries are warnings in the run summary. Manual fetches preserve one 90-day
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

## Release-bump procedure (RELEASE-2027 and later)

NEON publishes a new release each January. The app stays on its pinned release
until a person moves it; the weekly run goes red when a newer release appears.

1. Change the release tag, DOI and citation object everywhere they are pinned:
   `scripts/inv_source_contract.R` (`INV_RELEASE`, `INV_CITATION_OBJECT`),
   `scripts/fetch_inv_all.R`, `scripts/build_inv_data.R`,
   `scripts/inv_producer.R`, `scripts/inv_science_contract.R`,
   `scripts/inv_release_verifier.R`, `scripts/write_release_identity.R`
   (`RELEASE`, `DOI`, `CITATION_OBJECT`, `PRODUCTION_RELATIONS`),
   `scripts/post_deploy_smoke.sh`, `global.R` (`NEON_RELEASE`, `NEON_DOI`),
   `R/inv_helpers.R`, `scripts/check_loaded_app_contract.R`,
   `.github/workflows/refresh-data.yml`, the cover's footer in
   `docs/index.html`, `AGENTS.md`, this README, and the fixtures in
   `scripts/test_inv_source_contract.R`, `scripts/test_inv_science_contract.R`,
   `scripts/test_post_deploy_smoke.sh` and `scripts/test_release_identity.R`.
2. Dispatch **Propose immutable NEON invert refresh** with `skip_download=false`
   from a branch that carries step 1. Read the source receipt and relation
   counts it reports, update the pinned relations, and re-baseline the frozen
   headline oracle in `scripts/inv_headline_oracles.R` from the new validated
   bundles only after the source, science and verifier gates pass.
3. Update `docs/SCIENCE-CONTRACT.md` and `docs/EXPERT-REVIEW.md` if NEON changed
   a field, a sampling protocol or the issue log in a way that touches the
   estimand, then `docs/DATA-TAKEAWAYS.md` from the receipt-bound release.
   Re-verify that every Insecta row still has an order before keeping the
   "Assigned to an order" note that no unassigned count can be EPT.
4. Open one reviewed PR whose head passes the validator, including the
   exact-identity check. The merge is the deploy; then confirm the post-deploy
   workflow proves the new release identity on Pages and Connect.

## Run locally

```r
shiny::runApp(".")
```

Use the locked runtime and dependencies recorded by the release workflow. The
pin-card PNG export uses html-to-image (MIT), vendored byte for byte from
NEON-Breeding-Birds@67b3b39 into `www/vendor/html-to-image/` with its licence, so
the app loads no remote script. Data: NEON (National Ecological Observatory
Network) Macroinvertebrate collection (`DP1.20120.001`), RELEASE-2026,
[doi:10.48443/hp56-s582](https://doi.org/10.48443/hp56-s582), CC BY 4.0. Not
affiliated with NEON, Battelle, or the NSF. Built by Desert Data Labs in Tucson,
Arizona.
