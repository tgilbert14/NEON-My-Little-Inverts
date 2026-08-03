# My Little Inverts — Build/Test Handoff

## 2026-08-03 — Scheduled-refresh repair

Start status: production `main` was healthy at `b370274`, with 34 committed site bundles. The 2026-08-02 scheduled refresh fetched and rebuilt data, then failed while generating `manifest.json` because the refresh environment omitted `cpp11`. The same workflow mistakenly selected the heavy fetch on schedules, tolerated a 28-site floor, rebased with `|| true`, and pushed data directly to `main`.

End status: code-only repair prepared; no bundle or manifest bytes were regenerated or staged.

The committed manifest currently carries nine stale app/data checksums from earlier source changes. That known-good baseline is left untouched here; PR validation regenerates the manifest ephemerally, and the first post-merge refresh will propose the corrected bytes through review.

- Pinned the workflow to Ubuntu 22.04, R 4.5.2, and the 2026-07-15 Posit Package Manager snapshot; added `cpp11` to the validator/runtime closure. Manifest regeneration records that same dated repository rather than moving `latest`.
- Made the NEON fetch manual-only when `workflow_dispatch` explicitly sets `skip_download=false`. Scheduled runs reuse committed site bundles.
- Replaced direct-main publication with producer artifact → clean independent validator → restricted review-branch publisher. Pull requests run the same validator against their exact head. The publisher rejects stale bases, requires a direct-child candidate commit, uses force-with-lease, verifies the exact remote SHA and any exact head/base PR identity, and otherwise leaves a reviewer-authenticated compare link. It never creates or approves a PR.
- Added `scripts/verify_refresh_candidate.R`: base R + `jsonlite` enforce the exact 34-site roster, non-shrink against the committed roster, bundle/index structure, deterministic source stamp, canonical SYCA demo, manifest inventory, and every manifest MD5.
- Replaced `Sys.Date()` in the search index with the maximum ISO date from committed `meta$built` bundle receipts. Scientific estimators and per-site bundle construction are unchanged.

Before merging, run the code-only workflow on the proposed head, review its exact-head checks, open the generated compare link as a repository reviewer, and merge only after the PR checks are green.
