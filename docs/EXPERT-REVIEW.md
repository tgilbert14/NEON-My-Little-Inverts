# My Little Inverts — Pass-9 expert review

- **Review date:** 2026-08-04
- **Reviewed science head:** `6043c400afb21425d7c319e8225b9693fae416da`
- **Current publication head:** `a685e01c61938fcbd49325d7cf365aa272fae58a`
- **Scope:** source authority, estimand, denominators, edge cases, public claims,
  release reproducibility, and loaded-product behavior

**Decision:** the science implementation has no unresolved P0–P2 finding. A
prior receipt-authoritative run failed safely at the final full-UI source gate;
the corrected replacement run completed successfully through independent
validation and restricted candidate publication. Its exact direct-child
candidate is independently validated. This identity-bound review intentionally
does not carry later PR, merge, Pages, Connect, or live-production status; see
the identity-excluded handoff and central Driver register.

This is an app-local scientific/engineering review, not external peer review of
NEON's data product or a validation of ecological condition inference.

## Review questions and findings

### Is the population of sampling opportunities complete?

Yes. The field table, not positive taxonomy, is the denominator authority. The
exact local replay retained all 7,198 non-`.DNA` field rows as opportunities at
34 sites. Three `.DNA` field rows and their related laboratory family remained
in the raw authority and QC inventories but were explicitly quarantined from the
morphology-based collection estimand.

The mutually exclusive status ledger reconciled to 7,198. Independent support
flags also remained visible, so 713 sampling-impractical and eight nonstandard
collections were not lost when another primary display status had precedence.

### Are missing, unknown, and zero distinct?

Yes. Among 6,485 practical opportunities, the independent processing/count
partition was 34 processing unknown, zero processed-without-taxonomy, 237 with
taxonomy/count unavailable, and 6,214 with taxonomy/count available. Exactly
6,213 opportunities were count eligible. The release contained no reported-zero
opportunity.

One sample has a taxonomy `subsamplePercent` displayed as zero while the linked
per-sample record is 0.5%. The source contract does not invent a multiplier or
rewrite the displayed source. It uses the finite published
`estimatedTotalCount`, retains all 53 affected taxonomy rows, and exposes the
anomaly as evidence. This is an appropriate fail-closed treatment.

### Are comparison grain and denominators defensible?

Yes. The implementation keeps
`site × event × aquaticSiteType × habitatType × samplerType` intact. It does not
use modal habitat or sampler labels. Count, positive-composition, and density
eligibility are derived independently from primitive evidence. Missing grain,
count, or area cannot silently change another metric's denominator.

The exact replay produced 6,477 primary-stratum opportunities, 6,213 count
eligible samples, and 6,213 density eligible samples across 830 events and 1,679
exact event strata. Those equal count/density totals are a property of this
receipt-bound source, not an encoded assumption; the contract permits them to
differ in a future release.

### Is taxonomy summarized without false precision?

Yes. Raw taxonomy is retained and reconciled before collapse. The basic package's
omitted slide identity is documented; unique raw `uid` is used as an audited row
identity, not as an invented biological key. Thirty-one unresolved placeholder
rows remain unknown: seven occur beside other count-valid taxa and 24 are the
only placeholder outcome for their sample.

The 85,874 released taxon-stratum rows span 14 identification ranks; only 8,591
are species-rank rows. The interface therefore labels the mixed-rank result
“taxa recorded,” not species richness. EPT is descriptive, keeps unknown-order
positive counts in its denominator, and displays classification support.

### Are cross-site claims appropriately limited?

Yes. The network product contains effort and record-support fields only. It does
not rank raw density, abundance, richness, or EPT share across sites. Public
language consistently describes expanded count and density as properties of the
sampled record, not site populations or ecological condition.

### Is the release reproducible and source-bound?

Yes through the validated direct-child candidate. Before the authoritative
fetch, the exact local raw replay used the 15,755,404-byte
safe-failure artifact with SHA-256
`6e36b6653f0a05f5ab86dbe5b009b61215d3a83e67f0cbed1493472539d86f9e`
with a scoped, locally generated replay receipt. That receipt was never
publication authority. The full source, science, producer, release-verifier, and
loaded-app fixture families passed. A second clean build matched all 40
release-family files byte for byte, and streaming verification retained at most
one full site bundle at a time.

