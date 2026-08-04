# NEON My Little Inverts — Pass-9 data reading guide

This document deliberately carries no numeric ecological headline from the
legacy bundle family. Pass 9 changes the analytical frame from a taxonomy-first
set of positive records to a field-first opportunity ledger. Numeric takeaways
must be recomputed from the exact reviewed `RELEASE-2026` candidate and its
source receipt before they can be published here.

## What is safe to read now

The source and science contracts establish these structural facts:

- Every non-metabarcoding `inv_fieldData` row is retained as one opportunity.
- Every opportunity has one mutually exclusive primary processing status.
  Sampling-impractical, unstratifiable, nonstandard-collection, and
  reported-zero conditions are also retained as support flags because they can
  overlap another primary status.
- `.DNA` rows are inventoried as metabarcoding material, not silently mixed into
  collection summaries.
- `GRAB`, `BRYOZOAN`, and `MACROALGAE` special-ID records remain auditable but
  sit outside primary quantitative strata.
- Count and density have different denominators. A missing benthic area can
  prevent a density calculation without erasing the count record.
- Every quantitative event row retains
  `site × event × aquaticSiteType × habitatType × samplerType`.
- Taxon support is zero-filled only across count-valid processed samples in the
  same exact stratum. Processed samples with taxonomy unavailable remain
  unknown.
- Identification rank stays attached to each taxon. Site-level “taxa recorded”
  can contain mixed ranks.
- EPT summaries are descriptive, keep unknown-order positive counts in the
  denominator, and carry order-classification support beside the result.
- The network table contains effort and record counts only. It is not a raw
  biological ranking.

## What the fresh-candidate audit must report

After the full manual refresh succeeds, recompute and review:

1. Source receipt, exact release, provisional setting, publication cutoff,
   artifact SHA-256, and required-table row counts.
2. Opportunity reconciliation overall and by site, including the complete
   mutually exclusive status ledger.
3. Primary-stratum, count, positive-total composition, and density denominators
   by site and exact event stratum.
4. `.DNA` inventories and boolean-derived nonstandard-collection,
   unstratifiable, sampling-impractical, and reported-zero support counts.
5. Mixed identification ranks and order-classification support.
6. Contextual source-quality inventories for field, per-sample, taxonomy, and
   issue-log layers. These fields are retained evidence and do not automatically
   exclude records.
7. Candidate bundle hashes, deterministic rebuild evidence, and exact-head
   validator receipts.

Only after those checks should this file gain numeric summaries. Any future
headline must name its denominator and grain next to the value; missing and
unknown values must never be rewritten as zero.
