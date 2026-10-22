#!/usr/bin/env Rscript

# Independent headline oracles for the five hero metrics.
#
# Suite gate: every headline metric has at least one oracle that is never
# recomputed with the rule it checks. This file therefore does not source the
# producer, the science transform, or the release verifier. It compares each
# shipped bundle and data/site_index.rds against (1) a literal table frozen from
# the audited RELEASE-2026 build and (2) identities that read only verbatim
# NEON rows carried in each bundle and the committed source receipt.
#
# INV_HEADLINE_ORACLE was frozen once from the committed, audited RELEASE-2026
# data/site_index.rds. It may be re-baselined only inside the documented
# release-bump procedure, together with INV_HEADLINE_ORACLE_RELEASE. Never edit
# it to make a refresh pass.

INV_HEADLINE_ORACLE_RELEASE <- "RELEASE-2026"

INV_HEADLINE_ORACLE <- data.frame(
  stringsAsFactors = FALSE,
  site = c("ARIK", "BARC", "BIGC", "BLDE", "BLUE", "BLWA", "CARI", "COMO",
           "CRAM", "CUPE", "FLNT", "GUIL", "HOPB", "KING", "LECO", "LEWI",
           "LIRO", "MART", "MAYF", "MCDI", "MCRA", "OKSR", "POSE", "PRIN",
           "PRLA", "PRPO", "REDB", "SUGG", "SYCA", "TECR", "TOMB", "TOOK",
           "WALK", "WLOU"),
  n_opportunities = c(253L, 256L, 168L, 168L, 192L, 201L, 208L, 224L,
                      232L, 248L, 192L, 242L, 200L, 240L, 224L, 200L,
                      192L, 168L, 251L, 139L, 184L, 200L, 256L, 208L,
                      250L, 248L, 224L, 256L, 193L, 136L, 200L, 205L,
                      240L, 200L),
  n_count_samples = c(194L, 234L, 132L, 119L, 160L, 185L, 197L, 172L,
                      225L, 209L, 173L, 184L, 190L, 165L, 215L, 190L,
                      189L, 159L, 229L, 100L, 149L, 189L, 226L, 172L,
                      236L, 241L, 167L, 233L, 121L, 96L, 164L, 198L,
                      228L, 172L),
  n_density_samples = c(194L, 234L, 132L, 119L, 160L, 185L, 197L, 172L,
                        225L, 209L, 173L, 184L, 190L, 165L, 215L, 190L,
                        189L, 159L, 229L, 100L, 149L, 189L, 226L, 172L,
                        236L, 241L, 167L, 233L, 121L, 96L, 164L, 198L,
                        228L, 172L),
  n_taxa_recorded = c(363L, 248L, 323L, 264L, 282L, 270L, 216L, 274L,
                      286L, 195L, 300L, 210L, 397L, 248L, 357L, 278L,
                      266L, 300L, 343L, 246L, 291L, 209L, 431L, 316L,
                      162L, 143L, 267L, 243L, 245L, 274L, 226L, 216L,
                      337L, 223L),
  n_events = c(28L, 30L, 17L, 15L, 20L, 25L, 25L, 22L,
               29L, 29L, 23L, 29L, 25L, 26L, 28L, 24L,
               24L, 20L, 30L, 20L, 19L, 24L, 31L, 23L,
               31L, 31L, 22L, 30L, 17L, 12L, 24L, 25L,
               29L, 23L)
)

INV_HEADLINE_ORACLE_METRICS <- c(
  "n_opportunities", "n_count_samples", "n_density_samples",
  "n_taxa_recorded", "n_events"
)

inv_headline_oracle_fail <- function(...) {
  stop(sprintf("Headline oracle failed: %s", sprintf(...)), call. = FALSE)
}

inv_headline_oracle_int <- function(value) {
  if (length(value) != 1L) return(NA_integer_)
  number <- suppressWarnings(as.numeric(as.character(value)))
  if (is.na(number) || number != round(number)) return(NA_integer_)
  as.integer(number)
}

