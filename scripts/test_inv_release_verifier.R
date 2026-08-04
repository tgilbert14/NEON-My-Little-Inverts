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

expect_true(
  identical(
    inv_release_publication_dates(c(
      "20251204T230818Z", "20251206T000925Z"
    )),
    as.Date(c("2025-12-04", "2025-12-06"))
  ),
  "independent verifier parses NEON compact UTC publication dates"
)
expect_true(
  identical(
    inv_release_publication_dates(c(
      "2025-12-04", "2025-12-05T23:08:18Z", "invalid", NA_character_
    )),
    as.Date(c("2025-12-04", "2025-12-05", NA_character_, NA_character_))
  ),
  "independent verifier parses ISO publication dates and fails closed"
)
expect_true(
  all(is.na(inv_release_publication_dates(c(
    "20251204T230818Zjunk", "2025-12-05T23:08:18Zjunk",
    "2025-12-05junk", "20251204T230818Z ",
    "20251204T250818Z", "2025-12-05T23:61:18Z",
    "20250230T230818Z", "2025-02-30", "2025-02-30T23:08:18Z"
  )))),
  paste(
    "strict publication parser rejects trailing junk, whitespace, invalid",
    "clock values, and invalid calendar dates"
  )
)
expect_true(
  identical(
    inv_release_publication_dates(as.Date(c(
      "2025-12-04", "2025-12-05"
    ))),
    as.Date(c("2025-12-04", "2025-12-05"))
  ) && identical(
    inv_release_publication_dates(as.POSIXct(
      c("2025-12-04 23:08:18", "2025-12-05 00:00:00"), tz = "UTC"
    )),
    as.Date(c("2025-12-04", "2025-12-05"))
  ),
  "independent verifier preserves valid Date and POSIX UTC-day semantics"
)
non_utc_posixlt <- as.POSIXlt(
  as.POSIXct("2025-12-04 23:30:00", tz = "America/New_York"),
  tz = "America/New_York"
)
expect_true(
  identical(
    inv_release_publication_dates(non_utc_posixlt), as.Date("2025-12-05")
  ),
  paste(
    "independent verifier preserves a non-UTC POSIXlt instant before UTC",
    "calendar-day projection"
  )
)
invalid_date_values <- structure(
  c(20000.5, Inf, -Inf, NaN), class = "Date"
)
invalid_posix_values <- structure(
  c(Inf, -Inf, NaN), class = c("POSIXct", "POSIXt"), tzone = "UTC"
)
invalid_posixlt_value <- as.POSIXlt(
  structure(
    Inf, class = c("POSIXct", "POSIXt"), tzone = "America/New_York"
  ),
  tz = "America/New_York"
)
expect_true(
  all(is.na(inv_release_publication_dates(invalid_date_values))) &&
    all(is.na(inv_release_publication_dates(invalid_posix_values))) &&
    all(is.na(inv_release_publication_dates(invalid_posixlt_value))),
  paste(
    "independent verifier rejects fractional or nonfinite Date days and",
    "nonfinite POSIXct/POSIXlt instants"
  )
)
heterogeneous_metadata_summary <- list(
  class = "tbl_df/tbl/data.frame", row_count = 2L,
  columns = c("table", "fieldName"),
  column_classes = list(table = "character", fieldName = "character")
)
expect_true(
  isTRUE(tryCatch({
    inv_release_assert_receipt_object_summary(
      heterogeneous_metadata_summary, "heterogeneous metadata fixture"
    )
    TRUE
  }, error = function(error) FALSE)),
  "receipt schema accepts an exact tibble/data-frame class inventory"
)
data_table_metadata_summary <- heterogeneous_metadata_summary
data_table_metadata_summary$class <- "data.table/data.frame"
expect_true(
  isTRUE(tryCatch({
    inv_release_assert_receipt_object_summary(
      data_table_metadata_summary, "data.table metadata fixture"
    )
    TRUE
  }, error = function(error) FALSE)) &&
    !inv_release_value_equal(
      heterogeneous_metadata_summary, data_table_metadata_summary
    ),
  paste(
    "receipt schema accepts data.table/data.frame but exact raw comparison",
    "still rejects class drift"
  )
)

# Exercise the same exact-audit comparator used when production_exact=TRUE.
# The general fixture below is intentionally release-shaped rather than a copy
# of the production source, so pin the audited three-row per-sample UID family
# here and prove that a one-character canonical-hash defect is rejected.
production_exact_dna <- INV_RELEASE_DNA_FAMILY
production_exact_dna$uid_inventory_sha256[["inv_persample"]] <-
  "0202459f40870adc34539e57b97ab3dc8e41f6d0e4dec2add201bffb18aa1b55"
expect_true(
  isTRUE(tryCatch({
    inv_release_assert_audit(
      production_exact_dna, INV_RELEASE_DNA_FAMILY,
      "synthetic production-exact .DNA family"
    )
    TRUE
  }, error = function(error) FALSE)),
  "production-exact .DNA audit accepts the canonical three-row UID hash"
)
bad_production_exact_dna <- production_exact_dna
bad_production_exact_dna$uid_inventory_sha256[["inv_persample"]] <-
  "0202459f40870adc3459e57b97ab3dc8e41f6d0e4dec2add201bffb18aa1b55"
expect_error(
  inv_release_assert_audit(
    bad_production_exact_dna, INV_RELEASE_DNA_FAMILY,
    "synthetic production-exact .DNA family"
  ),
  "field uid_inventory_sha256 differs",
  "production-exact .DNA adversary rejects a truncated canonical UID hash"
)

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

