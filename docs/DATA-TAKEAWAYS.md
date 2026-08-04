# NEON My Little Inverts — Pass-9 data takeaways

These facts come from the receipt-authorized producer in current full run
`30885526988` at publication head
`a685e01c61938fcbd49325d7cf365aa272fae58a`. Source artifact `8883372756`,
reported with the name prefix `invert-source-a685…`, is a 15,554,711-byte API
zip with digest
`sha256:80d94fff2e7835d6e407e06bc9ca8b4995500ff4346ef979128fa8fe61196468`.
It contains the exact 15,755,405-byte `RELEASE-2026` raw RDS with SHA-256
`13345d39682bcc27ec45fca490cd63888b18c98735e6575737a79c6c109b67d0`.
The fetch-evidence SHA-256 is
`c2e792d513c875c8f38d78fa76f84c0478c0954eeac48b75405979248f10d415`.
Its source receipt fixes provisional data to `false`, DOI
`10.48443/hp56-s582`, fetch time `2026-08-04T07:08:55Z`, and maximum source
publication date `2025-12-09`; the receipt SHA-256 is
`0426ccdc31b4db9e00e768e90ad28918df533fc271078ead42c31293ff138a28`.
The citation SHA-256 remains
`4cc2f4603c86cec78b43e5024cf729c1de87d74c31786098faae6031f4c075ab`.

Independent local handoff verification passed. Producer artifact `8883439067`
is a 10,457,625-byte API zip with digest
`sha256:90b92ac47492552cf6cb63fa93c194139ca5db4600cb152e3f373f410d40b567`.
Its inner release tarball SHA-256 is
`64883e4d6e13129c7f4d4ac445405c58c12dff6d9afeb4f539822646090122bd`,
and its release-contract SHA-256 is
`15f5686f7f048ad72f1552ada78b2328eeb5718fd27bb2ebd44ddf24312e44bf`.
The producer allowlist is exactly the release contract, receipt, and 34 site
files; its embedded receipt is byte-identical to the authoritative source
receipt. Full run `30885526988` completed successfully: gate job `91915773284`,
producer job `91915789152`, validator job `91920084679`, and restricted
publisher job `91924715580` are green. Package proof is dated and contains no
`cran.rstudio.com` reference.

## Validated release and review state

Validated artifact `8883990535` is an 11,001,544-byte API zip with digest
`sha256:ec37be5bd0f3fe56cb9dde50e56f80193af024b7aa5a233bc5749db29f55b22d`.
Its inner 10,998,101-byte release tarball has SHA-256
`6aa5903dbb292f93c6c4c142a5cf7378322c8ca3c1845b4b47ad100012bf0c10`.
The exact 43-member allowlist contains the 34 site files plus release contract,
receipt, site index, cross-site file, search index, demo file, manifest,
production identity, and docs release.

Direct-child candidate `b7dffb6c1e149c52d094c4347483435df07856f6` has sole
parent `a685e01c61938fcbd49325d7cf365aa272fae58a`; all 43 branch files match
the validated artifact byte for byte. Its identity/docs-receipt SHA-256 is
`f0be51e0da7cc41176abdda57c52e202019579c1df3890e6ab7df18f8a1a1f46`,
its manifest SHA-256 is
`26b94b5e8ddc5e22618ad47faf1b388802dfa76354fd38f0a33a5c4c1a0eb8d2`,
and its release ID is
`sha256:fcee160ddb5e6ecedbca84811dea57993263507bbb8c38570b5243d5d7644ee5`.