inv_verify_headline_oracles <- function(root = ".") {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    inv_headline_oracle_fail("jsonlite is required to read data/source_receipt.json")
  }
  oracle <- INV_HEADLINE_ORACLE
  sites <- oracle$site
  bundle_dir <- file.path(root, "data", "sites")
  shipped <- sort(sub("[.]rds$", "", list.files(bundle_dir, pattern = "[.]rds$")))
  if (!identical(shipped, sort(sites))) {
    inv_headline_oracle_fail(
      "shipped bundles [%s] differ from the frozen %d-site oracle roster",
      paste(shipped, collapse = ", "), length(sites)
    )
  }

  site_index_path <- file.path(root, "data", "site_index.rds")
  if (!file.exists(site_index_path)) {
    inv_headline_oracle_fail("missing data/site_index.rds")
  }
  site_index <- as.data.frame(readRDS(site_index_path), stringsAsFactors = FALSE)
  missing_columns <- setdiff(c("site", INV_HEADLINE_ORACLE_METRICS), names(site_index))
  if (length(missing_columns)) {
    inv_headline_oracle_fail("data/site_index.rds lacks column(s): %s",
                             paste(missing_columns, collapse = ", "))
  }
  if (!identical(sort(as.character(site_index$site)), sort(sites))) {
    inv_headline_oracle_fail("data/site_index.rds roster differs from the frozen oracle")
  }

  network_opportunities <- 0L
  for (row in seq_len(nrow(oracle))) {
    site <- sites[[row]]
    bundle <- readRDS(file.path(bundle_dir, paste0(site, ".rds")))

    release <- bundle$provenance$source$release
    if (!identical(release, INV_HEADLINE_ORACLE_RELEASE)) {
      inv_headline_oracle_fail(
        paste0("%s bundle provenance release is %s, but the oracle is frozen ",
               "at %s; re-baseline the frozen headline oracle as part of the ",
               "release-bump procedure"),
        site, if (is.null(release)) "missing" else paste(release, collapse = "/"),
        INV_HEADLINE_ORACLE_RELEASE
      )
    }

    index_row <- site_index[as.character(site_index$site) == site, , drop = FALSE]
    if (nrow(index_row) != 1L) {
      inv_headline_oracle_fail("data/site_index.rds has %d rows for %s",
                               nrow(index_row), site)
    }
    for (metric in INV_HEADLINE_ORACLE_METRICS) {
      expected <- oracle[[metric]][[row]]
      meta_value <- inv_headline_oracle_int(bundle$meta[[metric]])
      index_value <- inv_headline_oracle_int(index_row[[metric]][[1L]])
      if (!identical(meta_value, expected)) {
        inv_headline_oracle_fail("%s bundle meta %s is %s; the frozen oracle is %d",
                                 site, metric, meta_value, expected)
      }
      if (!identical(index_value, expected)) {
        inv_headline_oracle_fail("%s site_index %s is %s; the frozen oracle is %d",
                                 site, metric, index_value, expected)
      }
    }

    # Verbatim NEON field rows retained in the bundle, minus metabarcoding
    # (.DNA) rows, are the opportunity population.
    field <- bundle$qc$source_quality$field
    if (!is.data.frame(field) || !"sampleID" %in% names(field)) {
      inv_headline_oracle_fail("%s bundle lacks verbatim qc$source_quality$field rows",
                               site)
    }
    dna_rows <- sum(grepl("[.]DNA$", as.character(field$sampleID)))
    retained_rows <- nrow(field) - dna_rows
    if (!identical(as.integer(retained_rows), oracle$n_opportunities[[row]])) {
      inv_headline_oracle_fail(
        "%s retains %d non-.DNA NEON field rows (%d rows, %d .DNA) but n_opportunities is %d",
        site, retained_rows, nrow(field), dna_rows, oracle$n_opportunities[[row]]
      )
    }

    event_ids <- bundle$event_strata$eventID
    if (is.null(event_ids)) {
      inv_headline_oracle_fail("%s bundle lacks event_strata$eventID", site)
    }
    distinct_events <- length(unique(event_ids))
    if (!identical(as.integer(distinct_events), oracle$n_events[[row]])) {
      inv_headline_oracle_fail("%s has %d distinct event_strata eventIDs but n_events is %d",
                               site, distinct_events, oracle$n_events[[row]])
    }

    network_opportunities <- network_opportunities + oracle$n_opportunities[[row]]
  }

  receipt_path <- file.path(root, "data", "source_receipt.json")
  if (!file.exists(receipt_path)) {
    inv_headline_oracle_fail("missing data/source_receipt.json")
  }
  receipt <- jsonlite::fromJSON(receipt_path, simplifyVector = FALSE)
  collection_rows <- inv_headline_oracle_int(receipt$segregation$collection_field_rows)
  practical_rows <- inv_headline_oracle_int(receipt$relations$practical_field_rows)
  impractical_rows <- inv_headline_oracle_int(receipt$relations$impractical_field_rows)
  if (!identical(collection_rows, network_opportunities)) {
    inv_headline_oracle_fail(
      "network n_opportunities sums to %d but the source receipt has %s collection field rows",
      network_opportunities, collection_rows
    )
  }
  if (anyNA(c(practical_rows, impractical_rows)) ||
      !identical(practical_rows + impractical_rows, network_opportunities)) {
    inv_headline_oracle_fail(
      "network n_opportunities sums to %d but receipt practical + impractical field rows are %s + %s",
      network_opportunities, practical_rows, impractical_rows
    )
  }

  invisible(list(
    release = INV_HEADLINE_ORACLE_RELEASE,
    sites = length(sites),
    network_opportunities = network_opportunities
  ))
}
