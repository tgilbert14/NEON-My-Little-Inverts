#!/usr/bin/env Rscript

# Deterministic RELEASE-2026 producer for the Pass-9 My Little Inverts bundle.
# The raw field table remains the opportunity population. All derived tables are
# built by build_inv_science_contract(); this producer only partitions, records
# provenance, and creates support-only indexes without cross-site ecological ranks.

if (!exists("inv_verify_source_receipt", mode = "function")) {
  source("scripts/inv_source_contract.R", local = TRUE)
}
if (!exists("build_inv_science_contract", mode = "function")) {
  source("scripts/inv_science_contract.R", local = TRUE)
}

INV_PRODUCER_SCHEMA_VERSION <- "2.1.0"
INV_BUNDLE_SCHEMA_VERSION <- "2.1.0"
INV_RELEASE_CONTRACT_SCHEMA_VERSION <- "1.0.0"
INV_QC_AUDIT_SCHEMA_VERSION <- "1.0.0"

inv_producer_fail <- function(...) stop(sprintf(...), call. = FALSE)

inv_producer_assert <- function(ok, ...) {
  if (!isTRUE(ok)) inv_producer_fail(...)
}

inv_producer_num <- function(x) suppressWarnings(as.numeric(as.character(x)))

inv_producer_dates <- function(x) {
  if (inherits(x, "Date")) {
    date_value <- as.Date(x)
    raw_days <- unclass(date_value)
    out <- rep(as.Date(NA), length(date_value))
    valid <- !is.na(raw_days) & is.finite(raw_days) & raw_days == floor(raw_days)
    if (any(valid)) {
      calendar <- format(date_value[valid], "%Y-%m-%d")
      round_trip <- suppressWarnings(as.Date(calendar, format = "%Y-%m-%d"))
      exact <- !is.na(round_trip) & unclass(round_trip) == raw_days[valid]
      out[which(valid)[exact]] <- round_trip[exact]
    }
    return(out)
  }
  if (inherits(x, "POSIXt")) {
    instant <- suppressWarnings(as.POSIXct(x))
    value <- format(instant, "%Y-%m-%d", tz = "UTC", usetz = FALSE)
    out <- suppressWarnings(as.Date(value, format = "%Y-%m-%d"))
    out[is.na(instant) | !is.finite(unclass(instant))] <- as.Date(NA)
    return(out)
  }

  # Raw numeric encodings are ambiguous (for example, epoch days versus a
  # compact calendar stamp) and are never authoritative publication dates.
  if (!is.character(x) && !is.factor(x)) {
    return(rep(as.Date(NA), length(x)))
  }

  value <- as.character(x)
  out <- rep(as.Date(NA), length(value))
  compact_neon <- !is.na(value) & grepl(
    "^[0-9]{8}T([01][0-9]|2[0-3])[0-5][0-9][0-5][0-9]Z$", value
  )
  iso_utc <- !is.na(value) & grepl(
    paste0(
      "^[0-9]{4}-[0-9]{2}-[0-9]{2}T",
      "([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]Z$"
    ),
    value
  )
  iso_date <- !is.na(value) & grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", value)

  parse_datetime <- function(mask, format_string) {
    rows <- which(mask)
    if (!length(rows)) return(invisible(NULL))
    parsed <- suppressWarnings(strptime(
      value[rows], format = format_string, tz = "UTC"
    ))
    round_trip <- format(
      parsed, format = format_string, tz = "UTC", usetz = FALSE
    )
    valid <- !is.na(parsed) & !is.na(round_trip) &
      round_trip == value[rows]
    if (any(valid)) {
      calendar <- format(
        parsed[valid], format = "%Y-%m-%d", tz = "UTC", usetz = FALSE
      )
      out[rows[valid]] <<- as.Date(calendar, format = "%Y-%m-%d")
    }
    invisible(NULL)
  }

  parse_datetime(compact_neon, "%Y%m%dT%H%M%SZ")
  parse_datetime(iso_utc, "%Y-%m-%dT%H:%M:%SZ")
  date_rows <- which(iso_date)
  if (length(date_rows)) {
    parsed <- suppressWarnings(as.Date(
      value[date_rows], format = "%Y-%m-%d"
    ))
    valid <- !is.na(parsed) & format(parsed, "%Y-%m-%d") == value[date_rows]
    out[date_rows[valid]] <- parsed[valid]
  }
  out
}

