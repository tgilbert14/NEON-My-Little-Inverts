#!/usr/bin/env Rscript

# Rebuild the support-only site/cross-site indexes from hash-pinned committed
# Pass-9 bundles. Cross-site ecological density/richness rankings are forbidden.

source("scripts/inv_producer.R", local = TRUE)
index <- inv_rebuild_derived_from_bundles(".", build_search = FALSE)
cat(sprintf("Rebuilt support-only site_index + cross_site for %d sites.\n",
            nrow(index)))
