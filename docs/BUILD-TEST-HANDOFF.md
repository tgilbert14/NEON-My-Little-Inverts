# My Little Inverts — build/test handoff

## 2026-08-05 — Cover badge removal source handoff (America/Phoenix)

### Scope and authority

- Clean source baseline: `origin/main` at
  `53991b6f460a97a4abfcee9f62e94cd77c167f89`; local source branch:
  `codex/inverts-remove-visible-art-badge`.
- Removed only the visible editorial-illustration caption from the Pages Living
  Poster and its in-app counterpart. The reviewed descriptive alt text,
  byte-identified local artwork, `docs/IMAGE-PROVENANCE.md`, opportunity/zero
  disclosure, density/EPT limits, and all scientific/data bytes remain unchanged.
- Removed the now-dead caption CSS. Static and post-deploy browser contracts now
  require the Pages/app badges to remain absent while retaining local-art,
  responsive, accessibility, provenance, exact-identity, and scientific-limit
  checks.

### Local evidence and release boundary

- Passed: `npm ci --ignore-scripts --no-audit --no-fund`,
  `npm run check:cover`, `node --check scripts/post_deploy_browser.mjs`,
  `Rscript --vanilla scripts/test_release_identity.R`, and `git diff --check`.
- Diagnostic R 4.5.3 checks also passed 143 source-contract fixtures, 109 science
  fixtures, 43 producer/verifier fixtures, and 58 adversarial release-verifier
  fixtures. The system library lacked `data.table`; the complete diagnostic suite
  was therefore rerun successfully with the existing `msc-r` environment. These
  diagnostics do not replace the pinned release validator.
- The authoritative `manifest.json`, `release/production-identity.json`, and
  `docs/release.json` were deliberately not rewritten on the macOS R 4.5.3 host.
  Repository policy requires their prestamp/write/final/verify sequence in the
  pinned R 4.5.2 / Ubuntu 22.04 validator, so this source handoff is not yet a
  deploy candidate and production remains unchanged.
- Next action: push the exact source commit, manually run **Propose immutable NEON
  invert refresh** on that ref with `skip_download=true`, review the generated
  `automation/invert-data-refresh` candidate, and merge only its green exact
  head. The merge makes Connect republish watched `main`; the
  `Verify My Little Inverts production` workflow must then prove Pages marker
  `inverts-living-poster-v2`, Connect marker
  `my-little-inverts-release-2026-v1`, the exact production identity, byte-exact
  Pages assets, and the live Playwright/Shiny round trip. No push, merge,
  deployment, or live-production claim was made in this local pass.

## 2026-08-04 — Pass-9 governance/tooling release complete

### Scope and authority

- Runtime, source, data-family, and scientific authority remains full-fetch run
  `30885526988` and merge
  `ff23e994e289982c747b91e48c5ff0907c1672d2`, recorded in the next section.
- Governance source `1b059cb04e32c02c171d21a9d47b22cf6c060db2` added the
  app-local governance/knowledge package, cycle-free production identity with
  Pages-payload domain v2, exact responsive/accessibility/live-host verification,
  and the advisory-fixed Playwright `1.55.1` pin.
- Committed-family run `30893786089` used `skip_download=true`: it fetched no raw
  NEON data and made no scientific, source-receipt, release-contract, bundle,
  derived-index, demo, social-art, or runtime-payload change.
- Candidate `ecbb23cd313632727e78896ab4473b600b456b34` is the sole direct
  child of `1b059cb04e32c02c171d21a9d47b22cf6c060db2`. Their delta is exactly
  `docs/release.json`, `manifest.json`, and
  `release/production-identity.json`.

### Validated committed-family candidate