inv_producer_qc_contract <- function() {
  list(
    schema_version = INV_QC_AUDIT_SCHEMA_VERSION,
    source = "Official DP1.20120.001 RELEASE-2026 vF QC",
    retain_verbatim = TRUE,
    automatic_exclusion = FALSE,
    eligibility_effect = "none",
    table_fields = INV_VF_QC_COLUMNS,
    issue_log_fields = INV_ISSUE_LOG_COLUMNS,
    issue_annotation_fields = c(
      "bundle_site", "site_scope_basis", "site_scope_match",
      "site_collect_date_min", "site_collect_date_max",
      "date_scope_basis", "date_overlap", "potentially_applicable",
      "annotation_only"
    )
  )
}

inv_producer_median <- function(x) {
  x <- inv_producer_num(x)
  x <- x[is.finite(x)]
  if (length(x)) stats::median(x) else NA_real_
}

inv_producer_save_rds <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(x, path, version = 3, compress = "xz")
  invisible(path)
}

inv_producer_publication_stamp <- function(source) {
  dates_by_table <- lapply(INV_REQUIRED_TABLES, function(table_name) {
    raw <- source[[table_name]]$publicationDate
    parsed <- inv_producer_dates(raw)
    inv_producer_assert(
      length(parsed) == length(raw) && !anyNA(parsed),
      "Verified source has an unparseable publicationDate in %s",
      table_name
    )
    parsed
  })
  dates <- unlist(dates_by_table, use.names = FALSE)
  dates <- as.Date(dates, origin = "1970-01-01")
  inv_producer_assert(length(dates) > 0L,
                      "Verified source has no usable publicationDate stamp")
  format(max(dates), "%Y-%m-%d")
}

inv_producer_source_provenance <- function(receipt, receipt_path, source_stamp) {
  table_rows <- vapply(INV_REQUIRED_TABLES, function(table_name) {
    as.integer(receipt$required_tables[[table_name]]$row_count)
  }, integer(1))
  metadata_rows <- vapply(INV_REQUIRED_METADATA, function(table_name) {
    as.integer(receipt$required_metadata[[table_name]]$row_count)
  }, integer(1))
  list(
    dpid = as.character(receipt$source_request$dpid),
    release = as.character(receipt$source_request$release),
    include_provisional = isTRUE(receipt$source_request$include_provisional),
    package = as.character(receipt$source_request$package),
    doi = as.character(receipt$release$doi),
    doi_url = as.character(receipt$release$doi_url),
    product_url = as.character(receipt$release$product_url),
    fetched_at_utc = as.character(receipt$fetched_at_utc),
    publication_date_max = source_stamp,
    artifact_file = as.character(receipt$artifact$file),
    artifact_bytes = as.numeric(receipt$artifact$bytes),
    artifact_sha256 = as.character(receipt$artifact$sha256),
    receipt_schema_version = as.character(receipt$receipt_schema_version),
    receipt_sha256 = inv_sha256_file(receipt_path),
    citation_object = as.character(receipt$citation$object),
    citation_sha256 = as.character(receipt$citation$sha256),
    table_rows = table_rows,
    metadata_rows = metadata_rows,
    segregation = receipt$segregation,
    producer_git_sha = as.character(receipt$producer$git_sha),
    producer_r_version = as.character(receipt$producer$r_version),
    neonUtilities_version = as.character(receipt$producer$neonUtilities_version),
    neonUtilities_source = as.character(receipt$producer$neonUtilities_source)
  )
}

