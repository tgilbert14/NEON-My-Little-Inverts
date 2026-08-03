#!/usr/bin/env Rscript

# Adversarial contract tests for the independent release verifier. The producer
# is used only to generate and rewrite fixtures; inv_release_verifier.R itself
# remains independent of both producer and science-transform implementations.

source("scripts/inv_producer.R", local = TRUE)
source("scripts/inv_release_verifier.R", local = TRUE)

checks <- 0L
FIXTURE_GIT_SHA <- paste(rep("c", 40L), collapse = "")

expect_true <- function(value, label) {
  checks <<- checks + 1L
  if (!isTRUE(value)) stop(sprintf("Check failed: %s", label), call. = FALSE)
  invisible(value)
}

expect_error <- function(expr, pattern, label) {
  checks <<- checks + 1L
  message_text <- tryCatch({ force(expr); NA_character_ },
                           error = function(error) conditionMessage(error))
  if (is.na(message_text) || !grepl(pattern, message_text, perl = TRUE)) {
    stop(sprintf("Check failed: %s; expected /%s/, got %s",
                 label, pattern, message_text), call. = FALSE)
  }
  invisible(message_text)
}

fixture_env <- new.env(parent = globalenv())
invisible(capture.output(sys.source("scripts/test_inv_source_contract.R",
                                    envir = fixture_env)))
source_fixture <- fixture_env$valid

temp_root <- tempfile("inv-verifier-adversarial-")
dir.create(temp_root)
on.exit(unlink(temp_root, recursive = TRUE, force = TRUE), add = TRUE)
source_dir <- file.path(temp_root, "source")
release_root <- file.path(temp_root, "release")
dir.create(source_dir)
dir.create(release_root)
artifact_path <- file.path(source_dir, "DP1.20120.001_all.rds")
receipt_path <- file.path(source_dir, "DP1.20120.001_source_receipt.json")
inv_persist_source(source_fixture, artifact_path, receipt_path,
                   FIXTURE_GIT_SHA,
                   fetched_at_utc = "2026-07-15T12:00:00Z")
inv_produce_verified_release(artifact_path, receipt_path, release_root)

base_summary <- inv_verify_release_data(release_root)
raw_summary <- inv_verify_release_against_source(
  release_root, artifact_path, receipt_path
)
expect_true(identical(base_summary$sites, 34L) &&
              identical(raw_summary$opportunities, 35L),
            "untampered bundle and raw source pass independent verification")

copy_release <- function(label) {
  target <- file.path(temp_root, label)
  dir.create(target)
  members <- list.files(release_root, all.files = TRUE, no.. = TRUE,
                        full.names = TRUE)
  copied <- file.copy(members, target, recursive = TRUE)
  if (!all(copied)) stop("Could not copy adversarial fixture", call. = FALSE)
  target
}

bad_lineage <- copy_release("bad-lineage")
bad_lineage_contract_path <- file.path(
  bad_lineage, "data", "release_contract.rds"
)
bad_lineage_contract <- readRDS(bad_lineage_contract_path)
bad_lineage_contract$source$producer_git_sha <-
  paste(rep("d", 40L), collapse = "")
inv_producer_save_rds(bad_lineage_contract, bad_lineage_contract_path)
expect_error(
  inv_verify_release_data(bad_lineage),
  "exact non-provisional RELEASE-2026 source",
  "release contract must preserve the receipt-bound fetching revision"
)

rewrite_bundle <- function(label, site, mutate) {
  target <- copy_release(label)
  bundle_path <- file.path(target, "data", "sites", paste0(site, ".rds"))
  bundle <- mutate(readRDS(bundle_path))
  inv_producer_save_rds(bundle, bundle_path)
  contract_path <- file.path(target, "data", "release_contract.rds")
  contract <- readRDS(contract_path)
  contract$bundle_sha256[[site]] <- inv_release_sha256(bundle_path)
  inv_producer_save_rds(contract, contract_path)
  inv_rebuild_derived_from_bundles(target, build_search = TRUE)
  target
}

# Rewriting producer-owned hashes and summaries must not make a deleted taxon
# projection acceptable when opportunity totals still prove the row existed.
bad_taxa <- rewrite_bundle("bad-taxa", "SYCA", function(bundle) {
  bundle$taxon_strata <- bundle$taxon_strata[FALSE, , drop = FALSE]
  bundle$site_summary$n_taxa_recorded <- 0L
  bundle$site_summary$taxonomic_ranks <- ""
  bundle$meta$n_taxa_recorded <- 0L
  bundle$meta$taxonomic_ranks <- ""
  bundle
})
expect_error(
  inv_verify_release_data(bad_taxa),
  "taxon totals do not reconcile|taxon presence support does not reconcile",
  "deleted taxon strata fail bundle-only arithmetic reconciliation"
)

# Self-consistent edits across every derived index still have to equal the
# independently recomputed support table from site bundles.
bad_index <- copy_release("bad-index")
for (name in c("site_index.rds", "cross_site.rds")) {
  path <- file.path(bad_index, "data", name)
  index <- readRDS(path)
  row <- index$site == "ARIK"
  index$n_events[row] <- 999L
  index$n_composition_samples[row] <- 999L
  inv_producer_save_rds(index, path)
}
search_path <- file.path(bad_index, "data", "search_index.rds")
search <- readRDS(search_path)
row <- search$sites$site == "ARIK"
search$sites$n_events[row] <- 999L
search$sites$n_composition_samples[row] <- 999L
inv_producer_save_rds(search, search_path)
expect_error(inv_verify_release_data(bad_index), "site index differs",
             "coordinated index inflation fails exact bundle reconciliation")

bad_search <- copy_release("bad-search")
search_path <- file.path(bad_search, "data", "search_index.rds")
search <- readRDS(search_path)
search$taxa <- search$taxa[-1L, , drop = FALSE]
inv_producer_save_rds(search, search_path)
expect_error(inv_verify_release_data(bad_search), "search taxon index differs",
             "search taxonomy projection must equal site-bundle taxa")

bad_summary <- rewrite_bundle("bad-summary", "SYCA", function(bundle) {
  bundle$site_summary$collectDate_min <- "1900-01-01"
  bundle$meta$collectDate_min <- "1900-01-01"
  bundle
})
expect_error(inv_verify_release_data(bad_summary), "site summary differs",
             "site summary dates are recomputed from opportunities")

# Bundle-only arithmetic intentionally cannot prove verbatim raw identity. The
# separately downloaded, receipt-bound artifact supplies that final comparison.
bad_identity <- rewrite_bundle("bad-identity", "SYCA", function(bundle) {
  bundle$opportunities$sampleNumber[[1L]] <- "tampered"
  bundle
})
expect_true(identical(inv_verify_release_data(bad_identity)$sites, 34L),
            "identity-only tamper remains arithmetically self-consistent")
expect_error(
  inv_verify_release_against_source(bad_identity, artifact_path, receipt_path),
  "raw-to-bundle opportunity identity differs",
  "raw-source handoff detects a bundle identity tamper"
)

tampered_artifact <- file.path(source_dir, "tampered-source.rds")
tampered_source <- readRDS(artifact_path)
tampered_source$inv_fieldData$sampleNumber[[1L]] <- "tampered"
inv_producer_save_rds(tampered_source, tampered_artifact)
expect_error(
  inv_verify_release_against_source(
    release_root, tampered_artifact, receipt_path
  ),
  "Raw source hash differs",
  "downloaded raw bytes must match the immutable source receipt"
)

cat(sprintf("Inverts adversarial release-verifier fixtures passed (%d checks).\n",
            checks))
