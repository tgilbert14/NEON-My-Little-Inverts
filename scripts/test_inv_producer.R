#!/usr/bin/env Rscript

source("scripts/inv_producer.R", local = TRUE)
source("scripts/inv_release_verifier.R", local = TRUE)

checks <- 0L
FIXTURE_GIT_SHA <- paste(rep("b", 40L), collapse = "")

expect_true <- function(value, label) {
  checks <<- checks + 1L
  if (!isTRUE(value)) stop(sprintf("Check failed: %s", label), call. = FALSE)
}

expect_error <- function(expr, pattern, label) {
  checks <<- checks + 1L
  message_text <- tryCatch({ force(expr); NA_character_ },
                           error = function(error) conditionMessage(error))
  if (is.na(message_text) || !grepl(pattern, message_text, perl = TRUE)) {
    stop(sprintf("Check failed: %s; expected /%s/, got %s",
                 label, pattern, message_text), call. = FALSE)
  }
}

expect_true(
  identical(
    inv_producer_dates(c(
      "20251204T230818Z", "2025-12-05T00:09:25Z", "2025-12-06"
    )),
    as.Date(c("2025-12-04", "2025-12-05", "2025-12-06"))
  ),
  paste(
    "exact compact UTC, canonical ISO UTC, and intentional date-only",
    "publicationDate values parse to their UTC calendar date"
  )
)
expect_true(
  all(is.na(inv_producer_dates(c(
    "2025-12-04T23:08:18Z trailing",
    "2025-12-04T24:00:00Z",
    "2025-12-04T23:60:00Z",
    "2025-12-04T23:08:60Z",
    "2025-02-29T23:08:18Z",
    "20250229T230818Z",
    "2025-02-29",
    "2025-12-04 23:08:18",
    "2025-12-04T23:08:18+00:00",
    "not-a-date",
    NA_character_
  )))),
  "malformed, non-UTC, noncanonical, and calendar-invalid values fail closed"
)
expect_true(
  all(is.na(inv_producer_dates(c(20251204, 20251205)))),
  "numeric publication encodings fail closed instead of becoming calendar dates"
)
expect_true(
  all(is.na(inv_producer_dates(structure(c(Inf, 1.5), class = "Date")))) &&
    all(is.na(inv_producer_dates(structure(
      Inf, class = c("POSIXct", "POSIXt"), tzone = "UTC"
    )))) &&
    all(is.na(inv_producer_dates(as.POSIXlt(
      structure(
        Inf, class = c("POSIXct", "POSIXt"),
        tzone = "America/New_York"
      ),
      tz = "America/New_York"
    )))),
  paste(
    "nonfinite and fractional class-backed publication values, including",
    "non-UTC POSIXlt values, fail closed"
  )
)
expect_true(
  identical(inv_producer_dates(as.Date(c("2025-12-04", "2025-12-05"))),
            as.Date(c("2025-12-04", "2025-12-05"))) &&
    identical(
      inv_producer_dates(as.POSIXct(
        c("2025-12-04 23:59:59", "2025-12-05 00:00:01"), tz = "UTC"
      )),
      as.Date(c("2025-12-04", "2025-12-05"))
  ),
  "Date and POSIX publication stamps retain explicit UTC date semantics"
)
non_utc_posixlt <- as.POSIXlt(
  as.POSIXct("2025-12-04 23:30:00", tz = "America/New_York"),
  tz = "America/New_York"
)
expect_true(
  identical(inv_producer_dates(non_utc_posixlt), as.Date("2025-12-05")),
  paste(
    "non-UTC POSIXlt publication stamps preserve their instant before",
    "UTC calendar-day projection"
  )
)
# Reuse the source-contract fixture without coupling the producer to its tests.
fixture_env <- new.env(parent = globalenv())
invisible(capture.output(sys.source("scripts/test_inv_source_contract.R",
                                    envir = fixture_env)))