inv_producer_site_source_counts <- function(source) {
  field <- source$inv_fieldData
  dna <- !inv_science_blank(field$sampleID) &
    grepl("[.]DNA$", trimws(as.character(field$sampleID)))
  collection <- field[!dna, , drop = FALSE]
  metabarcode <- field[dna, , drop = FALSE]
  mapped_field <- field[!inv_science_blank(field$sampleID), , drop = FALSE]
  mapped_field$sample_key <- inv_science_pair_key(
    mapped_field$sampleID, mapped_field$sampleCode
  )
  inv_producer_assert(!anyDuplicated(mapped_field$sample_key),
                      "Raw field sampleID-to-site map is ambiguous")
  pair_to_site <- stats::setNames(as.character(mapped_field$siteID),
                                  mapped_field$sample_key)

  per_sample <- source$inv_persample
  per_keys <- inv_science_pair_key(per_sample$sampleID, per_sample$sampleCode)
  per_sites <- unname(pair_to_site[per_keys])
  taxonomy <- source$inv_taxonomyProcessed
  tax_keys <- inv_science_pair_key(taxonomy$sampleID, taxonomy$sampleCode)
  tax_sites <- unname(pair_to_site[tax_keys])

  rows <- lapply(INV_EXPECTED_SITES, function(site) {
    data.frame(
      site = site,
      collection_field_rows = sum(as.character(collection$siteID) == site),
      metabarcode_field_rows = sum(as.character(metabarcode$siteID) == site),
      per_sample_rows = sum(per_sites == site, na.rm = TRUE),
      taxonomy_processed_rows = sum(tax_sites == site, na.rm = TRUE),
      field_qc_rows = sum(as.character(field$siteID) == site),
      per_sample_qc_rows = sum(per_sites == site, na.rm = TRUE),
      taxonomy_qc_rows = sum(tax_sites == site, na.rm = TRUE),
      issue_log_rows = nrow(source$issueLog_20120),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

inv_producer_sample_site_map <- function(source) {
  field <- source$inv_fieldData
  field$sample_key <- inv_science_pair_key(field$sampleID, field$sampleCode)
  field <- field[
    !inv_science_blank(field$sampleID),
    c("sample_key", "siteID"), drop = FALSE
  ]
  duplicate_keys <- unique(field$sample_key[duplicated(field$sample_key)])
  ambiguous <- duplicate_keys[vapply(duplicate_keys, function(key) {
    length(unique(as.character(field$siteID[field$sample_key == key]))) > 1L
  }, logical(1))]
  inv_producer_assert(!length(ambiguous),
                      "sampleID maps to multiple sites: %s",
                      paste(ambiguous, collapse = ", "))
  field <- field[!duplicated(field$sample_key), , drop = FALSE]
  stats::setNames(as.character(field$siteID), field$sample_key)
}

inv_producer_map_child_sites <- function(table, site_map, label) {
  keys <- inv_science_pair_key(table$sampleID, table$sampleCode)
  sites <- unname(site_map[keys])
  inv_producer_assert(!anyNA(sites),
                      "%s has source QC row(s) without a field-site mapping",
                      label)
  sites
}

inv_producer_issue_annotations <- function(issue_log, site, collect_dates) {
  out <- issue_log[, INV_ISSUE_LOG_COLUMNS, drop = FALSE]
  site_dates <- inv_producer_dates(collect_dates)
  site_dates <- site_dates[!is.na(site_dates)]
  inv_producer_assert(length(site_dates) > 0L,
                      "%s has no collection dates for issue applicability", site)
  site_min <- min(site_dates)
  site_max <- max(site_dates)

  locations <- trimws(as.character(out$locationAffected))
  location_blank <- is.na(locations) | !nzchar(locations)
  site_pattern <- paste0("(^|[^A-Z0-9])", site, "([^A-Z0-9]|$)")
  explicit_match <- !location_blank & grepl(
    site_pattern, toupper(locations), perl = TRUE
  )
  all_scope <- !location_blank & grepl(
    "(^|[^A-Z])(ALL|NETWORK[ -]?WIDE|ALL SITES)([^A-Z]|$)",
    toupper(locations), perl = TRUE
  )
  site_basis <- ifelse(
    explicit_match, "explicit_site_match",
    ifelse(location_blank, "scope_unspecified",
           ifelse(all_scope, "all_sites", "not_machine_resolved"))
  )
  site_match <- rep(NA, nrow(out))
  site_match[explicit_match | location_blank | all_scope] <- TRUE

  start_raw <- as.character(out$dateRangeStart)
  end_raw <- as.character(out$dateRangeEnd)
  start_blank <- is.na(start_raw) | !nzchar(trimws(start_raw))
  end_blank <- is.na(end_raw) | !nzchar(trimws(end_raw))
  start_date <- inv_producer_dates(start_raw)
  end_date <- inv_producer_dates(end_raw)
  unparseable <- (!start_blank & is.na(start_date)) |
    (!end_blank & is.na(end_date))
  unspecified <- start_blank & end_blank
  overlap <- rep(NA, nrow(out))
  comparable <- !unparseable & !unspecified
  after_site <- comparable & !is.na(start_date) & start_date > site_max
  before_site <- comparable & !is.na(end_date) & end_date < site_min
  overlap[comparable] <- !(after_site[comparable] | before_site[comparable])
  date_basis <- ifelse(
    unparseable, "unparseable_date_range",
    ifelse(unspecified, "date_range_unspecified",
           ifelse(overlap, "overlaps_site_collection_range",
                  "outside_site_collection_range"))
  )

  potentially_applicable <- rep(NA, nrow(out))
  resolved_site <- !is.na(site_match)
  resolved_date <- unspecified | !is.na(overlap)
  resolved <- resolved_site & resolved_date
  potentially_applicable[resolved] <-
    site_match[resolved] & (unspecified[resolved] | overlap[resolved])

  out$bundle_site <- rep(site, nrow(out))
  out$site_scope_basis <- site_basis
  out$site_scope_match <- site_match
  out$site_collect_date_min <- rep(format(site_min, "%Y-%m-%d"), nrow(out))
  out$site_collect_date_max <- rep(format(site_max, "%Y-%m-%d"), nrow(out))
  out$date_scope_basis <- date_basis
  out$date_overlap <- overlap
  out$potentially_applicable <- potentially_applicable
  out$annotation_only <- rep(TRUE, nrow(out))
  out
}

inv_producer_source_qc <- function(source) {
  for (table_name in names(INV_VF_QC_COLUMNS)) {
    missing <- setdiff(INV_VF_QC_COLUMNS[[table_name]],
                       names(source[[table_name]]))
    inv_producer_assert(!length(missing),
                        "%s lacks official vF QC field(s): %s", table_name,
                        paste(missing, collapse = ", "))
  }
  missing_issues <- setdiff(INV_ISSUE_LOG_COLUMNS,
                            names(source$issueLog_20120))
  inv_producer_assert(!length(missing_issues),
                      "issueLog_20120 lacks official field(s): %s",
                      paste(missing_issues, collapse = ", "))

  field <- source$inv_fieldData
  per_sample <- source$inv_persample
  taxonomy <- source$inv_taxonomyProcessed
  site_map <- inv_producer_sample_site_map(source)
  per_sites <- inv_producer_map_child_sites(per_sample, site_map,
                                            "inv_persample")
  tax_sites <- inv_producer_map_child_sites(taxonomy, site_map,
                                            "inv_taxonomyProcessed")
  # Retain the complete official primary-key identity beside every QC value.
  # Abbreviated identities are not sufficient for impractical field rows or
  # repeated taxonomy size classes, where the omitted key fields can differ.
  field_identity <- c(
    "siteID", "namedLocation", "eventID", "sampleID", "sampleCode",
    "habitatType", "samplerType", "sampleNumber", "collectDate"
  )
  per_identity <- c("sampleID", "sampleCode")
  tax_identity <- c(
    "uid", "sampleID", "sampleCode", "scientificName",
    "morphospeciesID", "invertebrateLifeStage", "sizeClass", "sizeCategory",
    "immatureSpecimen", "indeterminateSpecies", "taxonRankQualifier",
    "sampleCondition", "distinctTaxon", "identificationRemarks",
    "acceptedTaxonID", "taxonRank"
  )

  stats::setNames(lapply(INV_EXPECTED_SITES, function(site) {
    field_rows <- field[as.character(field$siteID) == site,
                        c(field_identity, INV_VF_QC_COLUMNS$inv_fieldData),
                        drop = FALSE]
    per_rows <- per_sample[per_sites == site,
                           c(per_identity, INV_VF_QC_COLUMNS$inv_persample),
                           drop = FALSE]
    per_rows <- data.frame(siteID = rep(site, nrow(per_rows)), per_rows,
                           check.names = FALSE, stringsAsFactors = FALSE)
    tax_rows <- taxonomy[tax_sites == site,
                         c(tax_identity,
                           INV_VF_QC_COLUMNS$inv_taxonomyProcessed),
                         drop = FALSE]
    tax_rows <- data.frame(siteID = rep(site, nrow(tax_rows)), tax_rows,
                           check.names = FALSE, stringsAsFactors = FALSE)
    list(
      field = field_rows,
      per_sample = per_rows,
      taxonomy_processed = tax_rows,
      issue_log = inv_producer_issue_annotations(
        source$issueLog_20120, site, field_rows$collectDate
      )
    )
  }), INV_EXPECTED_SITES)
}

inv_producer_site_context <- function(source, site) {
  field <- source$inv_fieldData
  dna <- !inv_science_blank(field$sampleID) &
    grepl("[.]DNA$", trimws(as.character(field$sampleID)))
  field <- field[!dna & as.character(field$siteID) == site, , drop = FALSE]
  water_types <- sort(unique(inv_science_chr(field$aquaticSiteType)))
  list(
    aquatic_site_types = water_types,
    aquaticSiteType = paste(water_types, collapse = " | "),
    lat = inv_producer_median(field$decimalLatitude),
    lng = inv_producer_median(field$decimalLongitude),
    elevation = inv_producer_median(field$elevation),
    named_location_count = length(unique(inv_science_chr(field$namedLocation)))
  )
}

inv_producer_site_qc <- function(opportunities, source_counts, status_levels,
                                 source_qc, qc_contract) {
  status_counts <- table(factor(opportunities$record_status,
                                levels = status_levels))
  status_table <- data.frame(
    record_status = names(status_counts),
    n = as.integer(status_counts),
    stringsAsFactors = FALSE
  )
  list(
    contract = qc_contract,
    status_counts = status_table,
    source_rows = source_counts,
    source_quality = source_qc[c("field", "per_sample", "taxonomy_processed")],
    issue_log = source_qc$issue_log,
    reconciliation = list(
      opportunity_rows = nrow(opportunities),
      status_rows = sum(status_table$n),
      primary_opportunities = sum(opportunities$primary_stratum),
      count_eligible_samples = sum(opportunities$count_eligible),
      composition_eligible_samples = sum(
        opportunities$count_eligible &
          is.finite(opportunities$total_estimated_count) &
          opportunities$total_estimated_count > 0
      ),
      density_eligible_samples = sum(opportunities$density_eligible),
      reported_zero_count = sum(opportunities$reported_zero_count),
      unstratifiable = sum(opportunities$unstratifiable),
      processing_unknown = sum(opportunities$processing_unknown),
      taxonomy_count_unavailable = sum(
        opportunities$taxonomy_count_unavailable
      ),
      displayed_zero_percent_authoritative_estimate = sum(
        opportunities$displayed_zero_percent_authoritative_estimate
      ),
      practical_processing_count_opportunities = sum(
        opportunities$sampling_practical
      ),
      processing_count_status_counts = table(factor(
        opportunities$processing_count_status[opportunities$sampling_practical],
        levels = INV_PROCESSING_COUNT_STATUS_LEVELS
      )),
      taxonomy_rows_collapsed = sum(opportunities$taxonomy_rows),
      opportunity_complete = identical(nrow(opportunities),
                                       as.integer(source_counts$collection_field_rows)),
      count_contains_density = all(
        !opportunities$density_eligible | opportunities$count_eligible
      ),
      source_qc_rows_retained = c(
        field = nrow(source_qc$field),
        per_sample = nrow(source_qc$per_sample),
        taxonomy_processed = nrow(source_qc$taxonomy_processed),
        issue_log = nrow(source_qc$issue_log)
      ),
      qc_alters_metric_eligibility = FALSE
    )
  )
}

inv_producer_bundle <- function(site, science, source, source_counts,
                                source_provenance, source_qc, qc_contract) {
  opportunities <- science$opportunities[
    science$opportunities$siteID == site, , drop = FALSE
  ]
  event_strata <- science$event_strata[
    science$event_strata$siteID == site, , drop = FALSE
  ]
  taxon_strata <- science$taxon_strata[
    science$taxon_strata$siteID == site, , drop = FALSE
  ]
  site_summary <- science$site_summary[
    science$site_summary$siteID == site, , drop = FALSE
  ]
  inv_producer_assert(nrow(opportunities) > 0L,
                      "Science contract has no opportunity rows for %s", site)
  inv_producer_assert(nrow(site_summary) == 1L,
                      "Science contract has %d site-summary rows for %s",
                      nrow(site_summary), site)

  context <- inv_producer_site_context(source, site)
  counts <- source_counts[source_counts$site == site, , drop = FALSE]
  status_levels <- names(science$summary$status_counts)
  qc <- inv_producer_site_qc(
    opportunities, counts, status_levels, source_qc, qc_contract
  )
  inv_producer_assert(isTRUE(qc$reconciliation$opportunity_complete),
                      "Field-first opportunity reconciliation failed for %s", site)

  composition_samples <- sum(
    opportunities$count_eligible &
      is.finite(opportunities$total_estimated_count) &
      opportunities$total_estimated_count > 0
  )
  meta <- list(
    schema_version = INV_BUNDLE_SCHEMA_VERSION,
    site = site,
    source_stamp = source_provenance$publication_date_max,
    built = source_provenance$publication_date_max,
    release = source_provenance$release,
    collectDate_min = as.character(site_summary$collectDate_min),
    collectDate_max = as.character(site_summary$collectDate_max),
    aquaticSiteType = context$aquaticSiteType,
    aquatic_site_types = context$aquatic_site_types,
    lat = context$lat,
    lng = context$lng,
    elevation = context$elevation,
    named_location_count = context$named_location_count,
    n_events = as.integer(site_summary$n_events),
    n_strata = as.integer(site_summary$n_strata),
    n_opportunities = nrow(opportunities),
    n_primary_opportunities = sum(opportunities$primary_stratum),
    n_count_samples = sum(opportunities$count_eligible),
    n_composition_samples = composition_samples,
    n_density_samples = sum(opportunities$density_eligible),
    n_reported_zero_count = sum(opportunities$reported_zero_count),
    n_unstratifiable = sum(opportunities$unstratifiable),
    n_processing_unknown = sum(opportunities$processing_unknown),
    n_taxonomy_count_unavailable = sum(
      opportunities$taxonomy_count_unavailable
    ),
    n_displayed_zero_percent_authoritative_estimate = sum(
      opportunities$displayed_zero_percent_authoritative_estimate
    ),
    n_taxa_recorded = as.integer(site_summary$n_taxa_recorded),
    taxonomic_ranks = as.character(site_summary$taxonomic_ranks),
    comparison_boundary = paste(
      "Exact site x event x aquaticSiteType x habitatType x samplerType strata;",
      "no site-health score and no raw-density cross-site rank."
    )
  )

  list(
    schema_version = INV_BUNDLE_SCHEMA_VERSION,
    opportunities = opportunities,
    event_strata = event_strata,
    taxon_strata = taxon_strata,
    site_summary = site_summary,
    meta = meta,
    metric_contract = science$metric_contract,
    qc = qc,
    provenance = list(
      source = source_provenance,
      producer_schema_version = INV_PRODUCER_SCHEMA_VERSION,
      science_version = science$science_version,
      field_first = TRUE,
      exact_grain = "site x event x aquaticSiteType x habitatType x samplerType",
      qc_contract = qc_contract,
      prohibited_inference = c(
        "site health or impairment",
        "population abundance",
        "raw-density cross-site ranking",
        "causality"
      )
    )
  )
}

inv_producer_site_index <- function(bundles) {
  rows <- lapply(names(bundles), function(site) {
    bundle <- bundles[[site]]
    meta <- bundle$meta
    opportunities <- bundle$opportunities
    status <- stats::setNames(bundle$qc$status_counts$n,
                              bundle$qc$status_counts$record_status)
    status_count <- function(name) {
      value <- unname(status[[name]])
      if (is.null(value) || !length(value) || is.na(value)) 0L else as.integer(value)
    }
    data.frame(
      site = site,
      aquaticSiteType = meta$aquaticSiteType,
      lat = meta$lat,
      lng = meta$lng,
      elevation = meta$elevation,
      collectDate_min = meta$collectDate_min,
      collectDate_max = meta$collectDate_max,
      n_events = meta$n_events,
      n_strata = meta$n_strata,
      n_opportunities = meta$n_opportunities,
      n_primary_opportunities = meta$n_primary_opportunities,
      n_count_samples = meta$n_count_samples,
      n_composition_samples = meta$n_composition_samples,
      n_density_samples = meta$n_density_samples,
      n_reported_zero_count = meta$n_reported_zero_count,
      n_unstratifiable = meta$n_unstratifiable,
      n_processing_unknown = meta$n_processing_unknown,
      n_taxonomy_count_unavailable = meta$n_taxonomy_count_unavailable,
      n_displayed_zero_percent_authoritative_estimate =
        meta$n_displayed_zero_percent_authoritative_estimate,
      n_taxa_recorded = meta$n_taxa_recorded,
      n_sampling_impractical = sum(!opportunities$sampling_practical),
      n_nonstandard_collection = sum(opportunities$nonstandard_collection),
      n_processed_no_taxonomy = sum(
        opportunities$processing_count_status %in% "processed_no_taxonomy"
      ),
      n_count_unavailable = status_count("count_unavailable"),
      n_area_unavailable = status_count("area_unavailable"),
      n_density_unavailable = status_count("density_unavailable"),
      taxonomic_ranks = meta$taxonomic_ranks,
      source_stamp = meta$source_stamp,
      science_version = bundle$provenance$science_version,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out <- out[order(out$site), , drop = FALSE]
  rownames(out) <- NULL
  out
}

inv_producer_search_index <- function(bundles, site_index, source_provenance,
                                      metric_contract) {
  keep <- c(
    "siteID", "eventID", "aquaticSiteType", "habitatType", "samplerType",
    "taxon_key", "acceptedTaxonID", "scientificName", "taxonRank", "order",
    "family", "class", "subclass", "is_ept", "order_classified",
    "n_count_eligible_samples", "n_samples_present", "support_pct"
  )
  rows <- lapply(bundles, function(bundle) {
    taxa <- bundle$taxon_strata
    if (!nrow(taxa)) return(NULL)
    taxa[, keep, drop = FALSE]
  })
  rows <- Filter(Negate(is.null), rows)
  if (length(rows)) {
    taxa <- do.call(rbind, rows)
    taxa <- taxa[order(taxa$scientificName, taxa$siteID, taxa$eventID,
                       taxa$aquaticSiteType, taxa$habitatType,
                       taxa$samplerType, taxa$taxon_key), , drop = FALSE]
    rownames(taxa) <- NULL
  } else {
    taxa <- data.frame(
      siteID = character(), eventID = character(), aquaticSiteType = character(),
      habitatType = character(), samplerType = character(), taxon_key = character(),
      acceptedTaxonID = character(), scientificName = character(),
      taxonRank = character(), order = character(), family = character(),
      class = character(), subclass = character(), is_ept = logical(),
      order_classified = logical(), n_count_eligible_samples = integer(),
      n_samples_present = integer(), support_pct = numeric(),
      stringsAsFactors = FALSE
    )
  }
  list(
    schema_version = INV_PRODUCER_SCHEMA_VERSION,
    taxa = taxa,
    sites = site_index,
    metric_contract = metric_contract,
    source = source_provenance,
    built = source_provenance$publication_date_max,
    boundary = paste(
      "Taxa rows retain exact collection strata and support denominators;",
      "the index contains no raw-density cross-site ranking."
    )
  )
}

inv_producer_release <- function(source, receipt, receipt_path) {
  analysis <- inv_prepare_analysis_source(source)
  science <- build_inv_science_contract(analysis$source)
  # The source gate has already removed the exact .DNA family before the
  # scientific transform, so restore the audited raw field count in the
  # release-level exclusion ledger (never infer it from the post-quarantine
  # analysis frame).
  science$summary$excluded_metabarcoding_rows <- as.integer(
    analysis$dna_family_quarantine$rows[["inv_fieldData"]]
  )
  inv_producer_assert(identical(sort(unique(science$opportunities$siteID)),
                                INV_EXPECTED_SITES),
                      "Science opportunity roster differs from the canonical sites")
  source_stamp <- inv_producer_publication_stamp(source)
  source_provenance <- inv_producer_source_provenance(
    receipt, receipt_path, source_stamp
  )
  source_counts <- inv_producer_site_source_counts(source)
  qc_contract <- inv_producer_qc_contract()
  # Retain the audited auxiliary per-sample row and every raw taxonomy row in
  # QC. Taxonomy UID is the honest record discriminator because the basic
  # package omits the expanded-only slide identity fields.
  source_qc <- inv_producer_source_qc(source)
  bundles <- stats::setNames(lapply(INV_EXPECTED_SITES, function(site) {
    inv_producer_bundle(
      site, science, source, source_counts, source_provenance,
      source_qc[[site]], qc_contract
    )
  }), INV_EXPECTED_SITES)
  site_index <- inv_producer_site_index(bundles)
  search_index <- inv_producer_search_index(
    bundles, site_index, source_provenance, science$metric_contract
  )
  list(
    bundles = bundles,
    site_index = site_index,
    cross_site = site_index,
    search_index = search_index,
    source_provenance = source_provenance,
    science_summary = science$summary,
    metric_contract = science$metric_contract,
    qc_contract = qc_contract
  )
}

inv_producer_write_release <- function(release, output_root, receipt_path) {
  site_dir <- file.path(output_root, "data", "sites")
  dir.create(site_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(output_root, "data-sample"), recursive = TRUE,
             showWarnings = FALSE)

  bundle_paths <- stats::setNames(character(length(release$bundles)),
                                  names(release$bundles))
  for (site in names(release$bundles)) {
    path <- file.path(site_dir, paste0(site, ".rds"))
    inv_producer_save_rds(release$bundles[[site]], path)
    bundle_paths[[site]] <- path
  }
  inv_producer_save_rds(release$site_index,
                        file.path(output_root, "data", "site_index.rds"))
  inv_producer_save_rds(release$cross_site,
                        file.path(output_root, "data", "cross_site.rds"))
  inv_producer_save_rds(release$search_index,
                        file.path(output_root, "data", "search_index.rds"))
  file.copy(bundle_paths[["SYCA"]],
            file.path(output_root, "data-sample", "demo.rds"), overwrite = TRUE)
  file.copy(receipt_path, file.path(output_root, "data", "source_receipt.json"),
            overwrite = TRUE)

  bundle_sha256 <- vapply(bundle_paths, inv_sha256_file, character(1))
  release_contract <- list(
    schema_version = INV_RELEASE_CONTRACT_SCHEMA_VERSION,
    producer_schema_version = INV_PRODUCER_SCHEMA_VERSION,
    bundle_schema_version = INV_BUNDLE_SCHEMA_VERSION,
    science_version = unique(vapply(
      release$bundles, function(bundle) bundle$provenance$science_version,
      character(1)
    )),
    source = release$source_provenance,
    science_summary = release$science_summary,
    metric_contract = release$metric_contract,
    qc_contract = release$qc_contract,
    site_ids = names(release$bundles),
    bundle_sha256 = bundle_sha256,
    bundle_members = names(release$bundles[[1L]]),
    support_index_only = TRUE,
    prohibited_cross_site_fields = c(
      "density_m2", "mean_sample_density_m2", "richness", "ept_richness",
      "pct_ept", "chao1", "rarefied_richness", "health_score"
    )
  )
  inv_producer_save_rds(
    release_contract, file.path(output_root, "data", "release_contract.rds")
  )
  invisible(release_contract)
}

inv_produce_verified_release <- function(artifact_path, receipt_path,
                                         output_root = ".") {
  receipt <- inv_verify_source_receipt(artifact_path, receipt_path)
  source <- readRDS(artifact_path)
  release <- inv_producer_release(source, receipt, receipt_path)
  contract <- inv_producer_write_release(release, output_root, receipt_path)
  cat(sprintf(
    paste0(
      "Built %d field-first site bundles: %d opportunities, %d count-eligible, ",
      "%d density-eligible; source %s (%s).\n"
    ),
    length(release$bundles), release$science_summary$opportunities,
    release$science_summary$count_eligible_samples,
    release$science_summary$density_eligible_samples,
    contract$source$release, contract$source$artifact_sha256
  ))
  invisible(contract)
}

inv_rebuild_derived_from_bundles <- function(output_root = ".",
                                             build_search = TRUE) {
  contract_path <- file.path(output_root, "data", "release_contract.rds")
  inv_producer_assert(file.exists(contract_path),
                      "Missing release contract: %s", contract_path)
  contract <- readRDS(contract_path)
  site_ids <- as.character(contract$site_ids)
  inv_producer_assert(identical(site_ids, INV_EXPECTED_SITES),
                      "Release contract site roster is not canonical")
  bundles <- stats::setNames(lapply(site_ids, function(site) {
    path <- file.path(output_root, "data", "sites", paste0(site, ".rds"))
    inv_producer_assert(file.exists(path), "Missing site bundle: %s", path)
    expected <- as.character(contract$bundle_sha256[[site]])
    inv_producer_assert(identical(inv_sha256_file(path), expected),
                        "Bundle hash differs from release contract: %s", site)
    readRDS(path)
  }), site_ids)
  site_index <- inv_producer_site_index(bundles)
  inv_producer_save_rds(site_index,
                        file.path(output_root, "data", "site_index.rds"))
  inv_producer_save_rds(site_index,
                        file.path(output_root, "data", "cross_site.rds"))
  file.copy(file.path(output_root, "data", "sites", "SYCA.rds"),
            file.path(output_root, "data-sample", "demo.rds"), overwrite = TRUE)
  if (isTRUE(build_search)) {
    search <- inv_producer_search_index(
      bundles, site_index, contract$source, contract$metric_contract
    )
    inv_producer_save_rds(search,
                          file.path(output_root, "data", "search_index.rds"))
  }
  invisible(site_index)
}
