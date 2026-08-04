# Driver knowledge package — My Little Inverts Pass 9

## Register identity

| Field | Value |
| --- | --- |
| App | NEON My Little Inverts |
| Repository | `tgilbert14/NEON-My-Little-Inverts` |
| Product | `DP1.20120.001` — Macroinvertebrate collection |
| Default / Connect branch | `main` |
| Pass | 9 |
| Reviewed science head | `6043c400afb21425d7c319e8225b9693fae416da` |
| Publication head | `a685e01c61938fcbd49325d7cf365aa272fae58a` |
| Authoritative full run | `30885526988` (complete success) |
| Direct-child candidate | `b7dffb6c1e149c52d094c4347483435df07856f6` |
| Human review PR | [#6](https://github.com/tgilbert14/NEON-My-Little-Inverts/pull/6), exact head `b7dffb6c…` |

This identity-bound package records authoritative runtime lineage through its
ancestor direct-child candidate and completed human review. Exact post-merge,
Pages, Connect, and production identifiers live only in the identity-excluded
`docs/BUILD-TEST-HANDOFF.md`; duplicating mutable closeout identifiers here
would create a new release identity.

## What changed in Pass 9

Pass 9 replaced a taxonomy-first positive-record product with a field-first,
opportunity-complete product:

- all non-`.DNA` field rows are retained as the sampling-opportunity ledger;
- sampling, processing, taxonomy, count, composition, and density outcomes are
  explicit and separately denominated;
- comparison grain preserves site, event, water type, habitat, and sampler;
- unresolved taxonomy/count outcomes remain unknown, never fabricated zeros;
- taxon rank and order-classification support stay attached to results;
- cross-site output is effort-only rather than a raw biological ranking;
- raw source, citation, schema, classes, receipts, bundles, manifest, Pages, and
  Connect are bound by one content-addressed production identity; and
- the Pages/app cover is a static artistic Living Poster with responsive,
  reduced-motion, and accessibility checks.

## Receipt-bound evidence available now

Current full run `30885526988` at publication head
`a685e01c61938fcbd49325d7cf365aa272fae58a` used `RELEASE-2026` with
provisional data disabled. It fetched at `2026-08-04T07:08:55Z`, and its source
and producer gates are green. Independent local handoff verification passed:

- source artifact `8883372756`, reported with name prefix
  `invert-source-a685…`, is a 15,554,711-byte API zip with digest
  `sha256:80d94fff2e7835d6e407e06bc9ca8b4995500ff4346ef979128fa8fe61196468`;
- the raw RDS is 15,755,405 bytes with SHA-256
  `13345d39682bcc27ec45fca490cd63888b18c98735e6575737a79c6c109b67d0`;
- fetch-evidence SHA-256
  `c2e792d513c875c8f38d78fa76f84c0478c0954eeac48b75405979248f10d415`;
- source-receipt SHA-256
  `0426ccdc31b4db9e00e768e90ad28918df533fc271078ead42c31293ff138a28`;
- citation SHA-256
  `4cc2f4603c86cec78b43e5024cf729c1de87d74c31786098faae6031f4c075ab`
  and maximum source publication date `2025-12-09`;
- producer artifact `8883439067` is a 10,457,625-byte API zip with digest
  `sha256:90b92ac47492552cf6cb63fa93c194139ca5db4600cb152e3f373f410d40b567`;
- inner release tarball SHA-256
  `64883e4d6e13129c7f4d4ac445405c58c12dff6d9afeb4f539822646090122bd`
  and release-contract SHA-256
  `15f5686f7f048ad72f1552ada78b2328eeb5718fd27bb2ebd44ddf24312e44bf`;
- exact producer allowlist: release contract, receipt, and 34 site files; the
  embedded producer receipt is byte-identical to the source receipt;
- raw tables: 7,201 field rows, 6,446 per-sample rows, and 320,240 taxonomy rows;
- three `.DNA` field rows quarantined, leaving 7,198 collection opportunities;
- 34 sites, 830 events, 1,679 exact event strata;
- 6,477 primary-stratum opportunities, 6,213 count eligible, and 6,213 density
  eligible;
- 719 unstratifiable opportunities, 181,922 collapsed taxonomy records, and
  85,874 search rows;
- source stamp `2025-12-09` and 55 release-family checksums.

Before the current network sequence, a disposable exact replay of safe-failure
raw RDS `6e36b665…` produced two clean builds matching all 40 release-family
files byte for byte, with the raw source serialized identically before and after
validation.
Current head `a685e01` retains the dated snapshot and exact `bslib` provenance
repair, replaces the invalid icon with valid `graph-up`, adds exact-package icon
inventory/render regression, pins the exact `bsicons` source in early producer
dependencies, and adds an early validator gate.

Full run `30885526988` completed successfully. Gate job `91915773284`, producer
job `91915789152`, validator job `91920084679`, and restricted publisher job
`91924715580` are green. Package proof is dated and contains no
`cran.rstudio.com` reference.

## Validated candidate and human review

Validated artifact `8883990535` is an 11,001,544-byte API zip with digest
`sha256:ec37be5bd0f3fe56cb9dde50e56f80193af024b7aa5a233bc5749db29f55b22d`.
Its inner 10,998,101-byte release tarball has SHA-256
`6aa5903dbb292f93c6c4c142a5cf7378322c8ca3c1845b4b47ad100012bf0c10`.
The exact 43-member allowlist comprises the 34 site files plus release contract,
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

Human-authored, non-draft [PR #6](https://github.com/tgilbert14/NEON-My-Little-Inverts/pull/6)
has exact head `b7dffb6c1e149c52d094c4347483435df07856f6`. PR workflow
`30888675725` completed successfully: gate, producer, validator, and the
PR-only stale-identity rejection test are green; publisher is skipped with zero
steps by design. Expected-head merge, Pages, Connect identity, and a live
bidirectional Shiny probe subsequently passed. Exact production identifiers are
recorded in `docs/BUILD-TEST-HANDOFF.md`.

## Safe-failure evidence

- Run `30876585674` fetched the full source at `cd2f6c0` but stopped before a
  receipt/candidate because `data.table`'s volatile `.internal.selfref` changed
  persisted-byte evidence.
- Run `30878052158` fetched the full source at `60bb041` and preserved raw
  artifact `8880476751`, but stopped before a receipt/candidate because a
  validator projection dispatched through `[.data.table`.
- `60bb041` removes only `.internal.selfref` during materialization.
- `6043c40` uses read-only `[[` metadata projection and proves the canonical
  source remains byte-identical through validation.
- Run `30880052469` passed source and producer gates at `6043c40` but stopped
  safely in the clean validator when a moving CRAN fallback supplied `bslib`
  0.12.0 instead of the snapshot-retained 0.11.0. Its source artifact
  `8881240077` contained a 15,755,274-byte raw RDS with SHA-256
  `b8ab62bad995101f3da4bc04c133cf4705b8e0d942a925774a4424a56f3faed2`;
  its source receipt SHA-256 was
  `5369b6bc2940e3e02658afa01d44c89ff47d030af519d27c2c7a296135e881dd`.
  Those receipts are safe failed history only.
- `c1bd681` pins every workflow repository to the dated snapshot and binds
  `bslib` version, source URL, and URL provenance in two independent checks.
- Run `30882432569` passed its source, science, producer, release, loaded-app,
  and candidate checks, then stopped safely at the final full-UI source gate
  when `bsicons` 0.1.2 rejected `scatter-chart`. Validated packaging, upload,
  and publisher steps were skipped; no candidate branch or PR was created. Its
  check totals were 143 source, 109 science, 43 producer, 58 release-verifier,
  and 104 loaded-app. Its source/producer receipts remain authoritative only for
  that failed attempt:
  source artifact `8882105960` had API digest
  `sha256:485c05f2612bf810109c74004a29057ba38a7ae159ec749cd7403b8f8fc5bbe7`;
  its raw RDS, fetch-evidence, and source-receipt SHA-256 values were
  `f471421791853c8a7047a4276c7b9ab5cf6b800b342af11ae8f7a22ac4f8f47e`,
  `a8f98aa0d116d086da0ff05166152c93fb12f75c5ff41e55e90d8e9f47240c12`,
  and `26fcb9193813440bbd69a349fde70b875347f1219a4474026c144618872a2ed1`;
  producer artifact `8882157880` had API digest
  `sha256:a380395b4b12b846229d69189f23dd6fc73e11b960bafeb068cbefe4e2691761`,
  inner release-tarball SHA-256
  `7b2fe393709f673f17291245e597dee5faafd510f0f01073b009ad9f37eb201d`,
  and release-contract SHA-256
  `5f8ab8088957bf4c8dcf17b02292022ec3985cfabb5ab97a6e04963888002d1b`.
- `a685e01` replaces the icon with valid `graph-up`, verifies the exact-package
  icon inventory and rendering, pins the early `bsicons` source, and moves the
  same check into an early validator gate.

The first two runs published no authoritative source receipt. None of the four
safe-failure runs published a candidate, review branch, or production byte. This
distinction belongs in the central failure ledger: a failed scheduled/manual
refresh does not mean the live app changed.

## Reusable suite lessons

### 1. Field-first is the default for opportunity-sampled products

Start from the table that records attempts or opportunities. Join observations,
laboratory outcomes, and taxonomy as children. Positive records alone cannot
represent effort, genuine zero, impractical sampling, or unknown processing.

### 2. Keep two status systems when precedence can hide evidence

A mutually exclusive display status is useful, but overlapping audit flags and a
separate processing/outcome partition preserve evidence that another status may
mask. Driver audits should demand both reconciliation totals.

### 3. Raw-object identity can include volatile implementation metadata

`data.table` serializes `.internal.selfref`, an external pointer that cannot be a
portable content claim. Remove exactly that attribute, preserve class and every
other attribute, and exercise the real `data.table` method in regression tests.
Never use `setDF`, `setattr`, or another by-reference repair on source authority.

### 4. Fetch evidence and publication authority are different artifacts

Upload raw-plus-evidence even when validation fails, but mark it explicitly
nonauthoritative. Produce the source receipt only after source-contract success;
make all downstream jobs require it.

### 5. Determinism and memory bounds are both release properties

Rebuild twice and compare the entire release family byte-for-byte. Verify large
site families as a stream and assert the maximum number of fully retained
bundles; semantic equality without a memory bound is not enough for hosted CI.

### 6. HTTP availability is not exact production provenance

Pages and Connect must expose the release identity recomputed from the merge.
Connect additionally needs a real bidirectional Shiny action. Do not map a public
200 response to a commit without that receipt.

## Driver updates on closure

When the release closes, update the app-local handoff and the central register,
suite learning loop, revamp plan, and Driver handoff. Record there:

- PR run `30888675725`'s exact-head conclusion;
- the exact merge, Pages, and post-deploy run IDs;
- Pages artifact IDs/digests where available;
- Connect publication number/content identity and live Shiny round trip; and
- the final source/data counts from `docs/DATA-TAKEAWAYS.md`.

Preserve all four safe failures as useful platform evidence; do not collapse
the history into an undifferentiated “refresh failed.”
