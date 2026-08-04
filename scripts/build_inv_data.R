#!/usr/bin/env Rscript

# Build the deterministic Pass-9 release from the exact raw RELEASE-2026 source
# and its immutable receipt. No taxonomy-first joins or unsupported estimators.

source("scripts/inv_producer.R", local = TRUE)

artifact_path <- Sys.getenv(
  "INV_SOURCE_RDS", "../inverts-data-fetch/DP1.20120.001_all.rds"
)
receipt_path <- Sys.getenv(
  "INV_SOURCE_RECEIPT",
  "../inverts-data-fetch/DP1.20120.001_source_receipt.json"
)
output_root <- Sys.getenv("INV_OUTPUT_ROOT", ".")

inv_produce_verified_release(artifact_path, receipt_path, output_root)
