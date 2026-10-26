<!-- neonize-playbook-stub: v1 -->
# NEONize playbook: pointer for My Little Inverts

The NEON suite playbook has one home, read by Claude Code and Codex alike:
https://github.com/tgilbert14/NEON-Driver-Cascade/blob/master/docs/neonize-playbook.md
(side-by-side clone: `../NEON-Driver-Cascade/docs/neonize-playbook.md`). Read it before
suite work. Fold every suite rule, pattern or gotcha into that file, never into this one.
Anything here beyond this pointer and the app facts below is a stale fork: report it.

## This app

- Repo `NEON-My-Little-Inverts` · watched branch `main` · product `DP1.20120.001`
- Rung specialist: `aquatics`
- Refresh: `refresh-data.yml` (first-week cadence) rebuilds derived files from the committed 34-site bundle (the full NEON download is manual only) and publishes validated bytes only to the fixed review branch `automation/invert-data-refresh`, never `main`; a person's merge to `main` is the deploy.
- Local authority files: `AGENTS.md` (scientific, source and release boundaries, checks), `docs/SCIENCE-CONTRACT.md` (opportunity ledger, grain, estimands), `docs/BUILD-TEST-HANDOFF.md` (commands, evidence, session log), `docs/EXPERT-REVIEW.md` (product-expert review), `docs/DRIVER-KNOWLEDGE-PACKAGE.md` (Driver disposition and reusable lessons).

## App-specific rules

- Default demo and startup site is **SYCA** (Sycamore Creek, Arizona; `DEMO_META` in `global.R`): this is an aquatic product and SRER has no aquatic sampling.
- Every root `docs/*.md` except `docs/BUILD-TEST-HANDOFF.md`, this file included, is bound into the Pages release identity by `scripts/write_release_identity.R`: any edit needs identity regeneration in the clean validator and a new exact candidate.
- The explorer answers "what sampling and processing happened?" before it shows taxon composition.

## Owner-settled house rules (both tools)

- Default demo, startup and picker pre-selection site: **SRER** (then JORN, SJER, MOAB, ONAQ) unless this app documents a reason.
- Copy voice on covers, share cards and in-app copy: plain words a non-expert follows; say what NEON is; no em dashes; no sales pitch (price, access, ease); no hype adjectives; no sincerity labels ("honest", "real data"); never state what the reader can already see.
- No visible "illustration" badge on poster art; the art's status lives in alt text and the image provenance record.

Cold boot: also grep the fleet's `.claude/agents/LESSONS.md` in TG-Data-Apps (Codex: the
`dev-teams` mirror) for your role name: `grep -E '^- \[[0-9-]*\] [a-z0-9+-]*<role>[ +]'`.