source_fixture <- fixture_env$valid
INV_SYNTHETIC_FIXTURE_MODE <- TRUE
INV_TAXONOMY_COLLISION_EXPECTATION <-
  fixture_env$INV_TAXONOMY_COLLISION_EXPECTATION
INV_DNA_FAMILY_EXPECTATION <- fixture_env$INV_DNA_FAMILY_EXPECTATION
INV_SAMPLE_IDENTITY_EXPECTATION <- fixture_env$INV_SAMPLE_IDENTITY_EXPECTATION
INV_UNRESOLVED_TAXONOMY_EXPECTATION <-
  fixture_env$INV_UNRESOLVED_TAXONOMY_EXPECTATION

compact_publication_source <- source_fixture
for (table_name in INV_REQUIRED_TABLES) {
  compact_publication_source[[table_name]]$publicationDate <- rep(
    "20251206T143059Z", nrow(compact_publication_source[[table_name]])
  )
}
expect_true(
  identical(
    inv_producer_publication_stamp(compact_publication_source), "2025-12-06"
  ),
  "producer derives the publication stamp from the production compact UTC form"
)
for (table_name in INV_REQUIRED_TABLES) {
  mixed_publication_source <- source_fixture
  mixed_publication_source[[table_name]]$publicationDate[[2L]] <-
    "2025-12-04T23:08:18Z trailing"
  expect_error(
    inv_producer_publication_stamp(mixed_publication_source),
    sprintf("unparseable publicationDate in %s", table_name),
    sprintf(
      "producer stamp rejects one malformed value among valid %s dates",
      table_name
    )
  )
}
numeric_publication_source <- source_fixture
numeric_publication_source$inv_fieldData$publicationDate <- rep(
  20251204, nrow(numeric_publication_source$inv_fieldData)
)
expect_error(
  inv_producer_publication_stamp(numeric_publication_source),
  "unparseable publicationDate in inv_fieldData",
  "producer stamp rejects numeric publication encodings before taking a maximum"
)

temp_root <- tempfile("inv-producer-fixture-")
dir.create(temp_root)
on.exit(unlink(temp_root, recursive = TRUE, force = TRUE), add = TRUE)
source_dir <- file.path(temp_root, "source")
dir.create(source_dir)
artifact_path <- file.path(source_dir, "DP1.20120.001_all.rds")
receipt_path <- file.path(source_dir, "DP1.20120.001_source_receipt.json")
inv_persist_source(
  source_fixture, artifact_path, receipt_path, FIXTURE_GIT_SHA,
  fetched_at_utc = "2026-07-15T12:00:00Z"
)

drift_source <- source_fixture
drift_row <- drift_source$variables_20120$table == "inv_fieldData" &
  drift_source$variables_20120$fieldName == "benthicArea"
drift_source$variables_20120$units[drift_row] <- "squareCentimeter"
drift_dir <- file.path(temp_root, "evidence-only-drift")
dir.create(drift_dir)
drift_artifact <- file.path(drift_dir, INV_SOURCE_ARTIFACT_FILE)
drift_evidence <- file.path(drift_dir, INV_FETCH_EVIDENCE_FILE)
inv_persist_fetch_evidence(
  drift_source, drift_artifact, drift_evidence, FIXTURE_GIT_SHA,
  fetched_at_utc = "2026-07-15T12:00:00Z"
)
drift_candidate <- file.path(temp_root, "forbidden-drift-candidate")
dir.create(drift_candidate)
expect_error(
  inv_produce_verified_release(
    drift_artifact, drift_evidence, drift_candidate
  ),
  "Source receipt schema version",
  "non-authoritative fetch evidence can never authorize a producer candidate"
)
expect_true(
  !file.exists(file.path(drift_candidate, "data", "release_contract.rds")) &&
    !dir.exists(file.path(drift_candidate, "data", "sites")),
  "schema drift leaves no partial release candidate"
)

out_a <- file.path(temp_root, "release-a")
out_b <- file.path(temp_root, "release-b")
dir.create(out_a)
dir.create(out_b)
inv_produce_verified_release(artifact_path, receipt_path, out_a)
inv_produce_verified_release(artifact_path, receipt_path, out_b)

