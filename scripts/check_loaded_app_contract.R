#!/usr/bin/env Rscript

# Static and fixture checks for the Pass-9 loaded experience. Kept under scripts
# so Shiny never auto-sources this executable test in production. This deliberately
# does not source global.R or start Shiny, so it runs in the lean producer gate.

fail <- function(...) stop(sprintf(...), call. = FALSE)
checks <- 0L
expect <- function(ok, message) {
  checks <<- checks + 1L
  if (!isTRUE(ok)) fail("Loaded-app contract check failed: %s", message)
}

root <- if (file.exists("ui.R")) "." else ".."
path <- function(...) file.path(root, ...)

r_files <- c("global.R", "ui.R", "server.R", "R/inv_helpers.R",
             "R/report_pdf.R")
for (file in r_files) {
  parsed <- tryCatch(parse(file = path(file)), error = identity)
  expect(!inherits(parsed, "error"), sprintf("%s parses", file))
}

scan_files <- c(
  r_files, "README.md", "docs/index.html", "docs/DATA-TAKEAWAYS.md",
  "www/styles.css", "www/inverts.css", "www/app.js"
)
text <- vapply(scan_files, function(file) {
  paste(readLines(path(file), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}, character(1))

prohibited_claims <- c(
  paste0("ch", "ao"), paste0("rare", "fi"), "clean[- ]water",
  paste0("pollution", "[- ]sensitive"), "health[ -]score"
)
claim_files <- c(
  "ui.R", "server.R", "R/report_pdf.R", "README.md", "docs/index.html",
  "docs/DATA-TAKEAWAYS.md", "www/styles.css", "www/inverts.css"
)
for (pattern in prohibited_claims) {
  hit <- claim_files[grepl(pattern, text[claim_files], ignore.case = TRUE,
                           perl = TRUE)]
  expect(!length(hit), sprintf("prohibited legacy claim /%s/ is absent", pattern))
}

loaded_r <- paste(text[c("global.R", "ui.R", "server.R", "R/inv_helpers.R",
                         "R/report_pdf.R")], collapse = "\n")
for (pattern in c("bundle\\$bouts", "bundle\\$samples", "bundle\\$taxa\\b",
                  "bundle\\$qc_samples")) {
  expect(!grepl(pattern, loaded_r, perl = TRUE),
         sprintf("legacy member access /%s/ is absent", pattern))
}

ui_text <- text[["ui.R"]]
global_text <- text[["global.R"]]
server_text <- text[["server.R"]]
app_js <- text[["www/app.js"]]
inverts_css <- text[["www/inverts.css"]]
for (copy in c(
  "NEON My Little Inverts · unofficial",
  "What lives below the surface?",
  paste("Explore the aquatic invertebrates NEON recorded in stream, river,",
        "and lake-bottom samples."),
  "Choose an aquatic site",
  paste0("Public NEON DP1.20120.001 · collection records—not verified zeros, ",
         "population counts, or water-quality scores.")
)) {
  expect(grepl(copy, ui_text, fixed = TRUE),
         sprintf("approved Living Poster copy is retained: %s", copy))
}
expect(grepl('selectizeInput("searchTaxon", "Taxon name"', ui_text,
             fixed = TRUE), "network taxon search has an associated label")
expect(grepl('tags$meta(name = "ddl-app-ready", content = APP_RELEASE_MARKER)',
             ui_text, fixed = TRUE) &&
         grepl('tags$meta(name = "ddl-release-instance", content = RELEASE_INSTANCE_ID)',
               ui_text, fixed = TRUE),
       "initial Shiny HTML exposes readiness and exact release identity")
expect(grepl('RELEASE_IDENTITY_PATH <- "release/production-identity.json"',
             global_text, fixed = TRUE) &&
         grepl("release_identity_material", global_text, fixed = TRUE) &&
         grepl("identity_file_contract", global_text, fixed = TRUE),
       "runtime validates the deterministic identity and bound release files")
for (file in c("R/inv_helpers.R", "README.md", "docs/DATA-TAKEAWAYS.md")) {
  expect(grepl("MACROALGAE", text[[file]], fixed = TRUE),
         sprintf("audited MACROALGAE special-ID handling is named in %s", file))
}
expect(!grepl("processed_zero_candidates", paste(text, collapse = "\n"),
              fixed = TRUE),
       "unknown-taxonomy copy contains no processed-zero-candidate terminology")
expect(grepl("Support flags can overlap", ui_text, fixed = TRUE) &&
         grepl("Support flags (may overlap)", text[["R/report_pdf.R"]],
               fixed = TRUE) &&
         grepl("inv_support_counts", text[["R/report_pdf.R"]], fixed = TRUE),
       "app and PDF distinguish primary status from overlapping support flags")
expect(grepl("inv_processing_count_counts(rv$opportunities)", server_text,
             fixed = TRUE) &&
         grepl("inv_processing_count_counts(bundle$opportunities)",
               text[["R/report_pdf.R"]], fixed = TRUE) &&
         !grepl('status[["processed_no_taxonomy"]]',
                paste(server_text, text[["R/report_pdf.R"]]), fixed = TRUE),
       paste(
         "Overview and PDF count processed-without-taxonomy from the exclusive",
         "processing outcome rather than primary status"
       ))
expect(grepl("source_qc_rows_retained", server_text, fixed = TRUE) &&
         grepl("metabarcode_field_rows", server_text, fixed = TRUE),
       "QC reconciliation renders retained rows and metabarcoding inventory")
expect(grepl("data[, INV_NETWORK_EXPORT_COLUMNS, drop = FALSE]", server_text,
             fixed = TRUE),
       "network table and CSV use the reviewed export-column contract")
for (retired in c("rodentConfetti", "invMascotSeen", "splash-guide",
                  "mascot-cheer")) {
  expect(!grepl(retired, paste(app_js, inverts_css), fixed = TRUE),
         sprintf("retired app animation code is absent: %s", retired))
}

for (id in c(
  "overviewStatusPlot", "overviewTimeline", "stratumAquaticType",
  "stratumHabitat", "stratumSampler", "stratumDensityPlot",
  "stratumCompositionPlot", "taxonStratum", "taxonSupportPlot",
  "taxonCountPlot", "networkX", "networkY", "networkPlot", "qcLayer",
  "opportunityTable", "metricContractTable", "provenanceTable"
)) {
  expect(grepl(sprintf('"%s"', id), ui_text, fixed = TRUE),
         sprintf("UI declares %s", id))
  expect(grepl(sprintf("output$%s", id), text[["server.R"]], fixed = TRUE) ||
           id %in% c("stratumAquaticType", "stratumHabitat", "stratumSampler",
                     "taxonStratum", "networkX", "networkY", "qcLayer"),
         sprintf("server binds %s", id))
}

environment <- new.env(parent = baseenv())
sys.source(path("R/inv_helpers.R"), envir = environment)

network_export_contract_ok <- function(columns) {
  !anyDuplicated(columns) &&
    !length(setdiff(names(environment$inv_comparison_choices), columns))
}
expect(
  network_export_contract_ok(environment$INV_NETWORK_EXPORT_COLUMNS),
  "every selectable network metric is present in the table/CSV export"
)
for (metric in c(
  "n_processing_unknown", "n_taxonomy_count_unavailable",
  "n_displayed_zero_percent_authoritative_estimate"
)) {
  expect(
    !network_export_contract_ok(setdiff(
      environment$INV_NETWORK_EXPORT_COLUMNS, metric
    )),
    sprintf("network export contract rejects omission of %s", metric)
  )
}

empty_frame <- function(columns) {
  out <- as.data.frame(stats::setNames(replicate(
    length(columns), character(), simplify = FALSE
  ), columns), stringsAsFactors = FALSE)
  out
}

opportunity <- empty_frame(environment$INV_OPPORTUNITY_COLUMNS)
opportunity[1L, ] <- NA
opportunity$opportunity_id <- "opportunity-1"
opportunity$siteID <- "TEST"
opportunity$samplingImpractical <- "location dry"
opportunity$record_status <- "unstratifiable"
opportunity$taxonomy_rows <- 0L
opportunity$has_per_sample <- FALSE
opportunity$sampling_practical <- FALSE
opportunity$primary_stratum <- FALSE
opportunity$grain_complete <- FALSE
opportunity$unstratifiable <- TRUE
opportunity$nonstandard_collection <- FALSE
opportunity$count_eligible <- FALSE
opportunity$density_eligible <- FALSE
opportunity$reported_zero_count <- FALSE
opportunity$processing_unknown <- FALSE
opportunity$taxonomy_count_unavailable <- FALSE
opportunity$displayed_zero_percent_authoritative_estimate <- FALSE
opportunity$processing_count_status <- NA_character_
opportunity$total_estimated_count <- NA_real_

site_summary <- data.frame(
  siteID = "TEST", collectDate_min = "2020-01-01",
  collectDate_max = "2020-01-01", n_events = 0, n_strata = 0,
  n_opportunities = 1, n_sampling_impractical = 1,
  n_nonstandard_collection = 0, n_unstratifiable = 1,
  n_processing_unknown = 0, n_processed_no_taxonomy = 0,
  n_taxonomy_count_unavailable = 0,
  n_displayed_zero_percent_authoritative_estimate = 0,
  n_count_samples = 0,
  n_density_samples = 0, n_taxa_recorded = 0,
  taxonomic_ranks = "", stringsAsFactors = FALSE
)

metric_names <- c(
  "mean_sample_density_m2", "mean_sample_taxa_observed",
  "mean_sample_pct_ept_of_all_estimated_count", "taxon_support_pct",
  "taxon_total_estimated_count"
)
metric_contract <- data.frame(
  metric = metric_names,
  table = c(rep("event_strata", 3L), rep("taxon_strata", 2L)),
  column = c(
    "mean_sample_density_m2", "mean_sample_taxa_observed",
    "mean_sample_pct_ept_of_all_estimated_count", "support_pct",
    "total_estimated_count"
  ),
  grain = c(rep(environment$INV_EXACT_GRAIN, 3L),
            rep(paste(environment$INV_EXACT_GRAIN, "x taxon"), 2L)),
  denominator = rep("fixture", length(metric_names)),
  boundary = rep("fixture", length(metric_names)),
  stringsAsFactors = FALSE
)

meta <- stats::setNames(vector("list", length(environment$INV_META_FIELDS)),
                        environment$INV_META_FIELDS)
meta$schema_version <- environment$INV_BUNDLE_SCHEMA_VERSION
meta$site <- "TEST"
meta$source_stamp <- "2020-01-01"
meta$built <- "2020-01-01"
meta$release <- "RELEASE-2026"
meta$collectDate_min <- "2020-01-01"
meta$collectDate_max <- "2020-01-01"
meta$aquaticSiteType <- "stream"
meta$aquatic_site_types <- "stream"
meta$lat <- 0
meta$lng <- 0
meta$elevation <- 0
meta$named_location_count <- 1
meta$n_events <- 0
meta$n_strata <- 0
meta$n_opportunities <- 1
meta$n_primary_opportunities <- 0
meta$n_count_samples <- 0
meta$n_composition_samples <- 0
meta$n_density_samples <- 0
meta$n_reported_zero_count <- 0
meta$n_unstratifiable <- 1
meta$n_processing_unknown <- 0
meta$n_taxonomy_count_unavailable <- 0
meta$n_displayed_zero_percent_authoritative_estimate <- 0
meta$n_taxa_recorded <- 0
meta$taxonomic_ranks <- ""
meta$comparison_boundary <- environment$INV_EXACT_GRAIN

source_provenance <- list(
  dpid = environment$INV_EXPECTED_DPID,
  release = environment$INV_EXPECTED_RELEASE,
  include_provisional = FALSE,
  publication_date_max = "2020-01-01",
  artifact_sha256 = paste(rep("a", 64L), collapse = ""),
  receipt_sha256 = paste(rep("b", 64L), collapse = "")
)
qc_contract <- list(
  schema_version = environment$INV_QC_AUDIT_SCHEMA_VERSION,
  retain_verbatim = TRUE,
  automatic_exclusion = FALSE,
  eligibility_effect = "none"
)
field_quality <- empty_frame(environment$INV_SOURCE_QUALITY_COLUMNS$field)
field_quality[1L, ] <- NA
field_quality$siteID <- "TEST"
field_quality$sampleID <- "sample-1"
field_quality$sampleCode <- "A"
per_sample_quality <- empty_frame(
  environment$INV_SOURCE_QUALITY_COLUMNS$per_sample
)
taxonomy_quality <- empty_frame(
  environment$INV_SOURCE_QUALITY_COLUMNS$taxonomy_processed
)
issue_log <- empty_frame(environment$INV_ISSUE_LOG_COLUMNS)
status_counts <- data.frame(
  record_status = environment$INV_RECORD_STATUS_LEVELS,
  n = rep(0L, length(environment$INV_RECORD_STATUS_LEVELS)),
  stringsAsFactors = FALSE
)
status_counts$n[status_counts$record_status == "unstratifiable"] <- 1L
source_rows <- data.frame(
  site = "TEST", collection_field_rows = 1L, metabarcode_field_rows = 0L,
  per_sample_rows = 0L, taxonomy_processed_rows = 0L, field_qc_rows = 1L,
  per_sample_qc_rows = 0L, taxonomy_qc_rows = 0L, issue_log_rows = 0L,
  stringsAsFactors = FALSE
)
reconciliation <- list(
  opportunity_rows = 1L, status_rows = 1L, primary_opportunities = 0L,
  count_eligible_samples = 0L, composition_eligible_samples = 0L,
  density_eligible_samples = 0L, reported_zero_count = 0L,
  unstratifiable = 1L, processing_unknown = 0L,
  taxonomy_count_unavailable = 0L,
  displayed_zero_percent_authoritative_estimate = 0L,
  practical_processing_count_opportunities = 0L,
  processing_count_status_counts = stats::setNames(
    rep(0L, length(environment$INV_PROCESSING_COUNT_STATUS_LEVELS)),
    environment$INV_PROCESSING_COUNT_STATUS_LEVELS
  ),
  taxonomy_rows_collapsed = 0L,
  opportunity_complete = TRUE, count_contains_density = TRUE,
  source_qc_rows_retained = c(
    field = 1L, per_sample = 0L, taxonomy_processed = 0L, issue_log = 0L
  ),
  qc_alters_metric_eligibility = FALSE
)

fixture <- list(
  schema_version = environment$INV_BUNDLE_SCHEMA_VERSION,
  opportunities = opportunity,
  event_strata = empty_frame(environment$INV_EVENT_COLUMNS),
  taxon_strata = empty_frame(environment$INV_TAXON_COLUMNS),
  site_summary = site_summary,
  meta = meta,
  metric_contract = metric_contract,
  qc = list(
    contract = qc_contract,
    status_counts = status_counts,
    source_rows = source_rows,
    source_quality = list(
      field = field_quality, per_sample = per_sample_quality,
      taxonomy_processed = taxonomy_quality
    ),
    issue_log = issue_log,
    reconciliation = reconciliation
  ),
  provenance = list(
    source = source_provenance,
    producer_schema_version = environment$INV_PRODUCER_SCHEMA_VERSION,
    science_version = "fixture", field_first = TRUE,
    exact_grain = environment$INV_EXACT_GRAIN,
    qc_contract = qc_contract,
    prohibited_inference = c(
      "site health or impairment", "population abundance",
      "raw-density cross-site ranking", "causality"
    )
  )
)

release_contract <- list(
  schema_version = environment$INV_RELEASE_CONTRACT_SCHEMA_VERSION,
  producer_schema_version = environment$INV_PRODUCER_SCHEMA_VERSION,
  bundle_schema_version = environment$INV_BUNDLE_SCHEMA_VERSION,
  science_version = "fixture",
  source = source_provenance,
  metric_contract = metric_contract,
  qc_contract = qc_contract,
  site_ids = "TEST",
  bundle_sha256 = c(TEST = paste(rep("c", 64L), collapse = "")),
  bundle_members = environment$INV_REQUIRED_BUNDLE_MEMBERS,
  support_index_only = TRUE,
  prohibited_cross_site_fields = c(
    "density_m2", "mean_sample_density_m2", "richness", "ept_richness",
    "pct_ept", "chao1", "rarefied_richness", "health_score"
  )
)

expect(isTRUE(environment$inv_validate_release_contract(
  release_contract, expected_sites = "TEST"
)), "exact reviewed release contract is accepted")
expect(isTRUE(environment$inv_validate_bundle(
  fixture, "TEST", release_contract
)), "exact Pass-9 bundle is accepted")

masked_processing_outcome <- fixture
masked_processing_outcome$opportunities$sampleID <- "sample-1"
masked_processing_outcome$opportunities$sampleCode <- "A"
masked_processing_outcome$opportunities$samplingImpractical <- "OK"
masked_processing_outcome$opportunities$has_per_sample <- TRUE
masked_processing_outcome$opportunities$sampling_practical <- TRUE
masked_processing_outcome$opportunities$processing_count_status <-
  "processed_no_taxonomy"
masked_processing_outcome$site_summary$n_sampling_impractical <- 0L
masked_processing_outcome$site_summary$n_processed_no_taxonomy <- 1L
masked_processing_outcome$qc$reconciliation[[
  "practical_processing_count_opportunities"
]] <- 1L
masked_processing_outcome$qc$reconciliation$processing_count_status_counts[
  "processed_no_taxonomy"
] <- 1L
expect(
  isTRUE(environment$inv_validate_bundle(
    masked_processing_outcome, "TEST", release_contract
  )) &&
    identical(
      unname(environment$inv_processing_count_counts(
        masked_processing_outcome$opportunities
      )[["processed_no_taxonomy"]]),
      1L
    ) &&
    identical(masked_processing_outcome$opportunities$record_status,
              "unstratifiable"),
  paste(
    "loaded app counts processed-without-taxonomy from the exclusive outcome",
    "when primary status is unstratifiable"
  )
)
stale_masked_summary <- masked_processing_outcome
stale_masked_summary$site_summary$n_processed_no_taxonomy <- 0L
expect(
  !isTRUE(environment$inv_validate_bundle(
    stale_masked_summary, "TEST", release_contract
  )),
  paste(
    "loaded app rejects a primary-status-derived processed-without-taxonomy",
    "summary that masks the exclusive outcome"
  )
)

# The dominant status is intentionally not a partition of overlapping support
# conditions. Missing exact-grain evidence precedes sampling impracticality.
overlap <- fixture
expect(isTRUE(environment$inv_validate_bundle(
  overlap, "TEST", release_contract
)), "unstratifiable status is accepted beside sampling-impractical support")
expect(identical(
  overlap$opportunities$record_status, "unstratifiable"
), "unstratifiable is the primary status under exact precedence")
expect(identical(
  unname(environment$inv_support_counts(overlap$opportunities)[c(
    "sampling_impractical", "unstratifiable"
  )]), c(1L, 1L)
), "support helper preserves overlapping marginal conditions")

# A usable zero may have area_unavailable as its dominant processing status.
zero_area <- fixture
zero_area$opportunities$sampleID <- "sample-1"
zero_area$opportunities$sampleCode <- "A"
zero_area$opportunities$eventID <- "event-1"
zero_area$opportunities$aquaticSiteType <- "stream"
zero_area$opportunities$habitatType <- "riffle"
zero_area$opportunities$samplerType <- "Surber"
zero_area$opportunities$samplingImpractical <- "OK"
zero_area$opportunities$sampling_practical <- TRUE
zero_area$opportunities$sampler_type_normalized <- "surber"
zero_area$opportunities$grain_complete <- TRUE
zero_area$opportunities$unstratifiable <- FALSE
zero_area$opportunities$primary_stratum <- TRUE
zero_area$opportunities$processing_count_status <-
  "taxonomy_count_available"
zero_area$opportunities$taxonomy_rows <- 1L
zero_area$opportunities$record_status <- "area_unavailable"
zero_area$opportunities$count_eligible <- TRUE
zero_area$opportunities$reported_zero_count <- TRUE
zero_area$opportunities$total_estimated_count <- 0
zero_area$site_summary$n_sampling_impractical <- 0L
zero_area$site_summary$n_unstratifiable <- 0L
zero_area$site_summary$n_count_samples <- 1L
zero_area$meta$n_primary_opportunities <- 1L
zero_area$meta$n_count_samples <- 1L
zero_area$meta$n_reported_zero_count <- 1L
zero_area$meta$n_unstratifiable <- 0L
zero_area$qc$status_counts$n[] <- 0L
zero_area$qc$status_counts$n[
  zero_area$qc$status_counts$record_status == "area_unavailable"
] <- 1L
zero_area$qc$reconciliation$primary_opportunities <- 1L
zero_area$qc$reconciliation$count_eligible_samples <- 1L
zero_area$qc$reconciliation$reported_zero_count <- 1L
zero_area$qc$reconciliation$unstratifiable <- 0L
zero_area$qc$reconciliation$practical_processing_count_opportunities <- 1L
zero_area$qc$reconciliation$processing_count_status_counts[] <- 0L
zero_area$qc$reconciliation$processing_count_status_counts[
  "taxonomy_count_available"
] <- 1L
zero_area$qc$reconciliation$taxonomy_rows_collapsed <- 1L
expect(isTRUE(environment$inv_validate_bundle(
  zero_area, "TEST", release_contract
)), "reported-zero support is accepted beside area-unavailable status")
expect(identical(
  unname(environment$inv_support_counts(zero_area$opportunities)[
    "reported_zero_count"
  ]), 1L
), "reported-zero total is boolean-derived rather than status-derived")

# Coordinated valid labels must not be able to replace the primitive row state.
# Each adversary also updates its dependent QC ledger, so a label-only
# reconciliation would accept it.
broken_precedence <- fixture
broken_precedence$opportunities$record_status <- "sampling_impractical"
broken_precedence$qc$status_counts$n[] <- 0L
broken_precedence$qc$status_counts$n[
  broken_precedence$qc$status_counts$record_status == "sampling_impractical"
] <- 1L
expect(!isTRUE(environment$inv_validate_bundle(
  broken_precedence, "TEST", release_contract
)), "coordinated status/QC tampering cannot bypass exact precedence")

broken_processing <- zero_area
broken_processing$opportunities$processing_count_status <-
  "taxonomy_count_unavailable"
broken_processing$qc$reconciliation$processing_count_status_counts[] <- 0L
broken_processing$qc$reconciliation$processing_count_status_counts[
  "taxonomy_count_unavailable"
] <- 1L
expect(!isTRUE(environment$inv_validate_bundle(
  broken_processing, "TEST", release_contract
)), "processing/count labels are rebuilt from primitive outcome evidence")

broken_count <- zero_area
broken_count$opportunities$count_eligible <- FALSE
broken_count$opportunities$reported_zero_count <- FALSE
broken_count$opportunities$record_status <- "count_unavailable"
broken_count$site_summary$n_count_samples <- 0L
broken_count$meta$n_count_samples <- 0L
broken_count$meta$n_reported_zero_count <- 0L
broken_count$qc$status_counts$n[] <- 0L
broken_count$qc$status_counts$n[
  broken_count$qc$status_counts$record_status == "count_unavailable"
] <- 1L
broken_count$qc$reconciliation$count_eligible_samples <- 0L
broken_count$qc$reconciliation$reported_zero_count <- 0L
expect(!isTRUE(environment$inv_validate_bundle(
  broken_count, "TEST", release_contract
)), "count eligibility is rebuilt from primitive taxonomy/count evidence")

zero_with_area <- zero_area
zero_with_area$opportunities$benthicArea_m2 <- 2
zero_with_area$opportunities$density_eligible <- TRUE
zero_with_area$opportunities$sample_density_m2 <- 0
zero_with_area$opportunities$record_status <- "reported_zero_count"
zero_with_area$site_summary$n_density_samples <- 1L
zero_with_area$meta$n_density_samples <- 1L
zero_with_area$qc$status_counts$n[] <- 0L
zero_with_area$qc$status_counts$n[
  zero_with_area$qc$status_counts$record_status == "reported_zero_count"
] <- 1L
zero_with_area$qc$reconciliation$density_eligible_samples <- 1L
expect(isTRUE(environment$inv_validate_bundle(
  zero_with_area, "TEST", release_contract
)), "valid-area reported zero follows the exact density/status projection")

broken_density <- zero_with_area
broken_density$opportunities$density_eligible <- FALSE
broken_density$opportunities$sample_density_m2 <- NA_real_
broken_density$opportunities$record_status <- "area_unavailable"
broken_density$site_summary$n_density_samples <- 0L
broken_density$meta$n_density_samples <- 0L
broken_density$qc$status_counts$n[] <- 0L
broken_density$qc$status_counts$n[
  broken_density$qc$status_counts$record_status == "area_unavailable"
] <- 1L
broken_density$qc$reconciliation$density_eligible_samples <- 0L
expect(!isTRUE(environment$inv_validate_bundle(
  broken_density, "TEST", release_contract
)), "density eligibility is rebuilt from the primitive area/count quotient")

broken_zero <- zero_with_area
broken_zero$opportunities$reported_zero_count <- FALSE
broken_zero$opportunities$record_status <- "quantified_community"
broken_zero$meta$n_reported_zero_count <- 0L
broken_zero$qc$status_counts$n[] <- 0L
broken_zero$qc$status_counts$n[
  broken_zero$qc$status_counts$record_status == "quantified_community"
] <- 1L
broken_zero$qc$reconciliation$reported_zero_count <- 0L
expect(!isTRUE(environment$inv_validate_bundle(
  broken_zero, "TEST", release_contract
)), "reported-zero support is rebuilt from the primitive count total")

broken <- fixture
broken$opportunities <- NULL
expect(!isTRUE(environment$inv_validate_bundle(
  broken, "TEST", release_contract
)),
       "missing opportunity ledger is rejected")
broken <- fixture
broken$bouts <- data.frame()
expect(!isTRUE(environment$inv_validate_bundle(
  broken, "TEST", release_contract
)),
       "legacy bundle member is rejected")
broken <- fixture
broken$opportunities$density_eligible <- TRUE
expect(!isTRUE(environment$inv_validate_bundle(
  broken, "TEST", release_contract
)),
       "density eligibility outside count eligibility is rejected")
broken <- fixture
broken$qc <- list()
expect(!isTRUE(environment$inv_validate_bundle(
  broken, "TEST", release_contract
)), "bundle without QC evidence is rejected")
broken <- fixture
broken$qc$source_quality <- NULL
expect(!isTRUE(environment$inv_validate_bundle(
  broken, "TEST", release_contract
)), "bundle without source-quality inventory is rejected")
broken <- fixture
broken$provenance$source <- list()
expect(!isTRUE(environment$inv_validate_bundle(
  broken, "TEST", release_contract
)), "bundle without source identity is rejected")
broken <- fixture
broken$meta$release <- "RELEASE-1900"
broken$provenance$source$release <- "RELEASE-1900"
expect(!isTRUE(environment$inv_validate_bundle(
  broken, "TEST", release_contract
)), "bundle from another release is rejected")
broken <- fixture
broken$metric_contract$boundary[[1L]] <- "tampered"
expect(!isTRUE(environment$inv_validate_bundle(
  broken, "TEST", release_contract
)), "bundle metrics must match the reviewed release contract")

fixture_path <- tempfile(fileext = ".rds")
on.exit(unlink(fixture_path), add = TRUE)
saveRDS(fixture, fixture_path, version = 3)
fixture_hash <- digest::digest(file = fixture_path, algo = "sha256")
expect(isTRUE(environment$inv_verify_file_sha256(fixture_path, fixture_hash)),
       "reviewed bundle file hash is accepted")
expect(!isTRUE(environment$inv_verify_file_sha256(
  fixture_path, paste(rep("0", 64L), collapse = "")
)), "bundle bytes outside the release hash are rejected")

site_index <- as.data.frame(stats::setNames(replicate(
  length(environment$INV_SITE_INDEX_COLUMNS), NA, simplify = FALSE
), environment$INV_SITE_INDEX_COLUMNS), stringsAsFactors = FALSE)
site_index$site <- "TEST"
site_index$aquaticSiteType <- "stream"
site_index$lat <- 0
site_index$lng <- 0
site_index$elevation <- 0
site_index$collectDate_min <- "2020-01-01"
site_index$collectDate_max <- "2020-01-01"
site_count_fields <- grep("^n_", names(site_index), value = TRUE)
site_index[site_count_fields] <- 0L
site_index$taxonomic_ranks <- ""
site_index$source_stamp <- source_provenance$publication_date_max
site_index$science_version <- "fixture"
expect(isTRUE(environment$inv_validate_site_index(
  site_index, release_contract
)),
       "effort/records-only site index is accepted")
broken_index <- site_index
broken_index$n_unstratifiable <- NULL
expect(!isTRUE(environment$inv_validate_site_index(
  broken_index, release_contract
)),
       "site index without n_unstratifiable is rejected")
broken_index <- site_index
broken_index$density_m2 <- 1
expect(!isTRUE(environment$inv_validate_site_index(
  broken_index, release_contract
)),
       "site index with raw density is rejected")
broken_index <- site_index
broken_index$chao1 <- 1
expect(!isTRUE(environment$inv_validate_site_index(
  broken_index, release_contract
)), "site index with an extra biological rank field is rejected")

search_index <- list(
  schema_version = environment$INV_PRODUCER_SCHEMA_VERSION,
  taxa = empty_frame(environment$INV_SEARCH_TAXON_COLUMNS),
  sites = site_index,
  metric_contract = metric_contract,
  source = source_provenance,
  built = source_provenance$publication_date_max,
  boundary = "Exact-stratum support rows only; no density ranking."
)
expect(isTRUE(environment$inv_validate_search_index(
  search_index, release_contract, site_index
)), "search index is bound to the reviewed release and site index")
broken_search <- search_index
broken_search$source$release <- "RELEASE-1900"
expect(!isTRUE(environment$inv_validate_search_index(
  broken_search, release_contract, site_index
)), "search index from another release is rejected")
broken_search <- search_index
broken_search$sites$n_opportunities <- 99L
expect(!isTRUE(environment$inv_validate_search_index(
  broken_search, release_contract, site_index
)), "search index with a different site table is rejected")

cat(sprintf("Loaded-app contract checks passed (%d checks).\n", checks))