Full run `30880052469` subsequently passed its source and producer gates from a
fresh 15,755,274-byte raw RDS with SHA-256
`b8ab62bad995101f3da4bc04c133cf4705b8e0d942a925774a4424a56f3faed2`.
Its validated source receipt is
`5369b6bc2940e3e02658afa01d44c89ff47d030af519d27c2c7a296135e881dd`,
and its counts/inventories match the exact replay. Its clean validator then
stopped before identity stamping or candidate publication because `bslib`
resolved from a moving CRAN fallback rather than the dated RELEASE-2026 snapshot.
The gate therefore produced no candidate, review branch, or production byte.
Those `b8ab62…` and `5369b6…` receipts are preserved as safe failed history
only; they are not the current source authority.

Former publication head `c1bd68184f06c4a011806193ce511f367d92d1ea` pins both
configured repositories to the dated snapshot and independently requires the
retained `bslib` 0.11.0 source URL in the manifest writer and verifier. Safe
failed full run `30882432569` supplies the latest completed receipt-bound
source/producer evidence for that exact attempt. It fetched at
`2026-08-04T06:13:33Z` and passed its source and producer gates. Source artifact
`8882105960` has API digest
`sha256:485c05f2612bf810109c74004a29057ba38a7ae159ec749cd7403b8f8fc5bbe7`;
the raw RDS SHA-256 is
`f471421791853c8a7047a4276c7b9ab5cf6b800b342af11ae8f7a22ac4f8f47e`,
the fetch-evidence SHA-256 is
`a8f98aa0d116d086da0ff05166152c93fb12f75c5ff41e55e90d8e9f47240c12`,
and the source-receipt SHA-256 is
`26fcb9193813440bbd69a349fde70b875347f1219a4474026c144618872a2ed1`.
The citation SHA-256 is
`4cc2f4603c86cec78b43e5024cf729c1de87d74c31786098faae6031f4c075ab`,
and the maximum source publication date is `2025-12-09`.

Producer artifact `8882157880` has API digest
`sha256:a380395b4b12b846229d69189f23dd6fc73e11b960bafeb068cbefe4e2691761`.
Its inner release tarball SHA-256 is
`7b2fe393709f673f17291245e597dee5faafd510f0f01073b009ad9f37eb201d`,
and its release-contract SHA-256 is
`5f8ab8088957bf4c8dcf17b02292022ec3985cfabb5ab97a6e04963888002d1b`.
All source, science, producer, release, loaded-app, and candidate checks
passed: 143 source, 109 science, 43 producer, 58 release-verifier, and 104
loaded-app checks. The 34-site inventory reconciled 7,198 opportunities, 6,213
count eligible, 6,213 density eligible, 719 unstratifiable, 85,874 search rows,
source stamp `2025-12-09`, and 55 checksums. Package-pin proof was clean, with
zero `cran.rstudio.com` references.

The final full-UI source gate then failed because `bsicons` 0.1.2 rejected the
nonexistent icon name `scatter-chart`. Validated packaging, upload, and the
restricted publisher were skipped, so run `30882432569` created no candidate
branch or PR. Its source/producer receipts remain authoritative only for that
safe failed attempt.

Fix head `a685e01c61938fcbd49325d7cf365aa272fae58a` replaces
`scatter-chart` with valid `graph-up`, adds exact-package icon inventory/render
regression, pins the exact `bsicons` source in early producer dependencies, and
adds an early validator gate. Run `30885526988` is the new authoritative
publication attempt at that head. It fetched at `2026-08-04T07:08:55Z`, and
independent local handoff verification passed. Source artifact `8883372756`,
reported with the name prefix `invert-source-a685…`, is a 15,554,711-byte API
zip with digest
`sha256:80d94fff2e7835d6e407e06bc9ca8b4995500ff4346ef979128fa8fe61196468`.
The 15,755,405-byte raw RDS SHA-256 is
`13345d39682bcc27ec45fca490cd63888b18c98735e6575737a79c6c109b67d0`,
the fetch-evidence SHA-256 is
`c2e792d513c875c8f38d78fa76f84c0478c0954eeac48b75405979248f10d415`,
and the source-receipt SHA-256 is
`0426ccdc31b4db9e00e768e90ad28918df533fc271078ead42c31293ff138a28`.
The citation SHA-256 remains
`4cc2f4603c86cec78b43e5024cf729c1de87d74c31786098faae6031f4c075ab`,
and the maximum source publication date is `2025-12-09`.