summary <- inv_verify_release_data(out_a)
raw_summary <- inv_verify_release_against_source(
  out_a, artifact_path, receipt_path, production_exact = FALSE
)
expect_true(identical(summary$sites, 34L),
            "producer and independent verifier retain all 34 sites")
expect_true(identical(summary$opportunities, 35L),
            "field-first producer retains practical and impractical opportunities")
expect_true(identical(summary$count_samples, 1L) &&
              identical(summary$density_samples, 1L),
            "verified fixture exposes exact count and density denominators")
expect_true(identical(raw_summary$opportunities, 35L) &&
              identical(raw_summary$taxon_strata, 1L),
            "independent raw-source reconciliation binds source to release")

files_a <- sort(list.files(out_a, recursive = TRUE))
files_b <- sort(list.files(out_b, recursive = TRUE))
expect_true(identical(files_a, files_b),
            "repeated production emits the same release inventory")
hash_a <- vapply(file.path(out_a, files_a), inv_release_sha256, character(1))
hash_b <- vapply(file.path(out_b, files_b), inv_release_sha256, character(1))
expect_true(identical(unname(hash_a), unname(hash_b)),
            "repeated production is byte deterministic")

syca <- readRDS(file.path(out_a, "data", "sites", "SYCA.rds"))
arik <- readRDS(file.path(out_a, "data", "sites", "ARIK.rds"))
expect_true(identical(names(syca), c(
  "schema_version", "opportunities", "event_strata", "taxon_strata",
  "site_summary", "meta", "metric_contract", "qc", "provenance"
)), "site bundle has the exact Pass-9 schema")
expect_true(nrow(arik$opportunities) == 1L && nrow(arik$taxon_strata) == 0L,
            "taxonomy absence never removes an impractical field opportunity")
expect_true(isTRUE(arik$qc$reconciliation$opportunity_complete),
            "bundle QC attests field-first opportunity reconciliation")
expect_true(identical(syca$provenance$source$artifact_sha256,
                      summary$artifact_sha256),
            "bundle provenance carries the verified raw artifact identity")
expect_true(identical(syca$provenance$source$producer_git_sha,
                      FIXTURE_GIT_SHA),
            "bundle and release contract bind the exact fetching revision")
expect_true(identical(syca$provenance$source$receipt_sha256,
                      inv_release_sha256(file.path(out_a, "data", "source_receipt.json"))),
            "bundle provenance carries the published source-receipt identity")
expect_true(isTRUE(syca$qc$contract$retain_verbatim) &&
              identical(syca$qc$contract$automatic_exclusion, FALSE) &&
              identical(syca$qc$reconciliation$qc_alters_metric_eligibility,
                        FALSE),
            "official vF QC is audit evidence and never an eligibility filter")
source_syca_field <- source_fixture$inv_fieldData[
  source_fixture$inv_fieldData$siteID == "SYCA", , drop = FALSE
]
expect_true(identical(syca$qc$source_quality$field$dataQF,
                      source_syca_field$dataQF),
            "field dataQF values are retained verbatim, including .DNA evidence")
