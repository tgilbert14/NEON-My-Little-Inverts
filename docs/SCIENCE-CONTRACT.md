# My Little Inverts — scientific contract

## Purpose and estimand

My Little Inverts describes the released record of NEON aquatic
macroinvertebrate collection and laboratory processing. Its population of
opportunities is the non-metabarcoding portion of `inv_fieldData`; its biological
summaries are properties of collected and processed records. The app does not
estimate site populations, ecological condition, habitat quality, or absence.

The contract version for Pass 9 is `2.1.0`.

## Source authority

The only accepted source request is:

| Field | Required value |
| --- | --- |
| Product | `DP1.20120.001` |
| Product name | Macroinvertebrate collection |
| Release | `RELEASE-2026` |
| Provisional data | `false` |
| Package | `basic` |
| Site and time | all released sites and dates |
| DOI | `10.48443/hp56-s582` |

The fetch must retain the complete returned object family, embedded release
citation, table classes, field classes, schema metadata, and raw row inventories.
The immutable raw RDS SHA-256 and a validated source receipt bind all derived
files to that exact source. Fetch evidence alone carries
`publication_authorized=false` and cannot enter publication.

`variables_20120` may arrive as `data.table/data.frame`. Persisting a
`data.table` includes the process-local `.internal.selfref` external pointer, so
canonicalization may remove that attribute and only that attribute. Column
projection must use read-only `[[` extraction into a base-data-frame view; no
source object may be coerced or changed by reference.

## Opportunity ledger

1. Each non-`.DNA` `inv_fieldData` row becomes exactly one opportunity.
2. An opportunity remains present if collection was impractical, its exact
   comparison grain is incomplete, a per-sample record is absent, taxonomy is
   absent, or count is unavailable.
3. The `.DNA` family is retained in source/QC inventories but quarantined from
   this morphology-based collection estimand.
4. Every canonical per-sample processing record reconciles to exactly one
   practical field opportunity. A practical opportunity may legitimately lack a
   per-sample child; any taxonomy child must still reconcile to that field parent.
   One known auxiliary photo-identification per-sample row is retained in raw
   evidence and quarantined from science.
5. Every opportunity keeps primitive source evidence alongside derived booleans
   and status. Validators recompute the derived fields from those primitives.

### Mutually exclusive record status

Every opportunity has exactly one `record_status` under deterministic
precedence:

- `unstratifiable`
- `sampling_impractical`
- `nonstandard_collection`
- `processing_unknown`
- `processed_no_taxonomy`
- `count_unavailable`
- `area_unavailable`
- `density_unavailable`
- `reported_zero_count`
- `quantified_community`

The status is a display partition, not the only evidence. Sampling practicality,
nonstandard collection, grain completeness, count availability, area
availability, and reported-zero state also remain independent support flags.
Their totals may overlap the mutually exclusive partition.

For practical opportunities, `processing_count_status` independently partitions
the laboratory outcome into `processing_unknown`, `processed_no_taxonomy`,
`taxonomy_count_unavailable`, or `taxonomy_count_available`. This prevents an
unstratifiable collection flag from hiding what happened in processing.

## Comparison grain and eligibility

The quantitative comparison grain is exactly:

```text
site × event × aquaticSiteType × habitatType × samplerType
```

An opportunity enters a primary stratum only when those fields are recorded and
the collection is not one of the special-ID `GRAB`, `BRYOZOAN`, or `MACROALGAE`
records. Those records remain auditable as nonstandard collections.

Eligibility is metric-specific:

- **Count eligible:** exact grain complete and a finite, nonnegative published
  expanded-count result is available.
- **Composition eligible:** count eligible with a positive total expanded count.
  Reported-zero samples remain in the count denominator but do not manufacture a
  composition.
- **Density eligible:** count eligible plus a finite positive published benthic
  area. Sample density is the expanded-count total divided by that area.
- **Occurrence support:** a taxon is present only from a positive valid expanded
  count. Zero support is filled only across count-eligible processed samples in
  the same exact stratum.

Count and density eligibility must never be coupled. Missing area cannot erase a
count, and missing taxonomy/count cannot become an observed zero.

## Taxonomy reconciliation

- The basic package omits expanded-package slide identity. The source contract
  proves that raw taxonomy `uid` is nonblank and unique for all rows, retains the
  omitted-field metadata, and uses `uid` only as the audited row identity.
- All raw taxonomy rows remain in the source authority. Rows are collapsed only
  after exact sample reconciliation and only under the documented taxon identity.
- Rows without `acceptedTaxonID` and without a count remain explicit unresolved
  taxonomy/count outcomes. They never create a zero or an invented taxon.
- Identification rank remains attached to every derived taxon. A mixed-rank
  “taxa recorded” total is descriptive support, not species richness.
- EPT means a positive taxon record classified to Ephemeroptera, Plecoptera, or
  Trichoptera. Unknown-order positive counts remain in the composition
  denominator, and order-classification support is shown beside EPT share.
- A published taxonomy `subsamplePercent` displayed as zero is not rewritten.
  For the one receipt-bound affected sample, the finite published
  `estimatedTotalCount` is the authoritative count and the anomaly remains an
  explicit support flag.

## QC and issue evidence

The release retains, verbatim where available:

- field `dataQF`;
- per-sample `dataQF`, sorting-QC dates and values, sorter identity, PDE, and PTD;
- taxonomy `qcChecked` and `dataQF`; and
- the complete issue log plus deterministic site/date scope annotations.

These are contextual review evidence. They do not automatically exclude a row or
change metric eligibility. Any future exclusion rule requires a new science
contract version, denominator impact report, adversarial tests, and expert review.

## Cross-site and public-claim limits

The network view may compare only effort and record-support fields: opportunities,
events, exact strata, eligible samples, processing outcomes, QC support, and
mixed-rank taxon-record counts. It must not present density, expanded-count totals,
richness, EPT share, or another biological value as a raw site ranking.

Public labels and exports must keep the denominator and grain adjacent to every
metric. Required caveats are:

- expanded laboratory counts are not population abundance;
- collection density is not population density;
- taxa recorded is not estimated richness;
- EPT share is descriptive, not a condition score; and
- not detected is not absent.

## Acceptance invariants

A release is scientifically admissible only when independent validation proves:

- one ledger row per non-`.DNA` field opportunity and the exact 34-site roster;
- one exclusive record status per opportunity and one exclusive practical
  processing/count status;
- primitive-to-derived status, count, density, and zero-state equivalence;
- exact source/receipt/citation/schema/class identity;
- exact per-sample and taxonomy reconciliation, including all quarantines;
- taxon support and zero-fill remain within the exact stratum;
- bundle, index, demo, manifest, and production identities form one
  content-addressed release; and
- a second clean build from the same raw authority is byte-identical.

The executable authority is in `scripts/inv_source_contract.R`,
`scripts/inv_science_contract.R`, `scripts/inv_producer.R`, and
`scripts/inv_release_verifier.R`. This document explains those gates; it does not
override them.