Run `30893786089` completed successfully: gate `91941763502`, producer
`91941814550`, validator `91942362091`, and restricted publisher
`91943273883` are green. Producer artifact `8886200239` has API digest
`sha256:30255536dd45832f234f23ac2e5f1bfd7e7acfe70613464aa63f28459796c78a`
and contains a 36-member tarball with SHA-256
`0ebb6207937b28a23673ce6725c119d9c9494e74cf5383f80d21d2840d6de04a`.
Validated artifact `8886314579` has API digest
`sha256:096d701536137a124e0b856e86c551ce63f4cc4babae787e6cb17dad213b9993`
and contains the exact 43-member candidate allowlist in a tarball with SHA-256
`04b34811b3bf12265b99de9276a06c3657ee19976c9fb1cc8cca2566e3e02c93`.
Every scoped candidate file matched that artifact byte for byte.

The identity/docs-receipt SHA-256 is
`9db621075e0a0a1dc898fac266a3e70e2eaaf6c965c3b8b007712e277e28eeb3`,
the manifest SHA-256 is
`7dceb40616052bb22e05a1ba68b56c47896ede68d08394b67c502bc81cd1ec8d`,
and the governance release ID is
`sha256:e1d3f1be5620706c71a53783e87b4570c6985fe8d9ed5554ece0b51954aa7aa8`.
The Pages payload SHA-256 is
`43b16e7b44d160055c8fa59039d2c922e802342042b1db1238e65c0249a44fff`.
The following runtime/data authorities are unchanged:

| Authority | SHA-256 |
| --- | --- |
| Runtime payload | `87900f675a1ef34d4f5c47c6788fbaac08a8549d82c4ef900a1b28726e925278` |
| Bundle family | `cbc3fa29a0a1b5ca2577310eab71170a9aa0bc587880282412322605587496c9` |
| Release contract | `15f5686f7f048ad72f1552ada78b2328eeb5718fd27bb2ebd44ddf24312e44bf` |
| Source receipt | `0426ccdc31b4db9e00e768e90ad28918df533fc271078ead42c31293ff138a28` |

### Human review and production closure