Human-authored, non-draft [PR #6](https://github.com/tgilbert14/NEON-My-Little-Inverts/pull/6)
was opened at that exact head. This identity-bound takeaway stops at the
knowable candidate/PR-head fact; downstream check, merge, Pages, Connect, and
live-production status belongs only in `docs/BUILD-TEST-HANDOFF.md` and the
central Driver register.

## Prior safe-failure evidence

Run `30882432569` at former publication head
`c1bd68184f06c4a011806193ce511f367d92d1ea` remains safe failed history only.
It fetched at `2026-08-04T06:13:33Z`. Source artifact `8882105960` had API
digest
`sha256:485c05f2612bf810109c74004a29057ba38a7ae159ec749cd7403b8f8fc5bbe7`;
its raw RDS, fetch-evidence, and source-receipt SHA-256 values were respectively
`f471421791853c8a7047a4276c7b9ab5cf6b800b342af11ae8f7a22ac4f8f47e`,
`a8f98aa0d116d086da0ff05166152c93fb12f75c5ff41e55e90d8e9f47240c12`,
and `26fcb9193813440bbd69a349fde70b875347f1219a4474026c144618872a2ed1`.
Producer artifact `8882157880` had API digest
`sha256:a380395b4b12b846229d69189f23dd6fc73e11b960bafeb068cbefe4e2691761`,
inner release-tarball SHA-256
`7b2fe393709f673f17291245e597dee5faafd510f0f01073b009ad9f37eb201d`,
and release-contract SHA-256
`5f8ab8088957bf4c8dcf17b02292022ec3985cfabb5ab97a6e04963888002d1b`.
Those receipts bind only that failed attempt.

All of that run's source, science, producer, release, loaded-app, and candidate
checks passed, but the final full-UI source gate failed when `bsicons` 0.1.2
rejected nonexistent `scatter-chart`. Validated packaging, upload, and publisher
steps were skipped, and no candidate branch or PR was created. Fix head
`a685e01c61938fcbd49325d7cf365aa272fae58a` replaced it with valid
`graph-up`, added exact-package icon inventory/render regression, pinned the
exact `bsicons` source in early producer dependencies, and added an early
validator gate.

## Start with opportunities

The raw source contains 7,201 field rows, 6,446 per-sample rows, and 320,240
taxonomy rows. Three `.DNA` field rows at HOPB are metabarcoding material; their
three per-sample and 172 taxonomy rows remain in raw/QC authority but are outside
this morphology-based estimand. The result is an exact ledger of **7,198 field
opportunities at 34 sites**, dated 2014-07-01 through 2024-11-26.

The mutually exclusive displayed outcome partition reconciles exactly:

| Record status | Opportunities |
| --- | ---: |
| Unstratifiable | 719 |
| Nonstandard collection | 2 |
| Processing unknown | 34 |
| Count unavailable | 230 |
| Quantified community | 6,213 |
| All other primary statuses | 0 |
| **Total** | **7,198** |

The primary status does not erase overlapping evidence. Independent support
flags identify 713 sampling-impractical opportunities, eight nonstandard
collections, 719 incomplete exact grains, 34 unknown processing outcomes, and
237 taxonomy/count-unavailable outcomes.

## Processing is not detection

Among **6,485 sampling-practical opportunities**, the independent laboratory
outcome partition is:

| Processing/count outcome | Opportunities |
| --- | ---: |
| Processing unknown | 34 |
| Processed, no taxonomy table | 0 |
| Taxonomy present, count unavailable | 237 |
| Taxonomy/count available | 6,214 |
| **Total practical opportunities** | **6,485** |

That last 6,214 is not automatically the count denominator. One nonstandard,
unstratifiable record remains outside primary quantitative strata, leaving **6,213
count-eligible opportunities**. Unknown processing or count is not a reported
zero.

The receipt-bound source contains **zero reported-zero opportunities**. It does
contain one sample whose taxonomy `subsamplePercent` is displayed as zero while
the per-sample table reports 0.5%. All 53 affected taxonomy rows keep their
published values; the finite published `estimatedTotalCount` is treated as
authoritative and the anomaly is exposed as a separate support flag. It is not
converted into a zero catch.

## Exact strata and denominators

The ledger resolves to **830 events** and **1,679 exact event strata** at
`site × event × aquaticSiteType × habitatType × samplerType`. Of 7,198
opportunities:

- 6,477 enter a primary exact stratum;
- 6,213 are count eligible;
- 6,213 have positive usable benthic area and are density eligible; and
- 6,213 have a positive count and therefore enter composition summaries.

The equal count, density, and composition totals are a fact about this exact
source, not a rule. The contracts allow future releases to differ: missing area
would remove density eligibility without removing count, and a genuine reported
zero would stay in count support without entering composition.

## Taxonomy is mixed-rank evidence

The science build reports **181,922 collapsed taxonomy records** and produces
**85,874 positive search/taxon-by-stratum rows**. Those rows span 14 published
identification ranks:

| Rank | Taxon-stratum rows |
| --- | ---: |
| Genus | 47,156 |
| Family | 12,583 |
| Species | 8,591 |
| Species group | 6,538 |
| Other 10 retained ranks | 11,006 |
| **Total** | **85,874** |

Only 8,591 rows are identified at species rank. Therefore “taxa recorded” is a
mixed-rank support count, not species richness. EPT summaries are likewise
descriptive: 82,565 taxon-stratum rows have order classified and 19,871 are
classified to an EPT order; unknown-order positive counts remain in the
composition denominator.

Thirty-one raw taxonomy placeholders have no accepted taxon and no usable count.
Seven occur in samples that also contain count-valid taxa; 24 are the only
placeholder outcome for their sample. All remain explicit unknown outcomes and
none becomes a taxonomic zero.

## Source reconciliation worth keeping visible

- The basic package omits expanded-only slide identity. All 320,240 raw taxonomy
  rows have a nonblank unique `uid`; the release retains the omitted-field
  metadata and audited surrogate inventory rather than inventing slide keys.
- One auxiliary FLNT photo-identification per-sample row is retained in raw/QC
  evidence and quarantined from the canonical processing join.
- Eight nonstandard `GRAB`, `BRYOZOAN`, or `MACROALGAE` collections remain
  auditable; two take nonstandard collection as their primary status and the
  others overlap a higher-precedence status.
- Field, per-sample, taxonomy, and issue-log QC fields are retained as context.
  They do not automatically exclude records or change denominators.

## How to read the app honestly

- Expanded laboratory count is a sampled-record quantity, not population
  abundance.
- Collection density is a sampled-record quotient, not population density.
- Taxa recorded is mixed-rank support, not estimated richness.
- EPT share is descriptive, not a condition or water-quality score.
- Cross-site tables compare effort and record support only.
- Not detected is not absent, and missing is never rewritten as zero.
