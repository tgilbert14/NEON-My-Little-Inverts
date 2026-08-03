# My Little Inverts — Build/Test Handoff

## 2026-08-03 — Scheduled-refresh repair

Start status: production `main` was healthy at `b370274`, with 34 committed site bundles. The 2026-08-02 scheduled refresh fetched and rebuilt data, then failed while generating `manifest.json` because the refresh environment omitted `cpp11`. The same workflow mistakenly selected the heavy fetch on schedules, tolerated a 28-site floor, rebased with `|| true`, and pushed data directly to `main`.

End status: code-only repair prepared; no bundle or manifest bytes were regenerated or staged.

The committed manifest currently carries nine stale app/data checksums from earlier source changes. That known-good baseline is left untouched here; PR validation regenerates the manifest ephemerally, and the first post-merge refresh will propose the corrected bytes through review.

- Pinned the workflow to Ubuntu 22.04, R 4.5.2, and the 2026-07-15 Posit Package Manager snapshot; added `cpp11` to the validator/runtime closure. Manifest regeneration replaces residual `cran.rstudio.com` `RemoteRepos` as well as moving CRAN/RSPM `latest`, and the verifier rejects any recurrence.
- Made the NEON fetch manual-only when `workflow_dispatch` explicitly sets `skip_download=false`. Scheduled runs reuse committed site bundles. `NEON_TOKEN` is scoped to that one manual fetch step and is absent from pull-request code.
- Replaced direct-main publication with producer artifact → clean independent validator → restricted review-branch publisher. Pull requests run the same validator against their exact head. The publisher rejects stale bases, requires a direct-child candidate commit, uses force-with-lease, verifies the exact remote SHA and any exact head/base PR identity, and otherwise leaves a reviewer-authenticated compare link. It never creates or approves a PR.
- Added `scripts/verify_refresh_candidate.R`: base R + `jsonlite` enforce the exact 34-site roster; per-site non-shrink for bouts and samples; no loss of early or latest year coverage; bundle/index structure; deterministic source stamp; canonical SYCA demo; exact data inventory; and every manifest MD5.
- Producer, validator, and publisher tarballs now enumerate the 34 site bundles and five derived/release files exactly. Archive members are checked before extraction and the publisher stages only that allowlist, so an extra generated or untracked data path fails closed.
- Replaced `Sys.Date()` in the search index with the maximum ISO date from committed `meta$built` bundle receipts. Scientific estimators and per-site bundle construction are unchanged.

Local evidence: the workflow parses as YAML and all eight embedded run blocks pass `bash -n`; changed R files parse; `git diff --check` passes; a focused 34-site fixture passed the complete verifier at 830 bouts, 6,430 samples, and 9,392 search rows; a deliberate SYCA sample-count shrink and an extra manifest data path were both rejected.

Before merging, run the code-only workflow on the proposed head, review its exact-head checks, open the generated compare link as a repository reviewer, and merge only after the PR checks are green.

## 2026-08-03 · Refresh publisher and manifest provenance repair

- Scheduled refreshes had completed candidate production and independent
  validation but failed while publishing the review branch. PR #3 repaired that
  boundary and merged as `d1af49817e52381b2a519f3c3d68e7c32b175003`.
- Post-repair workflow run `30819110562` passed producer, validator, and restricted
  publisher. It published candidate `39e169fe046bb01d9a16fec83b0b8330fdcd94ec`
  as a direct child of that merge. The three regenerated RDS indexes decode
  identically to `main`; their byte differences are serialization-only.
- Pre-PR semantic review correctly held that candidate. Its regenerated manifest
  retained exact source URLs but exposed the geospatial packages through symbolic
  `Source=URL` / `Repository=RSPM` deployment fields and kept validator wall-clock
  `Built` values. Connect treats the top-level repository as a network location,
  so this was not safe to merge despite green validation.
- This follow-up removes the old version-rewrite escape hatch, requires Plotly
  4.12.0 and the complete eight-package geospatial closure from exact retained
  URLs, validates actual installed versions/origins before canonicalization, gives
  Connect absolute deployment lanes, strips only non-semantic exact-source build
  clocks, and independently rechecks the complete provenance contract.
- No runtime, scientific helper, bundled observation, Pages, Connect, or Driver
  byte is changed by the repair commit. The review candidate must be regenerated
  from this exact branch, compared semantically, and pass exact-head PR checks
  before merge. Candidate `39e169f` is diagnostic evidence only and is superseded.

Next action: publish this focused repair, dispatch the skip-download refresh on its
exact branch, inspect the replacement review candidate, then open and merge the
combined exact-head PR only after all gates pass.

## 2026-08-03 · Ordinary-package manifest alias follow-up

- Restricted refresh `30822032342` proved the producer boundary and stopped
  safely in the clean validator. `rsconnect::writeManifest()` represented
  ordinary CRAN packages with `https://cloud.r-project.org` even though both
  workflow repository controls were pinned to the dated 2026-07-15 RSPM
  snapshot. The publisher was skipped, so no candidate branch or production byte
  changed.
- The manifest writer now accepts that one rsconnect ordinary-CRAN alias only
  when `RSPM` and `RENV_CONFIG_REPOS_OVERRIDE` both equal the exact dated
  snapshot. It still rejects `cran.rstudio.com`, `latest`, non-CRAN sources, and
  nonstandard remotes; exact Plotly and geospatial URL origins remain mandatory.
- Only after those installed-origin checks pass does the writer replace ordinary
  package deployment fields with the dated snapshot. The independent candidate
  verifier still accepts only the final dated-snapshot form, and a new
  post-canonicalization gate rejects any remaining moving repository.

Next action: run the restricted skip-download refresh again from this exact
repair head. Review and merge only its direct-child candidate after semantic
comparison and green literal-head CI.

## 2026-08-03 · Independent ordinary-remote verifier hardening

- A separate adversarial audit proved the writer already rejects ordinary
  package records with `RemoteType=url` or `RemoteType=github`, but the clean
  candidate verifier checked `RemoteRepos` only when `RemoteType=standard`.
  A hand-tampered manifest could therefore pass the verifier if it kept the
  dated top-level CRAN lane while adding an arbitrary URL or GitHub ref.
- The independent verifier now permits only an empty remote type (for
  recommended/base records) or `standard` (with the exact dated
  `RemoteRepos`). URL/GitHub ordinary-package records fail independently of the
  writer. Exact Plotly and geospatial URL records remain separately allowlisted
  and fully pinned.
- Refresh `30824016239` began before this verifier hardening and is evidence for
  the writer alias fix only. Even if green, its candidate is superseded and must
  not be merged; the restricted workflow must rerun on the new exact head.