Producer artifact `8883439067` is a 10,457,625-byte API zip with digest
`sha256:90b92ac47492552cf6cb63fa93c194139ca5db4600cb152e3f373f410d40b567`.
Its inner release tarball SHA-256 is
`64883e4d6e13129c7f4d4ac445405c58c12dff6d9afeb4f539822646090122bd`,
and its release-contract SHA-256 is
`15f5686f7f048ad72f1552ada78b2328eeb5718fd27bb2ebd44ddf24312e44bf`.
The producer allowlist is exactly the release contract, receipt, and 34 site
files, and its embedded receipt is byte-identical to the authoritative source
receipt. Source inventories and counts are unchanged. Full run `30885526988`
completed successfully: gate job `91915773284`, producer job `91915789152`,
validator job `91920084679`, and restricted publisher job `91924715580` are
green. Package proof is dated and contains no `cran.rstudio.com` reference.

Validated artifact `8883990535` is an 11,001,544-byte API zip with digest
`sha256:ec37be5bd0f3fe56cb9dde50e56f80193af024b7aa5a233bc5749db29f55b22d`.
Its inner 10,998,101-byte release tarball has SHA-256
`6aa5903dbb292f93c6c4c142a5cf7378322c8ca3c1845b4b47ad100012bf0c10`.
Its exact 43-member allowlist is the 34 site files plus release contract,
receipt, site index, cross-site file, search index, demo file, manifest,
production identity, and docs release.

Candidate `b7dffb6c1e149c52d094c4347483435df07856f6` has sole parent
`a685e01c61938fcbd49325d7cf365aa272fae58a`, and all 43 branch files match
the validated artifact byte for byte. The identity/docs-receipt SHA-256 is
`f0be51e0da7cc41176abdda57c52e202019579c1df3890e6ab7df18f8a1a1f46`,
the manifest SHA-256 is
`26b94b5e8ddc5e22618ad47faf1b388802dfa76354fd38f0a33a5c4c1a0eb8d2`,
and the release ID is
`sha256:fcee160ddb5e6ecedbca84811dea57993263507bbb8c38570b5243d5d7644ee5`.

Human-authored, non-draft [PR #6](https://github.com/tgilbert14/NEON-My-Little-Inverts/pull/6)
was opened at exact head `b7dffb6c1e149c52d094c4347483435df07856f6`.
This identity-bound review stops at that knowable candidate/PR-head fact.
Downstream check, merge, Pages, Connect, and live-production status belongs only
in `docs/BUILD-TEST-HANDOFF.md` and the central Driver register.

The first four GitHub full-fetch attempts failed safely before candidate
publication. Those failures exposed volatile `data.table` metadata,
class-dispatch assumptions, a moving repository fallback, and an invalid icon
name; all four were repaired without weakening the source, package-provenance,
or UI gates. The exact raw object serialized identically before and after source
validation.

## Resolved review findings

| Severity | Finding | Resolution |
| --- | --- | --- |
| P0 | Taxonomy-first bundles erased noncollection and unresolved outcomes | Field-first opportunity ledger with exact reconciliation |
| P0 | Fetch evidence could be mistaken for source authority | Separate nonauthoritative evidence and validated immutable receipt |
| P1 | Count and density shared an implicit denominator | Independent eligibility and explicit metric contract |
| P1 | Missing taxonomy/count could become an apparent zero | Exclusive processing/count partition; unknown never zero-filled |
| P1 | Basic-package slide identity is absent | Exact metadata proof plus unique raw-UID surrogate inventory |
| P1 | `data.table` self-reference changed persisted-byte evidence | Remove only `.internal.selfref`; prove all other bytes/attributes |
| P1 | Base projection syntax dispatched through `[.data.table` | Read-only `[[` projection; real-method adversarial regression |
| P2 | Mixed ranks could be read as species richness | Rank retained and public label/caveat corrected |
| P2 | Network values could imply biological ranking | Effort-only cross-site allowlist and verifier prohibition |

No unresolved P0, P1, or P2 scientific-contract finding remains at the reviewed
source head.

## Production closure gates

Candidate readiness is not production proof. Operational closure status is
recorded outside this identity-bound review. Every release must still require:

1. a literal-head PR validator for the exact candidate;
2. expected-head merge to `main`;
3. Pages and Connect expose the same recomputed release identity; and
4. Connect loads the canonical site family and completes a real Shiny
   client/server round trip.

Record the resulting immutable identifiers in `docs/BUILD-TEST-HANDOFF.md` and
the central Driver register before changing the suite register to closed.
