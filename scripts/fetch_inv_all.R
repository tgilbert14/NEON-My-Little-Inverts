# ===========================================================================
# fetch_inv_all.R — pull the immutable RELEASE-2026 Macroinvertebrate
# collection source for all aquatic sites. Persist non-authoritative fetch
# evidence before contract validation, then issue the authoritative source
# receipt only after the complete source contract passes.
#
# Run from the repository root with exactly R 4.5.2 and neonUtilities 4.0.1:
#   Rscript --vanilla scripts/fetch_inv_all.R
# ===========================================================================

source("scripts/inv_source_contract.R", local = TRUE)

inv_persist_fetched_source <- function(source_data, artifact_path,
                                       evidence_path, receipt_path,
                                       fetched_at_utc, producer_git_sha) {
  inv_persist_fetch_evidence(
    source_data, artifact_path, evidence_path, producer_git_sha,
    fetched_at_utc
  )
  inv_verify_fetch_evidence(artifact_path, evidence_path)

  # Any failure below intentionally leaves only the raw artifact plus its
  # non-authoritative evidence receipt. No source receipt means no candidate.
  source_summary <- inv_validate_source(source_data)
  inv_persist_authoritative_source_receipt(
    source_data, artifact_path, receipt_path, producer_git_sha,
    fetched_at_utc
  )
  receipt <- inv_verify_fetch_source_handoff(
    artifact_path, evidence_path, receipt_path
  )$receipt
  invisible(list(summary = source_summary, receipt = receipt))
}

fetch_inv_all <- function() {
  inv_assert_fetch_runtime()
  producer_git_sha <- inv_assert_producer_git_sha(
    trimws(Sys.getenv("SOURCE_SHA", ""))
  )

  out_dir <- normalizePath(file.path("..", "inverts-data-fetch"), mustWork = FALSE)
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  artifact_path <- file.path(out_dir, INV_SOURCE_ARTIFACT_FILE)
  evidence_path <- file.path(out_dir, INV_FETCH_EVIDENCE_FILE)
  receipt_path <- file.path(out_dir, INV_SOURCE_RECEIPT_FILE)

  artifact_exists <- file.exists(artifact_path)
  evidence_exists <- file.exists(evidence_path)
  receipt_exists <- file.exists(receipt_path)
  if (artifact_exists || evidence_exists || receipt_exists) {
    inv_assert(artifact_exists && evidence_exists,
               paste0(
                 "Existing fetch evidence is incomplete: artifact=%s ",
                 "evidence=%s receipt=%s"
               ), artifact_exists, evidence_exists, receipt_exists)
    inv_verify_fetch_evidence(artifact_path, evidence_path)
    inv_assert(receipt_exists,
               paste0(
                 "Existing fetch is evidence-only and is not publication ",
                 "authorized: %s"
               ), evidence_path)
    inv_verify_fetch_source_handoff(artifact_path, evidence_path, receipt_path)
    cat(sprintf(
      "Verified existing raw evidence and authoritative receipt: %s\n",
      artifact_path
    ))
    return(invisible(artifact_path))
  }

  token <- trimws(Sys.getenv("NEON_TOKEN", ""))
  inv_assert(nzchar(token),
             "NEON_TOKEN is required; anonymous or workstation-path fallback is forbidden")

  cat(sprintf(
    "Fetching %s, all sites/all dates, package=%s, release=%s, provisional=%s...\n",
    INV_DPID, INV_QUERY_PACKAGE, INV_RELEASE, INV_INCLUDE_PROVISIONAL
  ))
  started <- Sys.time()
  source_data <- neonUtilities::loadByProduct(
    dpID = INV_DPID,
    site = "all",
    startdate = NA,
    enddate = NA,
    package = INV_QUERY_PACKAGE,
    tabl = "all",
    timeIndex = "all",
    cloud.mode = FALSE,
    release = INV_RELEASE,
    include.provisional = INV_INCLUDE_PROVISIONAL,
    check.size = FALSE,
    token = token,
    nCores = 1,
    forceParallel = FALSE,
    useFasttime = FALSE,
    progress = TRUE
  )

  fetched_at_utc <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  persisted <- inv_persist_fetched_source(
    source_data, artifact_path, evidence_path, receipt_path, fetched_at_utc,
    producer_git_sha
  )
  source_summary <- persisted$summary
  cat("Validated objects:", paste(source_summary$object_names, collapse = ", "), "\n")
  for (table_name in INV_REQUIRED_TABLES) {
    table <- source_data[[table_name]]
    cat(sprintf("  %-32s %7d rows x %d cols\n",
                table_name, nrow(table), ncol(table)))
  }

  receipt <- persisted$receipt
  cat(sprintf(
    "Saved and receipt-verified %s (%s; %.1f min)\n",
    artifact_path, receipt$artifact$sha256,
    as.numeric(difftime(Sys.time(), started, units = "mins"))
  ))
  invisible(artifact_path)
}

if (sys.nframe() == 0L) fetch_inv_all()