expect_true(all(vapply(INV_VF_QC_COLUMNS$inv_persample, function(field) {
  identical(syca$qc$source_quality$per_sample[[field]],
            source_fixture$inv_persample[[field]])
}, logical(1))), "per-sample vF QC values are retained verbatim")
expect_true(all(vapply(INV_VF_QC_COLUMNS$inv_taxonomyProcessed,
                       function(field) {
  identical(syca$qc$source_quality$taxonomy_processed[[field]],
            source_fixture$inv_taxonomyProcessed[[field]])
}, logical(1))), "taxonomy vF QC values are retained verbatim")
expect_true(identical(
  syca$qc$issue_log[INV_ISSUE_LOG_COLUMNS],
  source_fixture$issueLog_20120[INV_ISSUE_LOG_COLUMNS]
) && identical(
  arik$qc$issue_log[INV_ISSUE_LOG_COLUMNS],
  source_fixture$issueLog_20120[INV_ISSUE_LOG_COLUMNS]
), "every bundle retains the full verbatim global issue log")
expect_true(
  identical(syca$qc$issue_log$site_scope_basis, "explicit_site_match") &&
    isTRUE(syca$qc$issue_log$date_overlap) &&
    identical(arik$qc$issue_log$site_scope_basis,
              "not_machine_resolved") &&
    is.na(arik$qc$issue_log$site_scope_match),
  "issue applicability is annotated by site/date without filtering evidence"
)
site_index <- readRDS(file.path(out_a, "data", "site_index.rds"))
expect_true(identical(as.integer(site_index$n_unstratifiable),
                      rep(0L, nrow(site_index))),
            "site support index carries the explicit unstratifiable count")
expect_true(!any(grepl("density_m2|richness|chao|raref|health",
                       names(site_index), ignore.case = TRUE)),
            "network index is support-only and has no ecological rank fields")

masked_analysis <- inv_prepare_analysis_source(source_fixture)$source
masked_analysis$inv_fieldData$habitatType[
  masked_analysis$inv_fieldData$sampleID %in% "SYCA.INV.S1"
] <- NA_character_
masked_analysis$inv_taxonomyProcessed <-
  masked_analysis$inv_taxonomyProcessed[
    !masked_analysis$inv_taxonomyProcessed$sampleID %in% "SYCA.INV.S1",
    , drop = FALSE
  ]
masked_science <- build_inv_science_contract(masked_analysis)
masked_syca <- syca
masked_syca$opportunities <- masked_science$opportunities[
  masked_science$opportunities$siteID == "SYCA", , drop = FALSE
]
masked_syca$site_summary <- masked_science$site_summary[
  masked_science$site_summary$siteID == "SYCA", , drop = FALSE
]
masked_index <- inv_producer_site_index(list(SYCA = masked_syca))
expect_true(
  identical(masked_syca$site_summary$n_processed_no_taxonomy, 1L) &&
    sum(masked_syca$opportunities$record_status ==
          "processed_no_taxonomy") == 0L &&
    identical(masked_index$n_processed_no_taxonomy, 1L),
  paste(
    "producer site index derives processed-without-taxonomy from the exclusive",
    "processing outcome even when primary status is unstratifiable"
  )
)

search <- readRDS(file.path(out_a, "data", "search_index.rds"))
expect_true(!any(grepl("density|chao|raref|health", names(search$taxa),
                       ignore.case = TRUE)),
            "taxon search retains exact support grain without density ranking")
expect_true(all(c("eventID", "aquaticSiteType", "habitatType", "samplerType",
                  "n_count_eligible_samples", "support_pct") %in%
                names(search$taxa)),
            "taxon search exposes exact method grain and support denominator")

unstratifiable_source <- source_fixture
arik_row <- which(unstratifiable_source$inv_fieldData$siteID == "ARIK" &
                    !grepl("[.]DNA$", unstratifiable_source$inv_fieldData$sampleID))
unstratifiable_source$inv_fieldData$habitatType[arik_row] <- NA_character_
unstratifiable_artifact <- file.path(source_dir, "unstratifiable.rds")
unstratifiable_receipt <- file.path(source_dir, "unstratifiable-receipt.json")
inv_persist_source(
  unstratifiable_source, unstratifiable_artifact, unstratifiable_receipt,
  FIXTURE_GIT_SHA,
  fetched_at_utc = "2026-07-15T12:00:00Z"
)
unstratifiable_root <- file.path(temp_root, "unstratifiable-release")
dir.create(unstratifiable_root)
inv_produce_verified_release(
  unstratifiable_artifact, unstratifiable_receipt, unstratifiable_root
)
unstratifiable_summary <- inv_verify_release_data(unstratifiable_root)
unstratifiable_index <- readRDS(file.path(
  unstratifiable_root, "data", "site_index.rds"
))
unstratifiable_arik <- readRDS(file.path(
  unstratifiable_root, "data", "sites", "ARIK.rds"
))
expect_true(
  identical(unstratifiable_summary$unstratifiable, 1L) &&
    identical(unstratifiable_index$n_unstratifiable[
      unstratifiable_index$site == "ARIK"
    ], 1L) &&
    identical(unstratifiable_index$n_sampling_impractical[
      unstratifiable_index$site == "ARIK"
    ], 1L) &&
    identical(unstratifiable_arik$meta$n_opportunities, 1L) &&
    identical(unstratifiable_arik$qc$reconciliation$unstratifiable, 1L) &&
    identical(unstratifiable_arik$opportunities$record_status,
              "unstratifiable"),
  paste(
    "impractical/unstratifiable overlap retains both marginal counts under",
    "the explicit unstratifiable record status"
  )
)