mixed_publication_source <- source_fixture
mixed_publication_source$inv_persample$publicationDate[1:2] <- c(
  "20251204T230818Z", "not-a-publication-date"
)
expect_error(
  inv_release_publication_stamp(mixed_publication_source),
  "unparseable publicationDate in inv_persample",
  paste0(
    "independent publication-stamp adversary rejects a malformed value ",
    "among valid values"
  )
)

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
production_receipt <- jsonlite::fromJSON(
  receipt_path, simplifyVector = TRUE, simplifyDataFrame = FALSE,
  simplifyMatrix = FALSE
)
production_receipt$object_names <- INV_RELEASE_OBJECT_NAMES
production_receipt$all_objects <-
  production_receipt$all_objects[INV_RELEASE_OBJECT_NAMES]
production_receipt$relations <- INV_RELEASE_SAMPLE_IDENTITY
INV_SYNTHETIC_FIXTURE_MODE <- FALSE
expect_true(
  isTRUE(tryCatch({
    inv_release_validate_receipt(production_receipt, receipt_path)
    TRUE
  }, error = function(error) FALSE)),
  "production receipt validator accepts the exact sampleID-primary relation"
)
bad_production_relation <- production_receipt
bad_production_relation$relations$practical_field_rows <-
  bad_production_relation$relations$practical_field_rows + 1L
expect_error(
  inv_release_validate_receipt(bad_production_relation, receipt_path),
  "published receipt sampleID-primary relation field practical_field_rows differs",
  "production receipt validator rejects a coordinated relation-value drift"
)
INV_SYNTHETIC_FIXTURE_MODE <- TRUE
inv_produce_verified_release(artifact_path, receipt_path, release_root)

base_summary <- inv_verify_release_data(release_root)
raw_summary <- inv_verify_release_against_source(
  release_root, artifact_path, receipt_path, production_exact = FALSE
)
expect_true(identical(base_summary$sites, 34L) &&
              identical(raw_summary$opportunities, 35L),
            "untampered bundle and raw source pass independent verification")
streaming_diagnostics <- attr(raw_summary, "streaming_diagnostics")
expect_true(
  is.list(streaming_diagnostics) &&
    identical(streaming_diagnostics$streamed_sites, 34L) &&
    identical(streaming_diagnostics$max_full_bundles_retained, 1L) &&
    is.finite(streaming_diagnostics$largest_full_bundle_bytes) &&
    streaming_diagnostics$largest_full_bundle_bytes > 0,
  paste(
    "raw authority regression streams all 34 sites while retaining at most",
    "one full QC-bearing bundle"
  )
)

