#!/usr/bin/env Rscript

# Rebuild the exact-stratum taxon search index from hash-pinned Pass-9 bundles.
# The index retains support denominators and deliberately omits raw density ranks.

source("scripts/inv_producer.R", local = TRUE)
index <- inv_rebuild_derived_from_bundles(".", build_search = TRUE)
search <- readRDS("data/search_index.rds")
cat(sprintf(
  "Built exact-stratum search index: %d taxon rows across %d support-only sites.\n",
  nrow(search$taxa), nrow(index)
))