Human-authored, non-draft [PR #7](https://github.com/tgilbert14/NEON-My-Little-Inverts/pull/7)
kept exact head `ecbb23cd313632727e78896ab4473b600b456b34`. Exact-head
workflow `30894827652` passed: gate `91945140085`, producer `91945164618`,
and validator `91945946170` succeeded; publisher `91950596073` was skipped
with zero steps by design. Expected-head merge produced
`6972817382491cc9312ae4588b75bc67ed422987`.

Pages run `30896544721` succeeded on that merge (build `91950697821`, deploy
`91950754979`, report `91950755051`). Connect publication #18
(`019fcc1b-5672-3278-21c6-9ead85568da2`) successfully published the exact merge
in five seconds with R 4.5.2 and all 91 required R packages; its startup log has
no Startup Error. Production run `30896548595`, smoke job `91950703053`, passed
exact main identity, byte-exact Pages index/art/social assets, desktop/390/320
geometry, visible keyboard focus, no poster animation, the exact 34-site roster,
the exact SYCA `193 / 121 / 121 / 245 / 17` statistics, Help's server round
trip, and zero browser, request, same-origin HTTP, stylesheet, or image failures.
Independent signed-in QA confirmed publication #18's exact merge, release ID,
SYCA workflow, and Help round trip with no startup or browser error.

### Superseded governance attempts

These are withheld/cancelled safeguard evidence, not production authority:

- Run `30891267045` at `ae2fd0202bc9c508d145ed20f913ca868d6969d3`
  completed and produced candidate
  `c81f7f506c71d6857c141de234bd4a80e6db6cb9`, but review found
  governance/identity-lane and browser-gate defects. It received no PR, merge,
  or production authority; the review branch was later replaced by `ecbb23c…`.
- Run `30893151571` at `88ab1e301d316fc1c75357119966fd57d273a1a1`
  was deliberately cancelled during producer after the remaining browser
  dependency issue was found. It produced no artifact or candidate.
- Run `30893443751` at `8f538de74ea060e273499c3bb7c922b299bdfd85`
  was deliberately cancelled after producer artifact `8886057041` when
  post-candidate exact-head workflow status remained in identity-bound
  documentation. It produced no validated artifact, candidate, review branch,
  or production byte.

## 2026-08-04 — Pass-9 authoritative runtime release complete

### Current position

- Reviewed science head:
  `6043c400afb21425d7c319e8225b9693fae416da` (`fix: validate canonical
  invert metadata`).
- Publication head:
  `a685e01c61938fcbd49325d7cf365aa272fae58a` (`fix: validate pinned Inverts
  icons early`).
- Authoritative publication attempt: `30885526988`.
- Corrected workflow status at this handoff: **complete success**. Gate job
  `91915773284`, producer job `91915789152`, validator job `91920084679`, and
  restricted publisher job `91924715580` are green.
- Direct-child candidate `b7dffb6c…` passed exact-head PR workflow
  `30888675725` and merged with expected-head protection as `ff23e994…`.
- Pages deployment `30890184235`, Connect publication #17, and production
  verification `30890185880` are green on that exact merge and release identity.
- Governance and browser-gate hardening is now separately published and recorded
  above. It strengthens verification without replacing this runtime/science
  authority.

### Current source-authoritative receipt and producer evidence

Run `30885526988` at publication head
`a685e01c61938fcbd49325d7cf365aa272fae58a` fetched at
`2026-08-04T07:08:55Z` and passed its source and producer gates. Independent
local handoff verification also passed. It produced source artifact
`8883372756`, reported with the name prefix `invert-source-a685…`:

| Evidence | Exact value |
| --- | --- |
| Source artifact API zip | 15,554,711 bytes |
| Source artifact API digest | `sha256:80d94fff2e7835d6e407e06bc9ca8b4995500ff4346ef979128fa8fe61196468` |
| Raw RDS | 15,755,405 bytes |
| Raw RDS SHA-256 | `13345d39682bcc27ec45fca490cd63888b18c98735e6575737a79c6c109b67d0` |
| Fetch evidence SHA-256 | `c2e792d513c875c8f38d78fa76f84c0478c0954eeac48b75405979248f10d415` |
| Source receipt SHA-256 | `0426ccdc31b4db9e00e768e90ad28918df533fc271078ead42c31293ff138a28` |
| Citation SHA-256 | `4cc2f4603c86cec78b43e5024cf729c1de87d74c31786098faae6031f4c075ab` |
| Maximum source publication date | `2025-12-09` |

Producer artifact `8883439067` is a 10,457,625-byte API zip with digest
`sha256:90b92ac47492552cf6cb63fa93c194139ca5db4600cb152e3f373f410d40b567`.
Its inner release tarball SHA-256 is
`64883e4d6e13129c7f4d4ac445405c58c12dff6d9afeb4f539822646090122bd`,
and its release-contract SHA-256 is
`15f5686f7f048ad72f1552ada78b2328eeb5718fd27bb2ebd44ddf24312e44bf`.
The producer allowlist is exactly the release contract, receipt, and 34 site
files; its embedded receipt is byte-identical to the authoritative source
receipt.

The receipt-bound source inventories 7,201 field rows, 6,446 per-sample rows,
and 320,240 taxonomy rows. Three `.DNA` field rows remain quarantined, leaving
7,198 collection opportunities at the canonical 34 sites. Producer reconciliation
matches the independently replayed diagnostic source: 830 events, 1,679 exact
event strata, 6,477 primary-stratum opportunities, 6,213 count eligible, 6,213
density eligible, 719 unstratifiable, 181,922 collapsed taxonomy records, and
85,874 search rows. The source stamp is `2025-12-09`, and the release family
contains 55 checksums.

### Validated candidate and completed runtime release

Validated artifact `8883990535` is an 11,001,544-byte API zip with digest
`sha256:ec37be5bd0f3fe56cb9dde50e56f80193af024b7aa5a233bc5749db29f55b22d`.
Its inner 10,998,101-byte release tarball has SHA-256
`6aa5903dbb292f93c6c4c142a5cf7378322c8ca3c1845b4b47ad100012bf0c10`.
The exact 43-member allowlist is 34 site files plus the release contract,
receipt, site index, cross-site file, search index, demo file, manifest,
production identity, and docs release.

Candidate `b7dffb6c1e149c52d094c4347483435df07856f6` has sole parent
`a685e01c61938fcbd49325d7cf365aa272fae58a`. All 43 candidate-branch files
match the validated artifact byte for byte. The identity/docs-receipt SHA-256 is
`f0be51e0da7cc41176abdda57c52e202019579c1df3890e6ab7df18f8a1a1f46`,
the manifest SHA-256 is
`26b94b5e8ddc5e22618ad47faf1b388802dfa76354fd38f0a33a5c4c1a0eb8d2`,
and the release ID is
`sha256:fcee160ddb5e6ecedbca84811dea57993263507bbb8c38570b5243d5d7644ee5`.
Package proof is dated and contains no `cran.rstudio.com` reference.

Human-authored, non-draft [PR #6](https://github.com/tgilbert14/NEON-My-Little-Inverts/pull/6)
has exact head `b7dffb6c1e149c52d094c4347483435df07856f6`. PR workflow
`30888675725` completed successfully: gate `91925475929`, producer
`91925500126`, and validator `91926069602` are green; restricted publisher job
`91930036661` is skipped with zero steps by design. The exact candidate merged
as `ff23e994e289982c747b91e48c5ff0907c1672d2` on 2026-08-04.

Pages run `30890184235` succeeded on that merge. Connect publication #17
(`019fcbca-a610-e368-7562-54b93e2056d0`) successfully published the same commit
with R 4.5.2, `bslib` 0.11.0, `bsicons` 0.1.2, and `plotly` 4.12.0. Production
verification run `30890185880`, smoke job `91930207585`, passed exact Pages and
Connect HTTP identity plus a live bidirectional Shiny session. Independent
signed-in QA also confirmed the local Living Poster, Leaflet map, all-34-site
picker, SYCA's five hero statistics (including 193 field opportunities), the
server-backed Help modal, no horizontal overflow at desktop width, and no
browser errors.

### Safe failures and the exact repairs

1. Full run `30876585674` on `cd2f6c0` completed the source download but stopped
   before an authoritative receipt or candidate. `variables_20120` was a real
   `data.table/data.frame`; its process-local `.internal.selfref` external pointer
   changed persisted-byte round-trip evidence.
2. `60bb041ae4d1d78cba023efce86c25ead1a1b7f7` canonicalized only that volatile
   attribute, preserving class, columns, and every other attribute.
3. Full run `30878052158` then stopped before a receipt or candidate because
   base-data-frame column-selection syntax dispatched through `[.data.table` in
   the clean source validator.
4. `6043c400afb21425d7c319e8225b9693fae416da` added read-only metadata projection
   through `[[`, with real `data.table` adversarial tests and serialized-source
   equality before/after validation.
5. Full run `30880052469` passed source and producer gates but stopped in the
   clean validator before identity stamping or candidate publication. The pinned
   `setup-r` action had configured a moving `https://cran.rstudio.com` fallback,
   so `bslib` 0.12.0 displaced snapshot-retained 0.11.0 and the manifest
   provenance gate correctly failed.
6. `c1bd68184f06c4a011806193ce511f367d92d1ea` pins both configured
   repositories to the dated RELEASE-2026 snapshot, installs the retained
   `bslib` source URL explicitly, and independently verifies its URL provenance.
7. Full run `30882432569` passed all source, science, producer, release,
   loaded-app, and candidate checks: 143 source, 109 science, 43 producer, 58
   release-verifier, and 104 loaded-app checks. Its 34-site candidate inventory
   reconciled 7,198 opportunities, 6,213 count eligible, 6,213 density eligible,
   719 unstratifiable, 85,874 search rows, source stamp `2025-12-09`, and 55
   checksums. Package-pin proof was clean, with zero `cran.rstudio.com`
   references. The final full-UI source gate then failed because `bsicons` 0.1.2
   rejected the nonexistent icon name `scatter-chart`. Validated packaging,
   upload, and restricted publisher steps were skipped; no candidate branch or
   PR was created.
8. `a685e01c61938fcbd49325d7cf365aa272fae58a` replaces `scatter-chart` with
   valid `graph-up`, adds exact-package icon inventory/render regression, pins
   the exact `bsicons` source in early producer dependencies, and adds an early
   validator gate. Run `30885526988` completed successfully through its
   restricted publisher and produced direct-child candidate `b7dffb6c…`.

Run `30882432569`'s evidence is retained only as safe failed history. It fetched
at `2026-08-04T06:13:33Z`; its source artifact `8882105960` had API digest
`sha256:485c05f2612bf810109c74004a29057ba38a7ae159ec749cd7403b8f8fc5bbe7`;
the raw RDS SHA-256 was
`f471421791853c8a7047a4276c7b9ab5cf6b800b342af11ae8f7a22ac4f8f47e`,
the fetch-evidence SHA-256 was
`a8f98aa0d116d086da0ff05166152c93fb12f75c5ff41e55e90d8e9f47240c12`,
and the source-receipt SHA-256 was
`26fcb9193813440bbd69a349fde70b875347f1219a4474026c144618872a2ed1`.
Its producer artifact `8882157880` had API digest
`sha256:a380395b4b12b846229d69189f23dd6fc73e11b960bafeb068cbefe4e2691761`,
inner release-tarball SHA-256
`7b2fe393709f673f17291245e597dee5faafd510f0f01073b009ad9f37eb201d`,
and release-contract SHA-256
`5f8ab8088957bf4c8dcf17b02292022ec3985cfabb5ab97a6e04963888002d1b`.
None of those hashes belongs to current run `30885526988`.

Run `30880052469` remains safe failed history, not current release authority. Its
source artifact `8881240077` contained a 15,755,274-byte raw RDS with SHA-256
`b8ab62bad995101f3da4bc04c133cf4705b8e0d942a925774a4424a56f3faed2`;
its source receipt SHA-256 was
`5369b6bc2940e3e02658afa01d44c89ff47d030af519d27c2c7a296135e881dd`.
Its producer artifact was `8881289043`, with API digest
`sha256:c4edadeff5b8fedfddd14dc4490e5041145b7c13b7bc56e2287157a56130ee73`.
Those receipts bind only that failed run's exact source/producer evidence and
grant no candidate or production authority.

Run `30878052158` preserved nonauthoritative raw source artifact `8880476751`.
Its raw RDS is 15,755,404 bytes with SHA-256
`6e36b6653f0a05f5ab86dbe5b009b61215d3a83e67f0cbed1493472539d86f9e`.
It is safe-failure evidence only: its fetch-evidence record said
`publication_authorized=false`, and the run published no authoritative receipt,
candidate, review branch, or production byte.

### Exact local replay evidence

Before spending a third full network fetch, `6043c40` was replayed in a disposable
checkout against the preserved `6e36b6…` raw RDS:

- source fixtures: 143 checks;
- science fixtures: 109 checks;
- producer fixtures: 43 checks;
- release-verifier fixtures: 58 checks;
- loaded-app fixtures: 104 checks;
- the real source object passed with `data.table` loaded and serialized
  identically before/after validation;
- the raw-to-34-site producer and independent verifier completed; and
- a second clean build matched all 40 release-family files byte for byte while
  streaming verification retained at most one fully loaded site bundle.

That replay proved the code path and justified run `30880052469`; it did not
convert the earlier evidence artifact into publication authority. Run
`30882432569` created and passed the source and producer gates for its own
receipt and producer artifact, then failed safely at the final full-UI source
gate before validated packaging or publication. Its evidence remains bound to
that failed attempt. Run `30885526988` completed its own source, producer,
independent validator, and restricted publisher gates and produced the validated
direct-child candidate reviewed in PR #6. Exact-head checks, expected-head
merge, Pages, Connect, and live production authority are now complete.

### Release identifiers to fill only from exact evidence

| Gate | Identifier |
| --- | --- |
| Direct-child reviewed candidate | `b7dffb6c1e149c52d094c4347483435df07856f6` |
| Reviewer-authenticated exact-head PR | [#6](https://github.com/tgilbert14/NEON-My-Little-Inverts/pull/6), head `b7dffb6c1e149c52d094c4347483435df07856f6` |
| Expected-head merge to `main` | `ff23e994e289982c747b91e48c5ff0907c1672d2` |
| Exact-merge Pages run / identity | `30890184235` / `sha256:fcee160ddb5e6ecedbca84811dea57993263507bbb8c38570b5243d5d7644ee5` |
| Connect publication / live round trip | #17 (`019fcbca-a610-e368-7562-54b93e2056d0`) / production run `30890185880`, job `91930207585` |

Governance/tooling publication is complete. It changed no source, science,
bundle, derived-index, or runtime-payload byte. Next action is the suite Driver
closeout and cross-product synthesis; do not reopen this handoff merely to record
its own documentation-only merge.

## 2026-08-03 — Previous production baseline

This was the live baseline before Pass 9 completed; preserve it for rollback
and comparison.

- Provenance repair head `3d116fa849cf7c23fc0a1e7334a28bebcf9f4a45`
  produced direct-child candidate
  `d9a3d1c60252b286b5cf708949cb14589aa6de59` in run `30825083094`.
- PR #4 literal-head run `30826225675` passed and PR #4 merged with expected-head
  protection as `fd509ae6821aae556a51ac05820e7f4f5dafbad5`.
- Pages deployment `30827939797` passed on that merge. The live Pages response
  was byte-identical to merged `docs/index.html`, SHA-256
  `11b4deac721d62a638f382475a0c7e2b7acac3b5e5bd40eca218756612147f45`.
- Connect returned a real 34-site Shiny app, but the old release had no exact
  runtime identity receipt. Availability therefore did not bind the worker to
  `fd509ae`; Pass 9's content-aware post-deploy gate replaces that gap.

The previous bundle family was taxonomy-first (830 bouts, 6,430 samples, 9,392
search rows, source stamp `2026-06-22`). Do not use those figures as Pass-9 data
takeaways.

## 2026-08-03 — Refresh-platform repair history

The repair series is useful platform evidence:

- The scheduled workflow was changed from direct-main/heavy-fetch behavior to a
  manual-only full fetch and scheduled committed-family rebuild. Publication now
  follows producer → independent validator → restricted review branch.
- PR #3 merged the first publisher repair as
  `d1af49817e52381b2a519f3c3d68e7c32b175003`; run `30819110562` published
  diagnostic candidate `39e169fe046bb01d9a16fec83b0b8330fdcd94ec`, which was
  correctly held for manifest provenance concerns and never merged.
- Run `30822032342` then failed safely when `rsconnect::writeManifest()` exposed a
  moving ordinary-CRAN alias. The writer now accepts that alias only under the
  exact dated RSPM controls and canonicalizes the final deployment lane.
- An adversarial audit closed a verifier gap for ordinary URL/GitHub remotes;
  only empty/base or standard dated-RSPM records are allowed outside the exact
  Plotly/geospatial URL allowlist. Run `30824016239` predated that hardening and
  remained superseded even if otherwise green.
- The validated publication baseline ultimately reached PR #4 and `fd509ae` as
  recorded above.

These failures changed no production bytes until an exact reviewed candidate
merged. Retain that distinction in future incident reports.