# Keep a deliberately simple split-based oracle in the test only. Production
# uses a vectorized group ledger, so this independent implementation protects
# its semantics while avoiding the split/rbind memory cost in the release gate.
reference_raw_collapse <- function(taxonomy) {
  count <- inv_release_raw_count_values(taxonomy)
  sample_key <- inv_release_pair_key(taxonomy$sampleID, taxonomy$sampleCode)
  taxon_key <- trimws(as.character(taxonomy$acceptedTaxonID))
  unresolved <- inv_release_blank(taxon_key)
  inv_release_assert(
    !any(unresolved &
           (!is.na(inv_release_num(taxonomy$individualCount)) |
              !is.na(inv_release_num(taxonomy$estimatedTotalCount)))) &&
      !any(unresolved & inv_release_blank(taxonomy$uid)),
    "Reference unresolved taxonomy identity is invalid"
  )
  taxon_key[unresolved] <- paste0(
    "unresolved-source-record:", taxonomy$uid[unresolved]
  )
  groups <- split(
    seq_len(nrow(taxonomy)), paste(sample_key, taxon_key, sep = "\u241d"),
    drop = TRUE
  )
  rows <- lapply(groups, function(index) {
    issues <- unique(count$issue[index])
    issues <- issues[!is.na(issues)]
    valid <- !length(issues)
    value <- if (valid) sum(count$value[index]) else NA_real_
    if (valid && !is.finite(value)) {
      valid <- FALSE
      value <- NA_real_
      issues <- "nonfinite_collapsed_count"
    }
    order_value <- inv_release_strict_value(taxonomy$order[index], "order")
    data.frame(
      sample_key = sample_key[index[[1L]]],
      taxon_key = taxon_key[index[[1L]]],
      acceptedTaxonID = inv_release_strict_value(
        taxonomy$acceptedTaxonID[index], "acceptedTaxonID"
      ),
      scientificName = inv_release_strict_value(
        taxonomy$scientificName[index], "scientificName"
      ),
      taxonRank = inv_release_strict_value(
        taxonomy$taxonRank[index], "taxonRank"
      ),
      order = order_value,
      family = inv_release_strict_value(taxonomy$family[index], "family"),
      class = inv_release_strict_value(taxonomy$class[index], "class"),
      subclass = inv_release_strict_value(
        taxonomy$subclass[index], "subclass"
      ),
      estimated_count = value,
      count_valid = valid,
      count_issue = if (valid) NA_character_ else
        paste(sort(unique(issues)), collapse = ";"),
      displayed_zero_percent_authoritative_estimate = any(
        count$displayed_zero_percent_authoritative_estimate[index]
      ),
      order_classified = !is.na(order_value),
      is_ept = !is.na(order_value) && tolower(order_value) %in%
        tolower(c("Ephemeroptera", "Plecoptera", "Trichoptera")),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out <- out[order(out$sample_key, out$taxon_key), , drop = FALSE]
  rownames(out) <- NULL
  out
}

set.seed(20120)
group <- rep(seq_len(400L), sample(2:4, 400L, replace = TRUE))
random_taxonomy <- data.frame(
  uid = sprintf("collapse-%06d", seq_along(group)),
  sampleID = sprintf("SITE.S%03d", (group - 1L) %% 80L + 1L),
  sampleCode = sprintf("C%03d", (group - 1L) %% 80L + 1L),
  acceptedTaxonID = sprintf("T%03d", (group - 1L) %/% 80L + 1L),
  scientificName = sprintf("Taxon %03d", (group - 1L) %/% 80L + 1L),
  taxonRank = "genus",
  order = c("Ephemeroptera", "Diptera", NA_character_)[
    (group - 1L) %% 3L + 1L
  ],
  family = sprintf("Family %03d", (group - 1L) %/% 80L + 1L),
  class = "Insecta", subclass = NA_character_,
  individualCount = sample(0:20, length(group), replace = TRUE),
  estimatedTotalCount = NA_real_,
  subsamplePercent = sample(c(0, 25, 50, 100), length(group), replace = TRUE),
  stringsAsFactors = FALSE
)
random_taxonomy$estimatedTotalCount <- random_taxonomy$individualCount +
  sample(0:20, nrow(random_taxonomy), replace = TRUE)
group_rows <- split(seq_len(nrow(random_taxonomy)), group)
random_taxonomy$estimatedTotalCount[group_rows[[1L]][[1L]]] <- NA_real_
random_taxonomy$estimatedTotalCount[group_rows[[2L]][1:2]] <- 1e308
random_taxonomy$individualCount[group_rows[[2L]][1:2]] <- 1e308
random_taxonomy$subsamplePercent[group_rows[[3L]][[1L]]] <- 0
vectorized_collapse <- inv_release_raw_collapsed_taxonomy(random_taxonomy)
reference_collapse <- reference_raw_collapse(random_taxonomy)
expect_true(
  inv_release_frame_equal(vectorized_collapse, reference_collapse),
  "vectorized raw collapse equals the split-based randomized oracle"
)
poisoned <- vectorized_collapse[
  vectorized_collapse$sample_key == random_taxonomy$sampleID[
    group_rows[[1L]][[1L]]
  ] &
    vectorized_collapse$taxon_key == random_taxonomy$acceptedTaxonID[
      group_rows[[1L]][[1L]]
    ], , drop = FALSE
]
overflowed <- vectorized_collapse[
  vectorized_collapse$sample_key == random_taxonomy$sampleID[
    group_rows[[2L]][[1L]]
  ] &
    vectorized_collapse$taxon_key == random_taxonomy$acceptedTaxonID[
      group_rows[[2L]][[1L]]
    ], , drop = FALSE
]
zero_marked <- vectorized_collapse[
  vectorized_collapse$sample_key == random_taxonomy$sampleID[
    group_rows[[3L]][[1L]]
  ] &
    vectorized_collapse$taxon_key == random_taxonomy$acceptedTaxonID[
      group_rows[[3L]][[1L]]
    ], , drop = FALSE
]
expect_true(
  nrow(poisoned) == 1L && !poisoned$count_valid &&
    poisoned$count_issue == "estimated_count_unavailable",
  "one invalid member poisons its complete sample-taxon group"
)
expect_true(
  nrow(overflowed) == 1L && !overflowed$count_valid &&
    overflowed$count_issue == "nonfinite_collapsed_count",
  "within-group overflow is quarantined by the vectorized raw collapse"
)
expect_true(
  nrow(zero_marked) == 1L &&
    zero_marked$displayed_zero_percent_authoritative_estimate,
  "finite published counts retain the displayed-zero subsample marker"
)

bad_unresolved <- random_taxonomy[1L, , drop = FALSE]
bad_unresolved$acceptedTaxonID <- NA_character_
bad_unresolved$uid <- ""
bad_unresolved$individualCount <- NA_real_
bad_unresolved$estimatedTotalCount <- NA_real_
expect_error(
  inv_release_raw_collapsed_taxonomy(bad_unresolved),
  "nonblank UID",
  "unresolved raw taxonomy without UID is rejected"
)
bad_metadata <- random_taxonomy[group_rows[[4L]][1:2], , drop = FALSE]
bad_metadata$order[[2L]] <- "Plecoptera"
expect_error(
  inv_release_raw_collapsed_taxonomy(bad_metadata),
  "conflicting order",
  "within-group metadata conflicts remain fail-closed"
)

tiny_field <- data.frame(
  namedLocation = c("TEST.AOS", "TEST.AOS"), eventID = "TEST.2026.1",
  sampleID = c("TEST.S1", "TEST.S2"), sampleCode = c("S1", "S2"),
  habitatType = "riffle", samplerType = "Surber",
  sampleNumber = c("1", "2"), siteID = "TEST",
  collectDate = "2026-01-01", aquaticSiteType = "stream",
  benthicArea = 1e-308, samplingImpractical = "OK",
  stringsAsFactors = FALSE
)
tiny_per <- tiny_field[c("sampleID", "sampleCode")]
tiny_taxonomy <- data.frame(
  uid = c("tiny-1", "tiny-2"), sampleID = tiny_field$sampleID,
  sampleCode = tiny_field$sampleCode, acceptedTaxonID = "A",
  scientificName = "Alpha", taxonRank = "genus", order = "Ephemeroptera",
  family = "Baetidae", class = "Insecta", subclass = NA_character_,
  individualCount = 1, estimatedTotalCount = 1,
  subsamplePercent = c(0, 100), stringsAsFactors = FALSE
)
tiny_source <- list(
  inv_fieldData = tiny_field, inv_persample = tiny_per,
  inv_taxonomyProcessed = tiny_taxonomy
)
tiny_science <- build_inv_science_contract(tiny_source)
tiny_collapsed <- inv_release_raw_collapsed_taxonomy(tiny_taxonomy)
tiny_expected_opportunities <- inv_release_raw_expected_opportunities(
  tiny_field, tiny_per, tiny_collapsed
)
tiny_expected_taxa <- inv_release_expected_raw_taxa(
  tiny_collapsed, tiny_science$opportunities
)
expect_true(
  inv_release_frame_equal(
    inv_release_sort_frame(tiny_science$opportunities, "opportunity_id"),
    inv_release_sort_frame(tiny_expected_opportunities, "opportunity_id")
  ) &&
    inv_release_frame_equal(tiny_science$taxon_strata, tiny_expected_taxa) &&
    is.finite(tiny_expected_taxa$mean_sample_density_m2) &&
    is.finite(tiny_expected_taxa$median_sample_density_m2) &&
    abs(tiny_expected_taxa$mean_sample_density_m2 / 1e308 - 1) < 1e-12 &&
    abs(tiny_expected_taxa$median_sample_density_m2 / 1e308 - 1) < 1e-12 &&
    sum(tiny_expected_opportunities$
      displayed_zero_percent_authoritative_estimate) == 1L &&
    !any(tiny_expected_opportunities$reported_zero_count),
  paste(
    "science and independent verifier agree on finite extreme taxon",
    "density and distinguish displayed 0% subsampling from organism zero"
  )
)

sample_overflow_field <- tiny_field[1L, , drop = FALSE]
sample_overflow_field$benthicArea <- 1
sample_overflow_per <- tiny_per[1L, , drop = FALSE]
sample_overflow_taxonomy <- tiny_taxonomy[rep(1L, 2L), , drop = FALSE]
sample_overflow_taxonomy$uid <- c("overflow-a", "overflow-b")
sample_overflow_taxonomy$acceptedTaxonID <- c("A", "B")
sample_overflow_taxonomy$scientificName <- c("Alpha", "Beta")
sample_overflow_taxonomy$individualCount <- 1e308
sample_overflow_taxonomy$estimatedTotalCount <- 1e308
sample_overflow_taxonomy$subsamplePercent <- 100
sample_overflow_collapsed <- inv_release_raw_collapsed_taxonomy(
  sample_overflow_taxonomy
)
sample_overflow_opportunity <- inv_release_raw_expected_opportunities(
  sample_overflow_field, sample_overflow_per, sample_overflow_collapsed
)
expect_true(
  nrow(sample_overflow_opportunity) == 1L &&
    sample_overflow_opportunity$count_issue == "nonfinite_sample_total" &&
    sample_overflow_opportunity$record_status == "count_unavailable" &&
    sample_overflow_opportunity$taxonomy_count_unavailable &&
    !sample_overflow_opportunity$count_eligible &&
    is.na(sample_overflow_opportunity$total_estimated_count),
  "finite taxon groups whose sample sum overflows are explicitly quarantined"
)

copy_release <- function(label) {
  target <- file.path(temp_root, label)
  dir.create(target)
  members <- list.files(release_root, all.files = TRUE, no.. = TRUE,
                        full.names = TRUE)
  copied <- file.copy(members, target, recursive = TRUE)
  if (!all(copied)) stop("Could not copy adversarial fixture", call. = FALSE)
  target
}

rewrite_source_provenance <- function(label, mutate) {
  target <- copy_release(label)
  contract_path <- file.path(target, "data", "release_contract.rds")
  contract <- readRDS(contract_path)
  contract$source <- mutate(contract$source)
  for (site in INV_RELEASE_EXPECTED_SITES) {
    bundle_path <- file.path(target, "data", "sites", paste0(site, ".rds"))
    bundle <- readRDS(bundle_path)
    bundle$provenance$source <- contract$source
    inv_producer_save_rds(bundle, bundle_path)
    contract$bundle_sha256[[site]] <- inv_release_sha256(bundle_path)
  }
  search_path <- file.path(target, "data", "search_index.rds")
  search <- readRDS(search_path)
  search$source <- contract$source
  inv_producer_save_rds(search, search_path)
  inv_producer_save_rds(contract, contract_path)
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
  "receipt-derived authority",
  "release contract must preserve the receipt-bound fetching revision"
)

source_adversaries <- list(
  package = function(source) {
    source$package <- "expanded"
    source
  },
  citation = function(source) {
    source$citation_object <- "citation_20120_RELEASE-2025"
    source$citation_sha256 <- paste(rep("d", 64L), collapse = "")
    source
  },
  runtime = function(source) {
    source$producer_r_version <- "4.5.3"
    source$neonUtilities_version <- "4.0.2"
    source$neonUtilities_source <- paste0(source$neonUtilities_source, "?drift")
    source
  },
  fetched_time = function(source) {
    source$fetched_at_utc <- "2026-07-15T12:00:01Z"
    source
  },
  artifact_bytes = function(source) {
    source$artifact_bytes <- as.numeric(source$artifact_bytes) + 1
    source
  }
)
for (label in names(source_adversaries)) {
  bad_source <- rewrite_source_provenance(
    paste0("bad-source-", label), source_adversaries[[label]]
  )
  expect_error(
    inv_verify_release_data(bad_source),
    "receipt-derived authority",
    paste("receipt authority rejects coordinated", label, "provenance drift")
  )
}

write_receipt <- function(path, receipt) {
  json <- paste0(jsonlite::toJSON(
    receipt, auto_unbox = TRUE, pretty = TRUE, null = "null"
  ), "\n")
  connection <- file(path, open = "wb")
  on.exit(close(connection), add = TRUE)
  writeBin(charToRaw(json), connection)
}

bad_receipt_citation <- copy_release("bad-receipt-citation-hash")
bad_receipt_path <- file.path(
  bad_receipt_citation, "data", "source_receipt.json"
)
bad_receipt <- jsonlite::fromJSON(
  bad_receipt_path, simplifyVector = TRUE, simplifyDataFrame = FALSE,
  simplifyMatrix = FALSE
)
bad_receipt$citation$text <- paste0(
  bad_receipt$citation$text, " coordinated citation drift"
)
write_receipt(bad_receipt_path, bad_receipt)
bad_receipt_contract_path <- file.path(
  bad_receipt_citation, "data", "release_contract.rds"
)
bad_receipt_contract <- readRDS(bad_receipt_contract_path)
bad_receipt_contract$source$receipt_sha256 <-
  inv_release_sha256(bad_receipt_path)
for (site in INV_RELEASE_EXPECTED_SITES) {
  bundle_path <- file.path(
    bad_receipt_citation, "data", "sites", paste0(site, ".rds")
  )
  bundle <- readRDS(bundle_path)
  bundle$provenance$source$receipt_sha256 <-
    bad_receipt_contract$source$receipt_sha256
  inv_producer_save_rds(bundle, bundle_path)
  bad_receipt_contract$bundle_sha256[[site]] <-
    inv_release_sha256(bundle_path)
}
search_path <- file.path(bad_receipt_citation, "data", "search_index.rds")
search <- readRDS(search_path)
search$source$receipt_sha256 <- bad_receipt_contract$source$receipt_sha256
inv_producer_save_rds(search, search_path)
inv_producer_save_rds(bad_receipt_contract, bad_receipt_contract_path)
expect_error(
  inv_verify_release_data(bad_receipt_citation),
  "citation identity or text hash is invalid",
  "coordinated downstream hashes cannot bless a stale receipt citation hash"
)

bad_receipt_relation <- copy_release("bad-receipt-relation")
bad_relation_receipt_path <- file.path(
  bad_receipt_relation, "data", "source_receipt.json"
)
bad_relation_receipt <- jsonlite::fromJSON(
  bad_relation_receipt_path, simplifyVector = TRUE,
  simplifyDataFrame = FALSE, simplifyMatrix = FALSE
)
bad_relation_receipt$relations$practical_field_rows <-
  as.integer(bad_relation_receipt$relations$practical_field_rows) + 1L
write_receipt(bad_relation_receipt_path, bad_relation_receipt)
bad_relation_contract_path <- file.path(
  bad_receipt_relation, "data", "release_contract.rds"
)
bad_relation_contract <- readRDS(bad_relation_contract_path)
bad_relation_contract$source <- inv_release_expected_source_from_receipt(
  bad_relation_receipt, bad_relation_receipt_path,
  bad_relation_contract$source$publication_date_max
)
for (site in INV_RELEASE_EXPECTED_SITES) {
  bundle_path <- file.path(
    bad_receipt_relation, "data", "sites", paste0(site, ".rds")
  )
  bundle <- readRDS(bundle_path)
  bundle$provenance$source <- bad_relation_contract$source
  inv_producer_save_rds(bundle, bundle_path)
  bad_relation_contract$bundle_sha256[[site]] <-
    inv_release_sha256(bundle_path)
}
invisible(file.copy(
  file.path(bad_receipt_relation, "data", "sites", "SYCA.rds"),
  file.path(bad_receipt_relation, "data-sample", "demo.rds"),
  overwrite = TRUE
))
bad_relation_search_path <- file.path(
  bad_receipt_relation, "data", "search_index.rds"
)
bad_relation_search <- readRDS(bad_relation_search_path)
bad_relation_search$source <- bad_relation_contract$source
inv_producer_save_rds(bad_relation_search, bad_relation_search_path)
inv_producer_save_rds(bad_relation_contract, bad_relation_contract_path)
expect_true(
  identical(inv_verify_release_data(bad_receipt_relation)$sites, 34L),
  paste(
    "synthetic bundle-only fixtures may retain internally coordinated",
    "non-production relation values"
  )
)
expect_error(
  inv_verify_release_against_source(
    bad_receipt_relation, artifact_path, bad_relation_receipt_path,
    production_exact = FALSE
  ),
  "receipt sampleID-primary relation field practical_field_rows differs",
  paste(
    "raw source authority rejects a relation-value, receipt-hash, bundle,",
    "search, and release-contract coordinated tamper"
  )
)

bad_artifact_size <- copy_release("bad-receipt-artifact-size")
bad_size_receipt_path <- file.path(
  bad_artifact_size, "data", "source_receipt.json"
)
bad_size_receipt <- jsonlite::fromJSON(
  bad_size_receipt_path, simplifyVector = TRUE, simplifyDataFrame = FALSE,
  simplifyMatrix = FALSE
)
bad_size_receipt$artifact$bytes <-
  as.numeric(bad_size_receipt$artifact$bytes) + 1
write_receipt(bad_size_receipt_path, bad_size_receipt)
bad_size_contract_path <- file.path(
  bad_artifact_size, "data", "release_contract.rds"
)
bad_size_contract <- readRDS(bad_size_contract_path)
bad_size_contract$source <- inv_release_expected_source_from_receipt(
  bad_size_receipt, bad_size_receipt_path,
  bad_size_contract$source$publication_date_max
)
for (site in INV_RELEASE_EXPECTED_SITES) {
  bundle_path <- file.path(
    bad_artifact_size, "data", "sites", paste0(site, ".rds")
  )
  bundle <- readRDS(bundle_path)
  bundle$provenance$source <- bad_size_contract$source
  inv_producer_save_rds(bundle, bundle_path)
  bad_size_contract$bundle_sha256[[site]] <- inv_release_sha256(bundle_path)
}
invisible(file.copy(
  file.path(bad_artifact_size, "data", "sites", "SYCA.rds"),
  file.path(bad_artifact_size, "data-sample", "demo.rds"),
  overwrite = TRUE
))
search_path <- file.path(bad_artifact_size, "data", "search_index.rds")
search <- readRDS(search_path)
search$source <- bad_size_contract$source
inv_producer_save_rds(search, search_path)
inv_producer_save_rds(bad_size_contract, bad_size_contract_path)
expect_true(
  identical(inv_verify_release_data(bad_artifact_size)$sites, 34L),
  "receipt-coordinated artifact size is structurally self-consistent"
)
expect_error(
  inv_verify_release_against_source(
    bad_artifact_size, artifact_path, bad_size_receipt_path,
    production_exact = FALSE
  ),
  "byte size differs",
  "raw artifact bytes reject a receipt/downstream-coordinated size tamper"
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

# Processing/count and record status are producer outputs, not primitive
# evidence. Coordinate a false status through every status/event/summary ledger
# and all downstream hashes; the verifier must still recompute it from the
# untouched sampling, processing, taxonomy, count, and area primitives.
bad_derived_status <- rewrite_bundle(
  "bad-derived-opportunity-status", "SYCA", function(bundle) {
    candidates <- which(
      bundle$opportunities$sampling_practical &
        bundle$opportunities$processing_count_status ==
          "taxonomy_count_available" &
        bundle$opportunities$record_status == "quantified_community"
    )
    if (!length(candidates)) stop("Fixture lacks a quantified status row")
    row <- candidates[[1L]]
    bundle$opportunities$processing_count_status[[row]] <-
      "taxonomy_count_unavailable"
    bundle$opportunities$record_status[[row]] <- "count_unavailable"
    bundle$event_strata <- inv_release_expected_events(bundle$opportunities)
    bundle$site_summary <- inv_release_expected_site_summary(
      bundle$opportunities, bundle$taxon_strata
    )
    status <- table(factor(
      bundle$opportunities$record_status,
      levels = INV_RELEASE_STATUS_LEVELS
    ))
    bundle$qc$status_counts <- data.frame(
      record_status = names(status), n = as.integer(status),
      stringsAsFactors = FALSE
    )
    bundle$qc$reconciliation$processing_count_status_counts <- table(factor(
      bundle$opportunities$processing_count_status[
        bundle$opportunities$sampling_practical
      ], levels = INV_RELEASE_PROCESSING_COUNT_STATUS_LEVELS
    ))
    bundle
  }
)
expect_error(
  inv_verify_release_data(bad_derived_status),
  "processing_count_status differs from primitive-field derivation",
  paste(
    "coordinated status-ledger/hash tamper cannot redefine processing/count",
    "or record-status precedence"
  )
)

bad_masked_processed_status <- rewrite_bundle(
  "bad-masked-processed-no-taxonomy", "SYCA", function(bundle) {
    candidates <- which(bundle$opportunities$taxonomy_rows == 0L)
    if (!length(candidates)) {
      stop("Fixture lacks a taxonomy-empty opportunity")
    }
    row <- candidates[[1L]]
    bundle$opportunities$samplerType[[row]] <- "(not recorded)"
    bundle$opportunities$sampler_type_normalized[[row]] <- NA_character_
    bundle$opportunities$grain_complete[[row]] <- FALSE
    bundle$opportunities$unstratifiable[[row]] <- TRUE
    bundle$opportunities$nonstandard_collection[[row]] <- FALSE
    bundle$opportunities$primary_stratum[[row]] <- FALSE
    bundle$opportunities$samplingImpractical[[row]] <- "OK"
    bundle$opportunities$sampling_practical[[row]] <- TRUE
    bundle$opportunities$has_per_sample[[row]] <- TRUE
    bundle$opportunities$processing_unknown[[row]] <- FALSE
    bundle$opportunities$taxonomy_count_unavailable[[row]] <- FALSE
    bundle$opportunities$processing_count_status[[row]] <-
      "processed_no_taxonomy"
    bundle$opportunities$record_status[[row]] <- "unstratifiable"
    bundle$event_strata <- inv_release_expected_events(bundle$opportunities)
    expected_summary <- inv_release_expected_site_summary(
      bundle$opportunities, bundle$taxon_strata
    )
    bundle$site_summary <- expected_summary
    # Recreate the stale producer behavior: count the primary record status,
    # which masks this real processing outcome behind `unstratifiable`.
    bundle$site_summary$n_processed_no_taxonomy <- 0L
    bundle$meta$n_events <- expected_summary$n_events
    bundle$meta$n_strata <- expected_summary$n_strata
    bundle$meta$n_primary_opportunities <- sum(
      bundle$opportunities$primary_stratum
    )
    bundle$meta$n_unstratifiable <- expected_summary$n_unstratifiable
    bundle$meta$n_processing_unknown <- expected_summary$n_processing_unknown
    status <- table(factor(
      bundle$opportunities$record_status,
      levels = INV_RELEASE_STATUS_LEVELS
    ))
    bundle$qc$status_counts <- data.frame(
      record_status = names(status), n = as.integer(status),
      stringsAsFactors = FALSE
    )
    bundle$qc$reconciliation$primary_opportunities <- sum(
      bundle$opportunities$primary_stratum
    )
    bundle$qc$reconciliation$unstratifiable <- sum(
      bundle$opportunities$unstratifiable
    )
    bundle$qc$reconciliation$processing_unknown <- sum(
      bundle$opportunities$processing_unknown
    )
    bundle$qc$reconciliation$processing_count_status_counts <- table(factor(
      bundle$opportunities$processing_count_status[
        bundle$opportunities$sampling_practical
      ], levels = INV_RELEASE_PROCESSING_COUNT_STATUS_LEVELS
    ))
    bundle$qc$reconciliation$practical_processing_count_opportunities <- sum(
      bundle$opportunities$sampling_practical
    )
    bundle
  }
)
expect_error(
  inv_verify_release_data(bad_masked_processed_status),
  "site summary differs",
  paste(
    "coordinated primary-status ledgers cannot erase a precedence-masked",
    "processed-no-taxonomy outcome"
  )
)

derivation_fixture <- readRDS(file.path(
  release_root, "data", "sites", "SYCA.rds"
))$opportunities
derived_row <- which(
  derivation_fixture$count_eligible & derivation_fixture$density_eligible &
    !derivation_fixture$reported_zero_count
)[[1L]]
bad_count_derivation <- derivation_fixture
bad_count_derivation$count_eligible[[derived_row]] <- FALSE
expect_error(
  inv_release_assert_opportunity_derivations(bad_count_derivation, "SYCA"),
  "count_eligible differs from primitive-field derivation",
  "bundle-only verifier independently derives count eligibility"
)
bad_density_derivation <- derivation_fixture
bad_density_derivation$density_eligible[[derived_row]] <- FALSE
expect_error(
  inv_release_assert_opportunity_derivations(bad_density_derivation, "SYCA"),
  "density_eligible differs from primitive-field derivation",
  "bundle-only verifier independently derives density eligibility"
)
bad_zero_derivation <- derivation_fixture
bad_zero_derivation$reported_zero_count[[derived_row]] <- TRUE
expect_error(
  inv_release_assert_opportunity_derivations(bad_zero_derivation, "SYCA"),
  "reported_zero_count differs from primitive-field derivation",
  "bundle-only verifier independently derives reported-zero status"
)
bad_record_derivation <- derivation_fixture
bad_record_derivation$record_status[[derived_row]] <- "count_unavailable"
expect_error(
  inv_release_assert_opportunity_derivations(bad_record_derivation, "SYCA"),
  "record_status differs from primitive-field derivation",
  "bundle-only verifier independently derives record-status precedence"
)

# Coordinate a Hill/classification edit through the producer-derived event
# ledger. Bundle-only arithmetic therefore remains self-consistent; the
# receipt-bound raw projection must still reject it.
bad_projection <- rewrite_bundle(
  "bad-complete-opportunity-projection", "SYCA", function(bundle) {
    eligible <- which(
      bundle$opportunities$count_eligible &
        bundle$opportunities$density_eligible &
        is.finite(bundle$opportunities$hill_q1) &
        is.finite(bundle$opportunities$hill_q2) &
        is.finite(bundle$opportunities$pct_ept_of_all_estimated_count) &
        is.finite(
          bundle$opportunities$pct_order_classified_estimated_count
        )
    )
    if (!length(eligible)) stop("Fixture lacks a complete metric row")
    row <- eligible[[1L]]
    bundle$opportunities$hill_q1[[row]] <-
      bundle$opportunities$hill_q1[[row]] + 0.125
    bundle$opportunities$hill_q2[[row]] <-
      bundle$opportunities$hill_q2[[row]] + 0.25
    bundle$opportunities$pct_ept_of_all_estimated_count[[row]] <-
      bundle$opportunities$pct_ept_of_all_estimated_count[[row]] + 0.5
    bundle$opportunities$pct_order_classified_estimated_count[[row]] <-
      bundle$opportunities$pct_order_classified_estimated_count[[row]] + 0.75
    bundle$event_strata <- inv_release_expected_events(bundle$opportunities)
    bundle
  }
)
expect_true(
  identical(inv_verify_release_data(bad_projection)$sites, 34L),
  "coordinated Hill/percent tamper passes bundle-only arithmetic"
)
expect_error(
  inv_verify_release_against_source(
    bad_projection, artifact_path, receipt_path, production_exact = FALSE
  ),
  "raw-to-bundle complete opportunity projection differs",
  "raw authority rejects coordinated Hill/percent opportunity tamper"
)

bad_annotation <- rewrite_bundle(
  "bad-issue-annotation", "SYCA", function(bundle) {
    if (!nrow(bundle$qc$issue_log)) stop("Fixture lacks issue-log rows")
    old <- as.character(bundle$qc$issue_log$site_scope_basis[[1L]])
    bundle$qc$issue_log$site_scope_basis[[1L]] <- if (
      identical(old, "scope_unspecified")
    ) "all_sites" else "scope_unspecified"
    bundle
  }
)
expect_true(
  identical(inv_verify_release_data(bad_annotation)$sites, 34L),
  "coordinated issue-annotation tamper passes bundle-only structure checks"
)
expect_error(
  inv_verify_release_against_source(
    bad_annotation, artifact_path, receipt_path, production_exact = FALSE
  ),
  "raw issue log and applicability annotations differs",
  "raw dates and issue scope reject coordinated applicability tamper"
)

bad_contract <- copy_release("bad-scientific-contract-authority")
contract_path <- file.path(bad_contract, "data", "release_contract.rds")
bad_contract_object <- readRDS(contract_path)
bad_contract_object$metric_contract$boundary[[1L]] <- "coordinated fiction"
for (site in INV_RELEASE_EXPECTED_SITES) {
  bundle_path <- file.path(bad_contract, "data", "sites", paste0(site, ".rds"))
  bundle <- readRDS(bundle_path)
  bundle$metric_contract <- bad_contract_object$metric_contract
  inv_producer_save_rds(bundle, bundle_path)
  bad_contract_object$bundle_sha256[[site]] <-
    inv_release_sha256(bundle_path)
}
search_path <- file.path(bad_contract, "data", "search_index.rds")
search <- readRDS(search_path)
search$metric_contract <- bad_contract_object$metric_contract
search$boundary <- "coordinated fiction"
inv_producer_save_rds(search, search_path)
inv_producer_save_rds(bad_contract_object, contract_path)
expect_error(
  inv_verify_release_data(bad_contract),
  "release metric contract differs",
  paste(
    "independent metric definition rejects coordinated contract, bundle,",
    "and search metric tampering"
  )
)

bad_prohibited <- copy_release("bad-prohibited-field-authority")
contract_path <- file.path(bad_prohibited, "data", "release_contract.rds")
contract <- readRDS(contract_path)
contract$prohibited_cross_site_fields <-
  head(contract$prohibited_cross_site_fields, -1L)
inv_producer_save_rds(contract, contract_path)
expect_error(
  inv_verify_release_data(bad_prohibited),
  "prohibited cross-site field roster is not exact",
  "independent prohibited-field roster rejects candidate-authority deletion"
)

bad_qc_policy <- copy_release("bad-qc-policy-authority")
contract_path <- file.path(bad_qc_policy, "data", "release_contract.rds")
contract <- readRDS(contract_path)
contract$qc_contract$source <- "coordinated fiction"
for (site in INV_RELEASE_EXPECTED_SITES) {
  bundle_path <- file.path(bad_qc_policy, "data", "sites", paste0(site, ".rds"))
  bundle <- readRDS(bundle_path)
  bundle$qc$contract <- contract$qc_contract
  bundle$provenance$qc_contract <- contract$qc_contract
  inv_producer_save_rds(bundle, bundle_path)
  contract$bundle_sha256[[site]] <- inv_release_sha256(bundle_path)
}
inv_producer_save_rds(contract, contract_path)
expect_error(
  inv_verify_release_data(bad_qc_policy),
  "official QC policy is not exact",
  "independent QC policy rejects coordinated contract and bundle tampering"
)

bad_comparison_boundary <- rewrite_bundle(
  "bad-comparison-boundary", "SYCA", function(bundle) {
    bundle$meta$comparison_boundary <- "coordinated fiction"
    bundle
  }
)
expect_error(
  inv_verify_release_data(bad_comparison_boundary),
  "scientific honesty/provenance boundary differs",
  "exact bundle comparison boundary is independently pinned"
)

bad_exact_grain <- rewrite_bundle(
  "bad-exact-grain", "SYCA", function(bundle) {
    bundle$provenance$exact_grain <- "coordinated fiction"
    bundle
  }
)
expect_error(
  inv_verify_release_data(bad_exact_grain),
  "scientific honesty/provenance boundary differs",
  "exact-grain provenance string is independently pinned"
)

bad_prohibited_inference <- rewrite_bundle(
  "bad-prohibited-inference", "SYCA", function(bundle) {
    bundle$provenance$prohibited_inference <- "coordinated fiction"
    bundle
  }
)
expect_error(
  inv_verify_release_data(bad_prohibited_inference),
  "scientific honesty/provenance boundary differs",
  "prohibited-inference provenance is independently pinned"
)

bad_search_boundary <- copy_release("bad-search-boundary")
search_path <- file.path(bad_search_boundary, "data", "search_index.rds")
search <- readRDS(search_path)
search$boundary <- "coordinated fiction"
inv_producer_save_rds(search, search_path)
expect_error(
  inv_verify_release_data(bad_search_boundary),
  "Search scientific boundary differs",
  "search-index scientific boundary is independently pinned"
)

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
  inv_verify_release_against_source(
    bad_identity, artifact_path, receipt_path, production_exact = FALSE
  ),
  "raw-to-bundle opportunity identity differs",
  "raw-source handoff detects a bundle identity tamper"
)

tampered_artifact <- file.path(source_dir, "tampered-source.rds")
tampered_source <- readRDS(artifact_path)
tampered_source$inv_fieldData$sampleNumber[[1L]] <- "tampered"
inv_producer_save_rds(tampered_source, tampered_artifact)
expect_error(
  inv_verify_release_against_source(
    release_root, tampered_artifact, receipt_path, production_exact = FALSE
  ),
  "Raw source hash differs",
  "downloaded raw bytes must match the immutable source receipt"
)

cat(sprintf("Inverts adversarial release-verifier fixtures passed (%d checks).\n",
            checks))
