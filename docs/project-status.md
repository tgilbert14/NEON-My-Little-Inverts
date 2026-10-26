# My Little Inverts: project status

Last verified: 2026-10-21 (America/Phoenix), against the NEON suite audit of
2026-10-18 and its finish ledger.

This file is identity-bound (every root `docs/*.md` file is hashed into the
release identity). It records the product's standing state and decisions only.
The current change's candidate, PR, merge, Pages and Connect status belong in
`docs/BUILD-TEST-HANDOFF.md` and the central Driver register.

## Where it stands

- **Product.** NEON Macroinvertebrate collection, `DP1.20120.001`, exact
  `RELEASE-2026`, basic package, provisional data excluded. 34 aquatic sites,
  7,198 field opportunities, records through 2024-11-26.
- **Deploy.** Posit Connect Cloud watches `main`; Pages serves `docs/`. One
  content-addressed release identity binds the data family, runtime files,
  Pages payload and Connect manifest, and the post-deploy workflow proves both
  hosts serve it.
- **Refresh.** Weekly cron with the shared NEON-suite calendar gate (week 1).
  Scheduled runs rebuild derived files from the committed bundles; a full NEON
  fetch is manual (`skip_download=false`). Validated candidates go only to
  `automation/invert-data-refresh`, only from a run on `main`; a person's
  reviewed merge is the deploy. Lineage: the gate and token probe came from the
  suite pipeline sweep (PR #11, merged); the CARTO basemap key path from PR #10
  (merged).
- **Default site.** SYCA (Sycamore Creek, Arizona). The suite default SRER is a
  terrestrial site with no macroinvertebrate sampling, so the Arizona aquatic
  site stands in for it.

## Audit pass 2026-10 (in source)

- **Shell.** Page `<title>` and `lang="en"` (the old `window_title` and
  `fillable` arguments were not `page_fillable()` arguments and landed on
  `<body>`); site-picker popup with Explore this site and About this site, a
  site-facts modal, `keepInView = FALSE`, the popup closed before the splash
  hides, and escaped popup and card markup through one delegated listener;
  Back returns to the picker; an unknown `?site=` code says so; info dots carry
  accessible names; light-theme contrast, 44 px tap targets and a one-row tab
  strip on phones.
- **Suite registry.** All ten explorers, each with its live app and its cover;
  the master app is named NEON Cross-Product Response Atlas everywhere; the
  cover keeps one Atlas route (Living Poster V1).
- **Copy.** No em dashes in visible copy; the cover's "What am I looking at?"
  and the in-app status and loading copy are in plain words; NEON is named in
  full on the cover and in the app.
- **Provenance.** Footer line with the latest collection date, release tag and
  DOI; CC BY 4.0 attribution; a citation line in About; the cover names the
  release and DOI. Every refresh run checks NEON for a newer release (red on the
  weekly run) and for issue-log entries dated after the committed fetch
  (warnings).
- **QC and charts.** Clickable processing-status flags (mouse, Enter, Space)
  with per-status and QC-report CSVs and an all-clear state; a status palette
  keyed by status, so no bar renders black and colours match across charts;
  NEON field flags marked on the strata charts (counted among the samples
  behind each point; "legacyData" shown but not marked); small-sample density
  points greyed; top-24 truncation labelled; "Assigned to an order" replaces
  the misleading "Order classified" label; "taxa recorded" no longer says
  "distinct"; NEON's pseudonymous sorter ID is hidden from the QC table. QC
  tiers follow the aquatics review recorded in `docs/EXPERT-REVIEW.md`.
- **Pin cards.** Overview and Event strata charts pin cards and save as PNG;
  every chart has a PNG camera; html-to-image is vendored, not loaded remotely.
- **Gates.** `check_cover.mjs` now forbids em dashes (it used to require one);
  a frozen headline oracle checks the five hero metrics and raw-row identities
  without the producer's rules; the handler check scans every R and JS file;
  the smoke and browser probes check `<title>`, `lang`, card overflow at 375 px,
  bar fills, tab contrast, the Back button and the basemap tile host.
- **Already in place before this pass** (verified, unchanged): deterministic
  bundles (`scripts/test_inv_producer.R` proves byte-identical repeated
  production and bundle-only rebuilds, and the publisher makes no commit when
  the validated bytes match); the post-deploy smoke proves the exact release
  identity rather than a fixed marker; release tag and DOI carried in every
  bundle and in the identity.

## Deliberately deferred

| Item | Why it waits | Revisit when |
| --- | --- | --- |
| `n_distinct_taxa` beside `n_taxa_recorded`, using an ambiguous-parent rule (a family is not counted when a finer descendant is present in the same unit) | A science-contract addition: aquatics writes the rule, the owner approves the tier, and all 34 bundles must be rebuilt from the raw source. The wording fix shipped now. | The next full fetch or RELEASE-2027 |
| `pct_insect_order_unresolved_estimated_count` in place of the order-classified support line | Same contract path; measured today it would be 0 everywhere, so the relabel carries the meaning in the meantime. | Same |
| Whether a processed sample with no taxonomy rows counts as a reported zero | Changes an eligibility rule; aquatics recommends, the owner decides. Today the flag fires 0 times in 7,198 opportunities and a fixture covers the rule. | Owner decision |
| Season encoding and a January 2026 sampling-window marker on event lines | NEON changed aquatic sampling windows from January 2026, but RELEASE-2026 ends in 2024-11, so no plotted event is affected. | The first release with 2026 events |
| Including provisional data | The app is release-pinned by design. | Owner decision |
| Ten per-sample rows with `dataQF` "AHTEST" | NEON publishes no definition; the rows are shown as retained evidence and never used to exclude a row. | Ask NEON or check the next release's QC notes |
| Keepalive job against the 60-day scheduled-workflow cliff | The suite plan trials it in one repository first. | After the suite trial |
| Branch protection or a ruleset on `main` | A repository setting only the owner applies. | Owner action |
| `CARTO_BASEMAP_KEY` on the Connect content | A dashboard setting only the owner applies; the post-deploy probe warns until it is set. | Owner action |
| Deleting merged remote branches, including the stale `automation/invert-data-refresh` twin of `main` | Branch deletion is the owner's call; the publisher recreates the review branch on the next real change. | Owner action |

## Owner decisions open

- The three science-contract additions in the deferred table.
- Whether to include provisional data.

## How to check

```sh
Rscript --vanilla scripts/test_inv_source_contract.R
Rscript --vanilla scripts/test_inv_science_contract.R
Rscript --vanilla scripts/test_inv_producer.R
Rscript --vanilla scripts/test_inv_release_verifier.R
Rscript --vanilla scripts/check_loaded_app_contract.R
npm ci --ignore-scripts --no-audit --no-fund
npm run check:cover
Rscript --vanilla scripts/test_release_identity.R
git diff --check
```

Suite lint, from the read-only hub:
`node .claude/scripts/neon-suite-lint.mjs --app inverts --worktree`.