zero_without_area_source <- source_fixture
syca_collection <- zero_without_area_source$inv_fieldData$siteID == "SYCA" &
  !grepl("[.]DNA$", zero_without_area_source$inv_fieldData$sampleID)
zero_without_area_source$inv_fieldData$benthicArea[syca_collection] <- NA_real_
non_dna_taxonomy <- !grepl(
  "[.]DNA$", zero_without_area_source$inv_taxonomyProcessed$sampleID
)
zero_without_area_source$inv_taxonomyProcessed$estimatedTotalCount[
  non_dna_taxonomy
] <- 0
zero_without_area_source$inv_taxonomyProcessed$individualCount[
  non_dna_taxonomy
] <- 0
zero_without_area_artifact <- file.path(source_dir, "zero-without-area.rds")
zero_without_area_receipt <- file.path(
  source_dir, "zero-without-area-receipt.json"
)
inv_persist_source(
  zero_without_area_source, zero_without_area_artifact,
  zero_without_area_receipt, FIXTURE_GIT_SHA,
  fetched_at_utc = "2026-07-15T12:00:00Z"
)
zero_without_area_root <- file.path(temp_root, "zero-without-area-release")
dir.create(zero_without_area_root)
inv_produce_verified_release(
  zero_without_area_artifact, zero_without_area_receipt,
  zero_without_area_root
)
inv_verify_release_against_source(
  zero_without_area_root, zero_without_area_artifact,
  zero_without_area_receipt, production_exact = FALSE
)
zero_index <- readRDS(file.path(
  zero_without_area_root, "data", "site_index.rds"
))
zero_syca <- readRDS(file.path(
  zero_without_area_root, "data", "sites", "SYCA.rds"
))
zero_status <- stats::setNames(zero_syca$qc$status_counts$n,
                               zero_syca$qc$status_counts$record_status)
expect_true(
  identical(zero_index$n_reported_zero_count[zero_index$site == "SYCA"], 1L) &&
    identical(zero_syca$meta$n_reported_zero_count, 1L) &&
    identical(unname(zero_status[["area_unavailable"]]), 1L) &&
    identical(unname(zero_status[["reported_zero_count"]]), 0L),
  paste(
    "reported zero without area remains a marginal zero while processing",
    "status records area unavailability"
  )
)

empty_issue_source <- source_fixture
empty_issue_source$issueLog_20120 <-
  empty_issue_source$issueLog_20120[FALSE, , drop = FALSE]
empty_issue_artifact <- file.path(source_dir, "empty-issue-log.rds")
empty_issue_receipt <- file.path(source_dir, "empty-issue-log-receipt.json")
inv_persist_source(
  empty_issue_source, empty_issue_artifact, empty_issue_receipt,
  FIXTURE_GIT_SHA,
  fetched_at_utc = "2026-07-15T12:00:00Z"
)
empty_issue_root <- file.path(temp_root, "empty-issue-log-release")
dir.create(empty_issue_root)
inv_produce_verified_release(
  empty_issue_artifact, empty_issue_receipt, empty_issue_root
)
empty_issue_summary <- inv_verify_release_data(empty_issue_root)
empty_issue_syca <- readRDS(file.path(
  empty_issue_root, "data", "sites", "SYCA.rds"
))
expect_true(
  identical(empty_issue_summary$sites, 34L) &&
    nrow(empty_issue_syca$qc$issue_log) == 0L &&
    all(c(INV_ISSUE_LOG_COLUMNS,
          empty_issue_syca$qc$contract$issue_annotation_fields) %in%
        names(empty_issue_syca$qc$issue_log)),
  "typed empty issue logs retain the complete raw and annotation schema"
)

before <- vapply(c(
  file.path(out_a, "data", "site_index.rds"),
  file.path(out_a, "data", "cross_site.rds"),
  file.path(out_a, "data", "search_index.rds"),
  file.path(out_a, "data-sample", "demo.rds")
), inv_release_sha256, character(1))
inv_rebuild_derived_from_bundles(out_a, build_search = TRUE)
after <- vapply(names(before), inv_release_sha256, character(1))
expect_true(identical(unname(before), unname(after)),
            "bundle-only derived rebuild is byte deterministic")

# Independent verifier must reject a field opportunity dropped even when an
# attacker rewrites the bundle hash in the release contract.
bad_root <- file.path(temp_root, "bad-opportunity")
dir.create(bad_root)
invisible(file.copy(
  list.files(out_a, full.names = TRUE, all.files = TRUE, no.. = TRUE),
  bad_root, recursive = TRUE
))
bad_path <- file.path(bad_root, "data", "sites", "ARIK.rds")
bad_bundle <- readRDS(bad_path)
bad_bundle$opportunities <- bad_bundle$opportunities[FALSE, , drop = FALSE]
inv_producer_save_rds(bad_bundle, bad_path)
bad_contract_path <- file.path(bad_root, "data", "release_contract.rds")
bad_contract <- readRDS(bad_contract_path)
bad_contract$bundle_sha256[["ARIK"]] <- inv_release_sha256(bad_path)
inv_producer_save_rds(bad_contract, bad_contract_path)
expect_error(inv_verify_release_data(bad_root),
             "opportunity ledger is empty|do not reconcile to source",
             "independent verifier rejects taxonomy-conditioned opportunity loss")

bad_root <- file.path(temp_root, "bad-qc-evidence")
dir.create(bad_root)
invisible(file.copy(
  list.files(out_a, full.names = TRUE, all.files = TRUE, no.. = TRUE),
  bad_root, recursive = TRUE
))
bad_path <- file.path(bad_root, "data", "sites", "SYCA.rds")
bad_bundle <- readRDS(bad_path)
bad_bundle$qc$source_quality$field$dataQF <- NULL
inv_producer_save_rds(bad_bundle, bad_path)
bad_contract_path <- file.path(bad_root, "data", "release_contract.rds")
bad_contract <- readRDS(bad_contract_path)
bad_contract$bundle_sha256[["SYCA"]] <- inv_release_sha256(bad_path)
inv_producer_save_rds(bad_contract, bad_contract_path)
expect_error(inv_verify_release_data(bad_root), "field QC lacks required columns",
             "independent verifier rejects stripped official vF QC evidence")

bad_root <- file.path(temp_root, "bad-ranking")
dir.create(bad_root)
invisible(file.copy(
  list.files(out_a, full.names = TRUE, all.files = TRUE, no.. = TRUE),
  bad_root, recursive = TRUE
))
bad_index_path <- file.path(bad_root, "data", "site_index.rds")
bad_index <- readRDS(bad_index_path)
bad_index$density_m2 <- seq_len(nrow(bad_index))
inv_producer_save_rds(bad_index, bad_index_path)
inv_producer_save_rds(bad_index, file.path(bad_root, "data", "cross_site.rds"))
expect_error(inv_verify_release_data(bad_root),
             "Site-index columns differ from the exact support schema",
             "independent verifier rejects raw-density cross-site ranking")

cat(sprintf("Inverts producer/verifier fixtures passed (%d checks).\n", checks))
