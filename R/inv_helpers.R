# ===========================================================================
# NEON My Little Inverts — loaded-app contract helpers
#
# The app reads the field-first Pass-9 bundle and nothing older. A field row is
# an opportunity; event and taxon metrics retain the exact site x event x water
# type x habitat x sampler grain. Missing, unknown, and a reported laboratory
# zero are different states. All summaries are descriptive collection records.
# ===========================================================================

`%||%` <- function(a, b) {
  if (is.null(a) || !length(a) || (length(a) == 1L && is.na(a))) b else a
}

num <- function(x) suppressWarnings(as.numeric(as.character(x)))

inv_chr <- function(x) {
  out <- trimws(as.character(x))
  out[is.na(x) | !nzchar(out)] <- NA_character_
  out
}

inv_true <- function(x) {
  out <- as.logical(x)
  out[is.na(out)] <- FALSE
  out
}

INV_BUNDLE_SCHEMA_VERSION <- "2.1.0"
INV_PRODUCER_SCHEMA_VERSION <- "2.1.0"
INV_RELEASE_CONTRACT_SCHEMA_VERSION <- "1.0.0"
INV_QC_AUDIT_SCHEMA_VERSION <- "1.0.0"
INV_EXPECTED_DPID <- "DP1.20120.001"
INV_EXPECTED_RELEASE <- "RELEASE-2026"
INV_EXACT_GRAIN <-
  "site x event x aquaticSiteType x habitatType x samplerType"

INV_SOURCE_IDENTITY_FIELDS <- c(
  "dpid", "release", "include_provisional", "publication_date_max",
  "artifact_sha256", "receipt_sha256"
)

INV_SOURCE_QUALITY_COLUMNS <- list(
  field = c(
    "siteID", "namedLocation", "eventID", "sampleID", "sampleCode",
    "collectDate", "dataQF"
  ),
  per_sample = c(
    "siteID", "sampleID", "sampleCode", "dataQF", "qcSortDate",
    "qcSortingEfficacy", "qcIterationCount", "qcPercentSimilarity",
    "qcSortedBy", "qcEnumerationDifference", "qcTaxonomicDifference"
  ),
  taxonomy_processed = c(
    "siteID", "uid", "sampleID", "sampleCode", "acceptedTaxonID",
    "scientificName", "taxonRank", "qcChecked", "dataQF"
  )
)

INV_ISSUE_LOG_COLUMNS <- c(
  "id", "parentIssueID", "issueDate", "resolvedDate", "dateRangeStart",
  "dateRangeEnd", "locationAffected", "issue", "resolution", "bundle_site",
  "site_scope_basis", "site_scope_match", "site_collect_date_min",
  "site_collect_date_max", "date_scope_basis", "date_overlap",
  "potentially_applicable", "annotation_only"
)

INV_SOURCE_ROW_COLUMNS <- c(
  "site", "collection_field_rows", "metabarcode_field_rows",
  "per_sample_rows", "taxonomy_processed_rows", "field_qc_rows",
  "per_sample_qc_rows", "taxonomy_qc_rows", "issue_log_rows"
)

INV_RECONCILIATION_SCALARS <- c(
  "opportunity_rows", "status_rows", "primary_opportunities",
  "count_eligible_samples", "composition_eligible_samples",
  "density_eligible_samples", "reported_zero_count", "unstratifiable",
  "processing_unknown", "taxonomy_count_unavailable",
  "displayed_zero_percent_authoritative_estimate",
  "practical_processing_count_opportunities",
  "taxonomy_rows_collapsed", "opportunity_complete", "count_contains_density",
  "qc_alters_metric_eligibility"
)

INV_SEARCH_TAXON_COLUMNS <- c(
  "siteID", "eventID", "aquaticSiteType", "habitatType", "samplerType",
  "taxon_key", "acceptedTaxonID", "scientificName", "taxonRank", "order",
  "family", "class", "subclass", "is_ept", "order_classified",
  "n_count_eligible_samples", "n_samples_present", "support_pct"
)

INV_RECORD_STATUS_LEVELS <- c(
  "sampling_impractical", "unstratifiable", "nonstandard_collection",
  "processing_unknown", "processed_no_taxonomy", "count_unavailable", "area_unavailable",
  "density_unavailable", "reported_zero_count", "quantified_community"
)
# The first applicable state wins. Keep this projection independent from the
# producer so the loaded app can reject coordinated status-ledger tampering.
INV_RECORD_STATUS_PRECEDENCE <- c(
  "unstratifiable", "sampling_impractical", "nonstandard_collection",
  "processing_unknown", "processed_no_taxonomy", "count_unavailable",
  "area_unavailable", "density_unavailable", "reported_zero_count",
  "quantified_community"
)
INV_PROCESSING_COUNT_STATUS_LEVELS <- c(
  "processing_unknown", "processed_no_taxonomy",
  "taxonomy_count_unavailable", "taxonomy_count_available"
)
INV_NONSTANDARD_SAMPLER_RELEASE_2026 <- "grab"

INV_STATUS_META <- data.frame(
  record_status = INV_RECORD_STATUS_LEVELS,
  label = c(
    "Sampling impractical", "Stratum fields unavailable",
    "Nonstandard collection", "Processing outcome unknown",
    "Processed; taxonomy unavailable",
    "Count unavailable", "Area unavailable", "Density unavailable",
    "Reported zero (primary status)", "Quantified community"
  ),
  meaning = c(
    "A field opportunity was recorded, but collection was impractical.",
    "A field row is retained, but one or more exact-grain fields are missing.",
    "A GRAB, BRYOZOAN, or MACROALGAE special-ID record is retained for audit and excluded from primary quantitative strata.",
    "A practical field opportunity has neither a processing record nor taxonomy; this is an unknown processing outcome, not an observed absence.",
    "A practical processed sample has no taxonomy rows; this is unknown, not an observed absence.",
    "Taxonomy exists, but expanded counts cannot be used under the count contract.",
    "Counts can be summarized, but sampled benthic area is unavailable.",
    "Count and area inputs exist, but sample density is non-finite.",
    "Primary status for a usable expanded zero when no higher-priority processing state applies; the separate reported-zero support flag counts every usable zero.",
    "The processed sample has usable expanded counts and benthic area."
  ),
  count_denominator = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE),
  density_denominator = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE),
  stringsAsFactors = FALSE
)

INV_REQUIRED_BUNDLE_MEMBERS <- c(
  "schema_version", "opportunities", "event_strata", "taxon_strata",
  "site_summary", "meta", "metric_contract", "qc", "provenance"
)

INV_OPPORTUNITY_COLUMNS <- c(
  "opportunity_id", "sample_key", "sampleID", "sampleCode", "siteID",
  "eventID", "collectDate", "aquaticSiteType", "habitatType", "samplerType",
  "namedLocation", "sampleNumber", "samplingImpractical", "stratum_key",
  "has_per_sample", "sampling_practical", "sampler_type_normalized",
  "nonstandard_id_hint", "grain_complete", "unstratifiable", "nonstandard_collection",
  "primary_stratum", "processing_unknown", "taxonomy_count_unavailable",
  "displayed_zero_percent_authoritative_estimate",
  "processing_count_status", "taxonomy_rows", "record_status", "count_issue",
  "density_issue", "benthicArea_m2", "total_estimated_count",
  "count_eligible", "density_eligible", "reported_zero_count",
  "sample_density_m2", "taxa_observed", "ept_taxa_observed", "hill_q1",
  "hill_q2", "pct_ept_of_all_estimated_count",
  "pct_order_classified_estimated_count"
)

INV_EVENT_COLUMNS <- c(
  "stratum_key", "siteID", "eventID", "aquaticSiteType", "habitatType",
  "samplerType", "collectDate_min", "collectDate_max", "n_opportunities",
  "n_sampling_impractical", "n_processing_unknown", "n_processed_no_taxonomy",
  "n_taxonomy_count_unavailable",
  "n_displayed_zero_percent_authoritative_estimate", "n_count_unavailable",
  "n_area_unavailable", "n_density_unavailable", "n_count_samples",
  "n_composition_samples", "n_density_samples", "n_reported_zero_count",
  "mean_sample_density_m2", "median_sample_density_m2",
  "sd_sample_density_m2", "se_sample_density_m2",
  "mean_sample_taxa_observed", "mean_sample_ept_taxa_observed",
  "mean_sample_hill_q1", "mean_sample_hill_q2",
  "mean_sample_pct_ept_of_all_estimated_count",
  "mean_sample_pct_order_classified_estimated_count"
)

INV_TAXON_COLUMNS <- c(
  "stratum_key", "siteID", "eventID", "aquaticSiteType", "habitatType",
  "samplerType", "taxon_key", "acceptedTaxonID", "scientificName",
  "taxonRank", "order", "family", "class", "subclass", "is_ept",
  "order_classified", "n_count_eligible_samples",
  "n_density_eligible_samples", "n_samples_present", "support_pct",
  "mean_sample_density_m2", "median_sample_density_m2",
  "total_estimated_count"
)

INV_SITE_INDEX_COLUMNS <- c(
  "site", "aquaticSiteType", "lat", "lng", "elevation",
  "collectDate_min", "collectDate_max", "n_events", "n_strata",
  "n_opportunities", "n_primary_opportunities", "n_count_samples",
  "n_composition_samples", "n_density_samples", "n_reported_zero_count",
  "n_unstratifiable", "n_processing_unknown", "n_taxonomy_count_unavailable",
  "n_displayed_zero_percent_authoritative_estimate",
  "n_taxa_recorded", "n_sampling_impractical",
  "n_nonstandard_collection", "n_processed_no_taxonomy",
  "n_count_unavailable", "n_area_unavailable", "n_density_unavailable",
  "taxonomic_ranks", "source_stamp", "science_version"
)

INV_META_FIELDS <- c(
  "schema_version", "site", "source_stamp", "built", "release",
  "collectDate_min", "collectDate_max", "aquaticSiteType",
  "aquatic_site_types", "lat", "lng", "elevation", "named_location_count",
  "n_events", "n_strata", "n_opportunities", "n_primary_opportunities",
  "n_count_samples", "n_composition_samples", "n_density_samples",
  "n_reported_zero_count", "n_unstratifiable", "n_processing_unknown",
  "n_taxonomy_count_unavailable",
  "n_displayed_zero_percent_authoritative_estimate", "n_taxa_recorded",
  "taxonomic_ranks", "comparison_boundary"
)

inv_contract_result <- function(ok, reason = NULL) {
  structure(isTRUE(ok), reason = reason %||% if (isTRUE(ok)) "ok" else "invalid")
}

inv_contract_reason <- function(result) attr(result, "reason") %||% "invalid"

inv_require_columns <- function(x, columns, label) {
  if (!is.data.frame(x)) {
    return(inv_contract_result(FALSE, sprintf("%s is not a data frame", label)))
  }
  missing <- setdiff(columns, names(x))
  if (length(missing)) {
    return(inv_contract_result(
      FALSE, sprintf("%s is missing column %s", label, missing[[1L]])
    ))
  }
  inv_contract_result(TRUE)
}

inv_scalar_text <- function(x) {
  value <- inv_chr(x)
  length(value) == 1L && !is.na(value)
}

inv_sha256_text <- function(x) {
  inv_scalar_text(x) && grepl("^[0-9a-f]{64}$", tolower(as.character(x)))
}

inv_source_identity <- function(source) {
  if (!is.list(source)) {
    return(inv_contract_result(FALSE, "source provenance is not a list"))
  }
  missing <- setdiff(INV_SOURCE_IDENTITY_FIELDS, names(source))
  if (length(missing)) {
    return(inv_contract_result(
      FALSE, sprintf("source provenance is missing %s", missing[[1L]])
    ))
  }
  if (!identical(as.character(source$dpid), INV_EXPECTED_DPID) ||
      !identical(as.character(source$release), INV_EXPECTED_RELEASE) ||
      !identical(source$include_provisional, FALSE)) {
    return(inv_contract_result(
      FALSE, "source provenance is not exact RELEASE-2026 without provisional data"
    ))
  }
  if (!inv_scalar_text(source$publication_date_max)) {
    return(inv_contract_result(FALSE,
                               "source publication_date_max is unavailable"))
  }
  if (!inv_sha256_text(source$artifact_sha256) ||
      !inv_sha256_text(source$receipt_sha256)) {
    return(inv_contract_result(FALSE, "source SHA-256 identity is invalid"))
  }
  inv_contract_result(TRUE)
}

inv_source_identity_equal <- function(left, right) {
  if (!isTRUE(inv_source_identity(left)) || !isTRUE(inv_source_identity(right))) {
    return(FALSE)
  }
  all(vapply(INV_SOURCE_IDENTITY_FIELDS, function(field) {
    identical(left[[field]], right[[field]])
  }, logical(1)))
}

inv_verify_file_sha256 <- function(path, expected_sha256) {
  if (!file.exists(path)) {
    return(inv_contract_result(FALSE, sprintf("file is missing: %s", path)))
  }
  if (!inv_sha256_text(expected_sha256)) {
    return(inv_contract_result(FALSE, "expected file SHA-256 is invalid"))
  }
  if (!requireNamespace("digest", quietly = TRUE)) {
    return(inv_contract_result(FALSE,
                               "digest is unavailable for release-file verification"))
  }
  observed <- tryCatch(
    digest::digest(file = path, algo = "sha256"),
    error = function(e) NA_character_
  )
  if (!identical(tolower(observed), tolower(as.character(expected_sha256)))) {
    return(inv_contract_result(FALSE, "file SHA-256 differs from release contract"))
  }
  inv_contract_result(TRUE)
}

inv_validate_release_contract <- function(contract, expected_sites = NULL) {
  if (!is.list(contract)) {
    return(inv_contract_result(FALSE, "release contract is not a list"))
  }
  required <- c(
    "schema_version", "producer_schema_version", "bundle_schema_version",
    "science_version", "source", "metric_contract", "qc_contract",
    "site_ids", "bundle_sha256", "bundle_members", "support_index_only",
    "prohibited_cross_site_fields"
  )
  missing <- setdiff(required, names(contract))
  if (length(missing)) {
    return(inv_contract_result(
      FALSE, sprintf("release contract is missing %s", missing[[1L]])
    ))
  }
  if (!identical(as.character(contract$schema_version),
                 INV_RELEASE_CONTRACT_SCHEMA_VERSION) ||
      !identical(as.character(contract$producer_schema_version),
                 INV_PRODUCER_SCHEMA_VERSION) ||
      !identical(as.character(contract$bundle_schema_version),
                 INV_BUNDLE_SCHEMA_VERSION)) {
    return(inv_contract_result(FALSE, "release contract schema family is invalid"))
  }
  if (!inv_scalar_text(contract$science_version) ||
      !isTRUE(contract$support_index_only)) {
    return(inv_contract_result(FALSE,
                               "release contract science/support boundary is invalid"))
  }
  source_check <- inv_source_identity(contract$source)
  if (!isTRUE(source_check)) return(source_check)
  metric_check <- inv_require_columns(
    contract$metric_contract, c("metric", "table", "column", "grain",
                                "denominator", "boundary"),
    "release contract metric_contract"
  )
  if (!isTRUE(metric_check)) return(metric_check)
  if (!is.list(contract$qc_contract) ||
      !identical(as.character(contract$qc_contract$schema_version),
                 INV_QC_AUDIT_SCHEMA_VERSION) ||
      !isTRUE(contract$qc_contract$retain_verbatim) ||
      !identical(contract$qc_contract$automatic_exclusion, FALSE) ||
      !identical(as.character(contract$qc_contract$eligibility_effect), "none")) {
    return(inv_contract_result(FALSE, "release contract QC policy is invalid"))
  }
  sites <- as.character(contract$site_ids)
  if (!length(sites) || any(is.na(inv_chr(sites))) || anyDuplicated(sites)) {
    return(inv_contract_result(FALSE,
                               "release contract site roster is empty or non-unique"))
  }
  if (!is.null(expected_sites) &&
      !identical(sites, as.character(expected_sites))) {
    return(inv_contract_result(FALSE,
                               "release contract site roster is not canonical"))
  }
  hashes <- contract$bundle_sha256
  if (is.null(names(hashes)) || !identical(names(hashes), sites) ||
      !all(vapply(hashes, inv_sha256_text, logical(1)))) {
    return(inv_contract_result(FALSE,
                               "release contract bundle hashes are incomplete"))
  }
  if (!identical(as.character(contract$bundle_members),
                 INV_REQUIRED_BUNDLE_MEMBERS)) {
    return(inv_contract_result(FALSE,
                               "release contract bundle members are invalid"))
  }
  prohibited <- c(
    "density_m2", "mean_sample_density_m2", "richness", "ept_richness",
    "pct_ept", "chao1", "rarefied_richness", "health_score"
  )
  if (!all(prohibited %in% contract$prohibited_cross_site_fields)) {
    return(inv_contract_result(FALSE,
                               "release contract cross-site boundary is incomplete"))
  }
  inv_contract_result(TRUE)
}

inv_validate_qc <- function(qc, opportunities, expected_site) {
  if (!is.list(qc)) return(inv_contract_result(FALSE, "qc is not a list"))
  required <- c(
    "contract", "status_counts", "source_rows", "source_quality",
    "issue_log", "reconciliation"
  )
  missing <- setdiff(required, names(qc))
  if (length(missing)) {
    return(inv_contract_result(FALSE, sprintf("qc is missing %s", missing[[1L]])))
  }
  if (!is.list(qc$contract) ||
      !identical(as.character(qc$contract$schema_version),
                 INV_QC_AUDIT_SCHEMA_VERSION) ||
      !isTRUE(qc$contract$retain_verbatim) ||
      !identical(qc$contract$automatic_exclusion, FALSE) ||
      !identical(as.character(qc$contract$eligibility_effect), "none")) {
    return(inv_contract_result(FALSE, "qc contract is invalid"))
  }
  status_check <- inv_require_columns(
    qc$status_counts, c("record_status", "n"), "qc$status_counts"
  )
  if (!isTRUE(status_check)) return(status_check)
  if (!identical(as.character(qc$status_counts$record_status),
                 INV_RECORD_STATUS_LEVELS) ||
      any(!is.finite(num(qc$status_counts$n)) | num(qc$status_counts$n) < 0)) {
    return(inv_contract_result(FALSE, "qc status ledger is invalid"))
  }
  source_rows_check <- inv_require_columns(
    qc$source_rows, INV_SOURCE_ROW_COLUMNS, "qc$source_rows"
  )
  if (!isTRUE(source_rows_check)) return(source_rows_check)
  if (nrow(qc$source_rows) != 1L ||
      !identical(as.character(qc$source_rows$site), expected_site)) {
    return(inv_contract_result(FALSE, "qc source-row receipt is not site-specific"))
  }
  source_row_values <- num(unlist(
    qc$source_rows[setdiff(INV_SOURCE_ROW_COLUMNS, "site")],
    use.names = FALSE
  ))
  if (any(!is.finite(source_row_values) | source_row_values < 0)) {
    return(inv_contract_result(FALSE, "qc source-row counts are invalid"))
  }
  if (!is.list(qc$source_quality) ||
      !identical(names(qc$source_quality), names(INV_SOURCE_QUALITY_COLUMNS))) {
    return(inv_contract_result(FALSE,
                               "qc$source_quality has an invalid table family"))
  }
  for (table_name in names(INV_SOURCE_QUALITY_COLUMNS)) {
    check <- inv_require_columns(
      qc$source_quality[[table_name]], INV_SOURCE_QUALITY_COLUMNS[[table_name]],
      paste0("qc$source_quality$", table_name)
    )
    if (!isTRUE(check)) return(check)
    rows <- qc$source_quality[[table_name]]
    row_sites <- as.character(rows$siteID)
    if (nrow(rows) && any(is.na(row_sites) | row_sites != expected_site)) {
      return(inv_contract_result(FALSE,
                                 "qc source-quality row belongs to another site"))
    }
  }
  issue_check <- inv_require_columns(qc$issue_log, INV_ISSUE_LOG_COLUMNS,
                                     "qc$issue_log")
  if (!isTRUE(issue_check)) return(issue_check)
  issue_sites <- as.character(qc$issue_log$bundle_site)
  if (nrow(qc$issue_log) &&
      any(is.na(issue_sites) | issue_sites != expected_site)) {
    return(inv_contract_result(FALSE, "qc issue annotation belongs to another site"))
  }
  reconciliation <- qc$reconciliation
  if (!is.list(reconciliation)) {
    return(inv_contract_result(FALSE, "qc reconciliation is not a list"))
  }
  missing <- setdiff(c(
    INV_RECONCILIATION_SCALARS, "processing_count_status_counts",
    "source_qc_rows_retained"
  ),
                     names(reconciliation))
  if (length(missing)) {
    return(inv_contract_result(
      FALSE, sprintf("qc reconciliation is missing %s", missing[[1L]])
    ))
  }
  retained <- reconciliation$source_qc_rows_retained
  expected_retained <- c(
    field = nrow(qc$source_quality$field),
    per_sample = nrow(qc$source_quality$per_sample),
    taxonomy_processed = nrow(qc$source_quality$taxonomy_processed),
    issue_log = nrow(qc$issue_log)
  )
  if (!identical(names(retained), names(expected_retained)) ||
      !identical(num(retained), num(expected_retained))) {
    return(inv_contract_result(FALSE,
                               "qc retained-row reconciliation is inconsistent"))
  }
  expected_status <- table(factor(
    as.character(opportunities$record_status), levels = INV_RECORD_STATUS_LEVELS
  ))
  expected_reconciliation <- c(
    primary_opportunities = sum(inv_true(opportunities$primary_stratum)),
    count_eligible_samples = sum(inv_true(opportunities$count_eligible)),
    composition_eligible_samples = sum(
      inv_true(opportunities$count_eligible) &
        is.finite(num(opportunities$total_estimated_count)) &
        num(opportunities$total_estimated_count) > 0
    ),
    density_eligible_samples = sum(inv_true(opportunities$density_eligible)),
    reported_zero_count = sum(inv_true(opportunities$reported_zero_count)),
    unstratifiable = sum(inv_true(opportunities$unstratifiable)),
    processing_unknown = sum(inv_true(opportunities$processing_unknown)),
    taxonomy_count_unavailable = sum(
      inv_true(opportunities$taxonomy_count_unavailable)
    ),
    displayed_zero_percent_authoritative_estimate = sum(
      inv_true(opportunities$displayed_zero_percent_authoritative_estimate)
    ),
    practical_processing_count_opportunities = sum(
      inv_true(opportunities$sampling_practical)
    ),
    taxonomy_rows_collapsed = sum(num(opportunities$taxonomy_rows))
  )
  reconciliation_matches <- all(vapply(
    names(expected_reconciliation), function(name) {
      identical(num(reconciliation[[name]]),
                num(expected_reconciliation[[name]]))
    }, logical(1)
  ))
  expected_processing_count_status <- table(factor(
    as.character(opportunities$processing_count_status[
      inv_true(opportunities$sampling_practical)
    ]), levels = INV_PROCESSING_COUNT_STATUS_LEVELS
  ))
  processing_count_status_matches <-
    identical(
      as.character(names(reconciliation$processing_count_status_counts)),
      as.character(names(expected_processing_count_status))
    ) &&
    identical(
      num(reconciliation$processing_count_status_counts),
      num(expected_processing_count_status)
    ) &&
    sum(num(expected_processing_count_status)) ==
      sum(inv_true(opportunities$sampling_practical))
  source_rows_match <-
    identical(num(qc$source_rows$collection_field_rows),
              as.numeric(nrow(opportunities))) &&
    identical(num(qc$source_rows$field_qc_rows),
              num(qc$source_rows$collection_field_rows) +
                num(qc$source_rows$metabarcode_field_rows)) &&
    identical(num(qc$source_rows$field_qc_rows),
              as.numeric(nrow(qc$source_quality$field))) &&
    identical(num(qc$source_rows$per_sample_rows),
              as.numeric(nrow(qc$source_quality$per_sample))) &&
    identical(num(qc$source_rows$per_sample_qc_rows),
              as.numeric(nrow(qc$source_quality$per_sample))) &&
    identical(num(qc$source_rows$taxonomy_processed_rows),
              as.numeric(nrow(qc$source_quality$taxonomy_processed))) &&
    identical(num(qc$source_rows$taxonomy_qc_rows),
              as.numeric(nrow(qc$source_quality$taxonomy_processed))) &&
    identical(num(qc$source_rows$issue_log_rows),
              as.numeric(nrow(qc$issue_log)))
  if (!identical(num(qc$status_counts$n), num(expected_status)) ||
      !identical(num(reconciliation$opportunity_rows),
                 as.numeric(nrow(opportunities))) ||
      !identical(num(reconciliation$status_rows),
                 as.numeric(nrow(opportunities))) ||
      !isTRUE(reconciliation$opportunity_complete) ||
      !isTRUE(reconciliation$count_contains_density) ||
      !reconciliation_matches || !processing_count_status_matches ||
      !source_rows_match ||
      !identical(reconciliation$qc_alters_metric_eligibility, FALSE)) {
    return(inv_contract_result(FALSE, "qc reconciliation differs from bundle rows"))
  }
  inv_contract_result(TRUE)
}

inv_validate_bundle <- function(bundle, expected_site = NULL,
                                release_contract = NULL) {
  if (!is.list(bundle)) return(inv_contract_result(FALSE, "bundle is not a list"))
  missing <- setdiff(INV_REQUIRED_BUNDLE_MEMBERS, names(bundle))
  if (length(missing)) {
    return(inv_contract_result(
      FALSE, sprintf("bundle is missing member %s", missing[[1L]])
    ))
  }
  if (!identical(names(bundle), INV_REQUIRED_BUNDLE_MEMBERS)) {
    return(inv_contract_result(FALSE,
                               "bundle members/order differ from the release family"))
  }
  legacy <- intersect(c("bouts", "samples", "taxa", "qc_samples"), names(bundle))
  if (length(legacy)) {
    return(inv_contract_result(
      FALSE, sprintf("legacy bundle member is prohibited: %s", legacy[[1L]])
    ))
  }
  if (!identical(as.character(bundle$schema_version), INV_BUNDLE_SCHEMA_VERSION)) {
    return(inv_contract_result(FALSE, sprintf(
      "bundle schema_version is not %s", INV_BUNDLE_SCHEMA_VERSION
    )))
  }

  checks <- list(
    inv_require_columns(bundle$opportunities, INV_OPPORTUNITY_COLUMNS,
                        "opportunities"),
    inv_require_columns(bundle$event_strata, INV_EVENT_COLUMNS, "event_strata"),
    inv_require_columns(bundle$taxon_strata, INV_TAXON_COLUMNS, "taxon_strata"),
    inv_require_columns(bundle$site_summary,
                        c("siteID", "collectDate_min", "collectDate_max",
                          "n_events", "n_strata", "n_opportunities",
                          "n_sampling_impractical", "n_nonstandard_collection",
                          "n_unstratifiable", "n_processing_unknown",
                          "n_processed_no_taxonomy",
                          "n_taxonomy_count_unavailable",
                          "n_displayed_zero_percent_authoritative_estimate",
                          "n_count_samples", "n_density_samples",
                          "n_taxa_recorded", "taxonomic_ranks"),
                        "site_summary"),
    inv_require_columns(bundle$metric_contract,
                        c("metric", "grain", "denominator", "boundary"),
                        "metric_contract")
  )
  bad <- which(!vapply(checks, isTRUE, logical(1)))
  if (length(bad)) return(checks[[bad[[1L]]]])
  if (!nrow(bundle$opportunities)) {
    return(inv_contract_result(FALSE, "opportunity ledger is empty"))
  }
  if (nrow(bundle$site_summary) != 1L) {
    return(inv_contract_result(FALSE, "site_summary must contain exactly one row"))
  }
  if (!is.list(bundle$meta) || !is.list(bundle$qc) ||
      !is.list(bundle$provenance)) {
    return(inv_contract_result(FALSE, "meta, qc, and provenance must be lists"))
  }
  missing_meta <- setdiff(INV_META_FIELDS, names(bundle$meta))
  if (length(missing_meta)) {
    return(inv_contract_result(
      FALSE, sprintf("meta is missing field %s", missing_meta[[1L]])
    ))
  }

  site <- as.character(bundle$meta$site %||% NA_character_)
  if (length(site) != 1L || is.na(site) || !nzchar(site)) {
    return(inv_contract_result(FALSE, "meta$site must be one nonblank code"))
  }
  if (!is.null(expected_site) && !identical(site, as.character(expected_site))) {
    return(inv_contract_result(FALSE, "bundle site does not match requested site"))
  }
  if (!identical(as.character(bundle$meta$schema_version),
                 INV_BUNDLE_SCHEMA_VERSION) ||
      !identical(as.character(bundle$meta$release), INV_EXPECTED_RELEASE)) {
    return(inv_contract_result(FALSE, "bundle meta is outside the release family"))
  }
  site_members <- c(
    as.character(bundle$opportunities$siteID),
    as.character(bundle$event_strata$siteID),
    as.character(bundle$taxon_strata$siteID),
    as.character(bundle$site_summary$siteID)
  )
  site_members <- site_members[!is.na(site_members)]
  if (!length(site_members) || any(site_members != site)) {
    return(inv_contract_result(FALSE, "bundle tables do not resolve to meta$site"))
  }
  if (anyDuplicated(bundle$opportunities$opportunity_id)) {
    return(inv_contract_result(FALSE, "opportunity_id is not unique"))
  }
  summary_row <- bundle$site_summary[1L, , drop = FALSE]
  boolean_fields <- c(
    "has_per_sample", "sampling_practical", "primary_stratum", "unstratifiable",
    "nonstandard_collection", "count_eligible", "density_eligible",
    "reported_zero_count", "processing_unknown",
    "taxonomy_count_unavailable",
    "displayed_zero_percent_authoritative_estimate"
  )
  valid_booleans <- vapply(boolean_fields, function(field) {
    values <- bundle$opportunities[[field]]
    is.logical(values) && length(values) == nrow(bundle$opportunities) &&
      !anyNA(values)
  }, logical(1))
  if (!all(valid_booleans)) {
    return(inv_contract_result(
      FALSE, sprintf("opportunity boolean %s is invalid",
                     boolean_fields[which(!valid_booleans)[[1L]]])
    ))
  }

  opportunities <- bundle$opportunities
  source_missing <- function(value) {
    normalized <- trimws(as.character(value))
    is.na(value) | !nzchar(normalized) | normalized == "(not recorded)"
  }
  primitive_num <- function(value) {
    if (is.numeric(value)) return(as.numeric(value))
    suppressWarnings(as.numeric(as.character(value)))
  }
  practical_flag <- trimws(as.character(opportunities$samplingImpractical))
  expected_practical <- is.na(opportunities$samplingImpractical) |
    !nzchar(practical_flag) | toupper(practical_flag) == "OK"
  grain_fields <- c(
    "siteID", "eventID", "aquaticSiteType", "habitatType", "samplerType"
  )
  expected_grain_complete <- Reduce(
    `&`, lapply(opportunities[grain_fields], function(value) {
      !source_missing(value)
    })
  )
  sampler_normalized <- trimws(as.character(opportunities$samplerType))
  sampler_normalized[source_missing(opportunities$samplerType)] <- NA_character_
  sampler_normalized <- tolower(gsub(
    "[[:space:]_-]+", "", sampler_normalized
  ))
  expected_unstratifiable <- !expected_grain_complete
  expected_nonstandard <- !is.na(sampler_normalized) &
    sampler_normalized == INV_NONSTANDARD_SAMPLER_RELEASE_2026
  expected_primary <- !expected_unstratifiable & !expected_nonstandard
  structure_checks <- list(
    sampling_practical = expected_practical,
    grain_complete = expected_grain_complete,
    unstratifiable = expected_unstratifiable,
    nonstandard_collection = expected_nonstandard,
    primary_stratum = expected_primary
  )
  bad_structure <- names(structure_checks)[!vapply(
    names(structure_checks), function(field) {
      identical(opportunities[[field]], structure_checks[[field]])
    }, logical(1)
  )]
  if (length(bad_structure)) {
    return(inv_contract_result(
      FALSE, sprintf(
        "opportunity %s differs from primitive field evidence",
        bad_structure[[1L]]
      )
    ))
  }
  if (!identical(as.character(opportunities$sampler_type_normalized),
                 sampler_normalized)) {
    return(inv_contract_result(
      FALSE, "opportunity sampler normalization differs from samplerType"
    ))
  }

  taxonomy_rows <- primitive_num(opportunities$taxonomy_rows)
  if (any(!is.finite(taxonomy_rows) | taxonomy_rows < 0 |
          taxonomy_rows != floor(taxonomy_rows))) {
    return(inv_contract_result(
      FALSE, "opportunity taxonomy_rows is not a nonnegative integer ledger"
    ))
  }
  has_per_sample <- opportunities$has_per_sample
  count_issue <- inv_chr(opportunities$count_issue)
  expected_processing_unknown <- expected_practical & !has_per_sample &
    taxonomy_rows == 0
  expected_taxonomy_count_unavailable <- expected_practical &
    taxonomy_rows > 0 & !is.na(count_issue)
  expected_processing_status <- rep(NA_character_, nrow(opportunities))
  expected_processing_status[expected_processing_unknown] <-
    "processing_unknown"
  expected_processing_status[
    expected_practical & has_per_sample & taxonomy_rows == 0
  ] <- "processed_no_taxonomy"
  expected_processing_status[expected_taxonomy_count_unavailable] <-
    "taxonomy_count_unavailable"
  expected_processing_status[
    expected_practical & taxonomy_rows > 0 & is.na(count_issue)
  ] <- "taxonomy_count_available"
  if (!identical(opportunities$processing_unknown,
                 expected_processing_unknown) ||
      !identical(opportunities$taxonomy_count_unavailable,
                 expected_taxonomy_count_unavailable) ||
      !identical(as.character(opportunities$processing_count_status),
                 expected_processing_status)) {
    return(inv_contract_result(
      FALSE,
      paste0(
        "opportunity processing/count outcome differs from primitive ",
        "practicality, per-sample, taxonomy, or count-issue evidence"
      )
    ))
  }

  total_count <- primitive_num(opportunities$total_estimated_count)
  benthic_area <- primitive_num(opportunities$benthicArea_m2)
  valid_area <- is.finite(benthic_area) & benthic_area > 0
  analysis_practical <- expected_practical & expected_primary
  expected_count_eligible <- analysis_practical & taxonomy_rows > 0 &
    is.na(count_issue)
  if (any(expected_count_eligible &
          (!is.finite(total_count) | total_count < 0))) {
    return(inv_contract_result(
      FALSE, "count-eligible primitive totals are missing, nonfinite, or negative"
    ))
  }
  density_candidate <- expected_count_eligible & valid_area
  candidate_density <- rep(NA_real_, nrow(opportunities))
  candidate_density[density_candidate] <-
    total_count[density_candidate] / benthic_area[density_candidate]
  nonfinite_density <- density_candidate & !is.finite(candidate_density)
  expected_density_eligible <- density_candidate & !nonfinite_density
  expected_reported_zero <- expected_count_eligible &
    is.finite(total_count) & total_count == 0
  if (!identical(opportunities$count_eligible, expected_count_eligible) ||
      !identical(opportunities$density_eligible,
                 expected_density_eligible) ||
      !identical(opportunities$reported_zero_count,
                 expected_reported_zero)) {
    return(inv_contract_result(
      FALSE,
      "opportunity eligibility differs from primitive grain/count/area evidence"
    ))
  }
  expected_density_issue <- rep(NA_character_, nrow(opportunities))
  expected_density_issue[nonfinite_density] <- "nonfinite_sample_density"
  if (!identical(as.character(opportunities$density_issue),
                 expected_density_issue)) {
    return(inv_contract_result(
      FALSE, "opportunity density issue differs from the primitive quotient"
    ))
  }
  expected_sample_density <- candidate_density
  expected_sample_density[!expected_density_eligible] <- NA_real_
  observed_sample_density <- primitive_num(opportunities$sample_density_m2)
  density_equal <- (is.na(observed_sample_density) &
                      is.na(expected_sample_density)) |
    (!is.na(observed_sample_density) & !is.na(expected_sample_density) &
       observed_sample_density == expected_sample_density)
  if (!all(density_equal)) {
    return(inv_contract_result(
      FALSE, "opportunity sample density differs from the primitive quotient"
    ))
  }

  expected_status <- rep(NA_character_, nrow(opportunities))
  expected_status[expected_unstratifiable] <- "unstratifiable"
  expected_status[is.na(expected_status) & !expected_practical] <-
    "sampling_impractical"
  expected_status[is.na(expected_status) & expected_nonstandard] <-
    "nonstandard_collection"
  expected_status[analysis_practical & expected_processing_unknown] <-
    "processing_unknown"
  expected_status[
    analysis_practical & has_per_sample & taxonomy_rows == 0
  ] <- "processed_no_taxonomy"
  expected_status[
    analysis_practical & expected_taxonomy_count_unavailable
  ] <- "count_unavailable"
  expected_status[
    analysis_practical & taxonomy_rows > 0 & is.na(count_issue) & !valid_area
  ] <- "area_unavailable"
  expected_status[nonfinite_density] <- "density_unavailable"
  expected_status[expected_density_eligible & total_count > 0] <-
    "quantified_community"
  expected_status[expected_density_eligible & expected_reported_zero] <-
    "reported_zero_count"
  if (anyNA(expected_status) ||
      !identical(as.character(opportunities$record_status), expected_status)) {
    return(inv_contract_result(
      FALSE, paste0(
        "opportunity record_status differs from exact precedence: ",
        paste(INV_RECORD_STATUS_PRECEDENCE, collapse = " > ")
      )
    ))
  }
  status <- as.character(bundle$opportunities$record_status)
  if (any(is.na(status) | !status %in% INV_RECORD_STATUS_LEVELS)) {
    return(inv_contract_result(FALSE, "opportunity ledger has an unknown status"))
  }
  practical <- inv_true(bundle$opportunities$sampling_practical)
  processing_status <- inv_chr(bundle$opportunities$processing_count_status)
  if (any(is.na(processing_status[practical]) |
          !processing_status[practical] %in%
            INV_PROCESSING_COUNT_STATUS_LEVELS) ||
      any(!is.na(processing_status[!practical]))) {
    return(inv_contract_result(
      FALSE,
      "practical opportunities do not have one exclusive processing/count status"
    ))
  }
  expected_summary_counts <- c(
    n_opportunities = nrow(bundle$opportunities),
    n_sampling_impractical = sum(!bundle$opportunities$sampling_practical),
    n_nonstandard_collection = sum(bundle$opportunities$nonstandard_collection),
    n_unstratifiable = sum(bundle$opportunities$unstratifiable),
    n_processing_unknown = sum(bundle$opportunities$processing_unknown),
    n_processed_no_taxonomy = sum(
      processing_status %in% "processed_no_taxonomy"
    ),
    n_taxonomy_count_unavailable = sum(
      bundle$opportunities$taxonomy_count_unavailable
    ),
    n_displayed_zero_percent_authoritative_estimate = sum(
      bundle$opportunities$displayed_zero_percent_authoritative_estimate
    ),
    n_count_samples = sum(bundle$opportunities$count_eligible),
    n_density_samples = sum(bundle$opportunities$density_eligible)
  )
  for (summary_name in names(expected_summary_counts)) {
    if (!identical(num(summary_row[[summary_name]]),
                   num(expected_summary_counts[[summary_name]]))) {
      return(inv_contract_result(
        FALSE, sprintf("site_summary$%s differs from opportunity support flags",
                       summary_name)
      ))
    }
  }
  summary_map <- c(
    n_events = "n_events", n_strata = "n_strata",
    n_opportunities = "n_opportunities",
    n_count_samples = "n_count_samples",
    n_density_samples = "n_density_samples",
    n_unstratifiable = "n_unstratifiable",
    n_processing_unknown = "n_processing_unknown",
    n_taxonomy_count_unavailable = "n_taxonomy_count_unavailable",
    n_displayed_zero_percent_authoritative_estimate =
      "n_displayed_zero_percent_authoritative_estimate",
    n_taxa_recorded = "n_taxa_recorded"
  )
  for (meta_name in names(summary_map)) {
    summary_name <- summary_map[[meta_name]]
    if (!identical(num(bundle$meta[[meta_name]]),
                   num(summary_row[[summary_name]]))) {
      return(inv_contract_result(
        FALSE, sprintf("meta$%s differs from site_summary$%s",
                       meta_name, summary_name)
      ))
    }
  }
  if (!identical(as.character(bundle$meta$taxonomic_ranks),
                 as.character(summary_row$taxonomic_ranks))) {
    return(inv_contract_result(FALSE,
                               "meta taxonomic ranks differ from site_summary"))
  }
  composition_eligible <- bundle$opportunities$count_eligible &
    is.finite(num(bundle$opportunities$total_estimated_count)) &
    num(bundle$opportunities$total_estimated_count) > 0
  expected_meta_counts <- c(
    n_opportunities = nrow(bundle$opportunities),
    n_primary_opportunities = sum(bundle$opportunities$primary_stratum),
    n_count_samples = sum(bundle$opportunities$count_eligible),
    n_composition_samples = sum(composition_eligible),
    n_density_samples = sum(bundle$opportunities$density_eligible),
    n_reported_zero_count = sum(bundle$opportunities$reported_zero_count),
    n_unstratifiable = sum(bundle$opportunities$unstratifiable)
  )
  for (meta_name in names(expected_meta_counts)) {
    if (!identical(num(bundle$meta[[meta_name]]),
                   num(expected_meta_counts[[meta_name]]))) {
      return(inv_contract_result(
        FALSE, sprintf("meta$%s differs from opportunity support flags",
                       meta_name)
      ))
    }
  }
  count_ok <- inv_true(bundle$opportunities$count_eligible)
  density_ok <- inv_true(bundle$opportunities$density_eligible)
  reported_zero <- inv_true(bundle$opportunities$reported_zero_count)
  if (any(density_ok & !count_ok)) {
    return(inv_contract_result(FALSE, "density eligibility is not a subset of count eligibility"))
  }
  zero_values <- num(bundle$opportunities$total_estimated_count)
  if (any(reported_zero & (!count_ok | !is.finite(zero_values) | zero_values != 0))) {
    return(inv_contract_result(FALSE, "reported-zero semantics are inconsistent"))
  }
  if (!isTRUE(bundle$provenance$field_first) ||
      !identical(as.character(bundle$provenance$exact_grain), INV_EXACT_GRAIN)) {
    return(inv_contract_result(FALSE, "field-first exact-grain provenance is absent"))
  }
  provenance_fields <- c(
    "source", "producer_schema_version", "science_version", "field_first",
    "exact_grain", "qc_contract", "prohibited_inference"
  )
  missing_provenance <- setdiff(provenance_fields, names(bundle$provenance))
  if (length(missing_provenance)) {
    return(inv_contract_result(
      FALSE, sprintf("provenance is missing %s", missing_provenance[[1L]])
    ))
  }
  if (!identical(as.character(bundle$provenance$producer_schema_version),
                 INV_PRODUCER_SCHEMA_VERSION) ||
      !inv_scalar_text(bundle$provenance$science_version)) {
    return(inv_contract_result(FALSE, "producer/science provenance is invalid"))
  }
  source_check <- inv_source_identity(bundle$provenance$source)
  if (!isTRUE(source_check)) return(source_check)
  if (!identical(as.character(bundle$meta$source_stamp),
                 as.character(bundle$provenance$source$publication_date_max))) {
    return(inv_contract_result(FALSE, "bundle source stamp differs from provenance"))
  }
  required_metrics <- c(
    "mean_sample_density_m2", "mean_sample_taxa_observed",
    "mean_sample_pct_ept_of_all_estimated_count", "taxon_support_pct",
    "taxon_total_estimated_count"
  )
  if (!all(required_metrics %in% bundle$metric_contract$metric)) {
    return(inv_contract_result(FALSE, "metric contract is incomplete"))
  }
  metric_grain <- as.character(bundle$metric_contract$grain)
  if (any(is.na(metric_grain) |
          !startsWith(metric_grain, INV_EXACT_GRAIN))) {
    return(inv_contract_result(FALSE, "metric contract leaves the exact grain"))
  }
  qc_check <- inv_validate_qc(bundle$qc, bundle$opportunities, site)
  if (!isTRUE(qc_check)) return(qc_check)
  if (!identical(bundle$provenance$qc_contract, bundle$qc$contract)) {
    return(inv_contract_result(FALSE,
                               "QC provenance differs from the bundle QC contract"))
  }
  if (!is.null(release_contract)) {
    contract_check <- inv_validate_release_contract(release_contract)
    if (!isTRUE(contract_check)) return(contract_check)
    if (!site %in% as.character(release_contract$site_ids) ||
        !identical(unname(as.character(bundle$provenance$science_version)),
                   unname(as.character(release_contract$science_version))) ||
        !inv_source_identity_equal(bundle$provenance$source,
                                   release_contract$source) ||
        !identical(bundle$metric_contract, release_contract$metric_contract) ||
        !identical(bundle$qc$contract, release_contract$qc_contract)) {
      return(inv_contract_result(FALSE,
                                 "bundle identity differs from release contract"))
    }
  }
  inv_contract_result(TRUE)
}

inv_validate_site_index <- function(index, release_contract = NULL) {
  check <- inv_require_columns(index, INV_SITE_INDEX_COLUMNS, "site_index")
  if (!isTRUE(check)) return(check)
  if (!identical(names(index), INV_SITE_INDEX_COLUMNS)) {
    return(inv_contract_result(FALSE,
                               "site_index columns differ from support-only schema"))
  }
  if (!nrow(index) || anyDuplicated(index$site) || any(is.na(inv_chr(index$site)))) {
    return(inv_contract_result(FALSE, "site_index roster is empty or non-unique"))
  }
  prohibited <- intersect(
    c("density_m2", "mean_sample_density_m2", "richness", "ept_richness",
      "pct_ept_ind", "pct_ept_taxa", "hill_q1", "health_score"),
    names(index)
  )
  if (length(prohibited)) {
    return(inv_contract_result(
      FALSE, sprintf("site_index contains prohibited comparison field %s",
                     prohibited[[1L]])
    ))
  }
  count_fields <- c(
    "n_events", "n_strata", "n_opportunities", "n_primary_opportunities",
    "n_count_samples", "n_composition_samples", "n_density_samples",
    "n_reported_zero_count", "n_unstratifiable", "n_taxa_recorded",
    "n_sampling_impractical", "n_nonstandard_collection",
    "n_processing_unknown", "n_processed_no_taxonomy",
    "n_taxonomy_count_unavailable",
    "n_displayed_zero_percent_authoritative_estimate",
    "n_count_unavailable", "n_area_unavailable",
    "n_density_unavailable"
  )
  count_values <- as.matrix(data.frame(lapply(index[count_fields], num)))
  if (any(!is.finite(count_values) | count_values < 0)) {
    return(inv_contract_result(FALSE,
                               "site_index support counts are invalid"))
  }
  if (!is.null(release_contract)) {
    contract_check <- inv_validate_release_contract(release_contract)
    if (!isTRUE(contract_check)) return(contract_check)
    source_stamp <- inv_chr(index$source_stamp)
    science_version <- inv_chr(index$science_version)
    if (!identical(as.character(index$site),
                   as.character(release_contract$site_ids)) ||
        any(is.na(source_stamp) | source_stamp !=
              as.character(release_contract$source$publication_date_max)) ||
        any(is.na(science_version) | science_version !=
              as.character(release_contract$science_version))) {
      return(inv_contract_result(FALSE,
                                 "site_index identity differs from release contract"))
    }
  }
  inv_contract_result(TRUE)
}

inv_validate_search_index <- function(index, release_contract = NULL,
                                      site_index = NULL) {
  expected_members <- c(
    "schema_version", "taxa", "sites", "metric_contract", "source", "built",
    "boundary"
  )
  if (!is.list(index) || !identical(names(index), expected_members)) {
    return(inv_contract_result(FALSE, "search_index members are incomplete"))
  }
  if (!identical(as.character(index$schema_version),
                 INV_PRODUCER_SCHEMA_VERSION)) {
    return(inv_contract_result(FALSE, "search_index schema version is invalid"))
  }
  taxa_check <- inv_require_columns(
    index$taxa, INV_SEARCH_TAXON_COLUMNS,
    "search_index$taxa"
  )
  if (!isTRUE(taxa_check)) return(taxa_check)
  if (!identical(names(index$taxa), INV_SEARCH_TAXON_COLUMNS)) {
    return(inv_contract_result(FALSE,
                               "search_index taxon columns differ from support schema"))
  }
  if (nrow(index$taxa)) {
    denominator <- num(index$taxa$n_count_eligible_samples)
    present <- num(index$taxa$n_samples_present)
    support <- num(index$taxa$support_pct)
    if (any(!is.finite(denominator) | denominator <= 0 |
            !is.finite(present) | present <= 0 | present > denominator |
            !is.finite(support) | support <= 0 | support > 100)) {
      return(inv_contract_result(FALSE,
                                 "search_index taxon support is invalid"))
    }
  }
  site_check <- inv_validate_site_index(index$sites, release_contract)
  if (!isTRUE(site_check)) return(site_check)
  source_check <- inv_source_identity(index$source)
  if (!isTRUE(source_check)) return(source_check)
  if (!is.null(site_index) && !identical(index$sites, site_index)) {
    return(inv_contract_result(FALSE,
                               "search_index site table differs from site_index"))
  }
  if (!is.null(release_contract) &&
      (!inv_source_identity_equal(index$source, release_contract$source) ||
       !identical(index$metric_contract, release_contract$metric_contract) ||
       !identical(as.character(index$built),
                  as.character(release_contract$source$publication_date_max)))) {
    return(inv_contract_result(FALSE,
                               "search_index identity differs from release contract"))
  }
  inv_contract_result(TRUE)
}

inv_year_label <- function(meta) {
  lo <- suppressWarnings(as.Date(meta$collectDate_min %||% NA_character_))
  hi <- suppressWarnings(as.Date(meta$collectDate_max %||% NA_character_))
  if (is.na(lo) || is.na(hi)) return("date range unavailable")
  yl <- format(lo, "%Y")
  yh <- format(hi, "%Y")
  if (identical(yl, yh)) yl else paste0(yl, "–", yh)
}

inv_value <- function(x, digits = 0L, suffix = "") {
  value <- suppressWarnings(as.numeric(x))
  if (length(value) != 1L || !is.finite(value)) return("Unavailable")
  paste0(format(round(value, digits), big.mark = ",", trim = TRUE,
                nsmall = digits), suffix)
}

inv_status_ledger <- function(opportunities) {
  counts <- table(factor(
    as.character(opportunities$record_status), levels = INV_RECORD_STATUS_LEVELS
  ))
  out <- merge(
    INV_STATUS_META,
    data.frame(record_status = names(counts), n = as.integer(counts),
               stringsAsFactors = FALSE),
    by = "record_status", all.x = TRUE, sort = FALSE
  )
  out <- out[match(INV_RECORD_STATUS_LEVELS, out$record_status), , drop = FALSE]
  rownames(out) <- NULL
  out
}

# `processing_count_status` is the exhaustive outcome partition for practical
# opportunities. Unlike record_status, it is not masked by comparison-grain or
# nonstandard-collection precedence.
inv_processing_count_counts <- function(opportunities) {
  if (is.null(opportunities) || !nrow(opportunities)) {
    return(stats::setNames(
      rep(0L, length(INV_PROCESSING_COUNT_STATUS_LEVELS)),
      INV_PROCESSING_COUNT_STATUS_LEVELS
    ))
  }
  counts <- table(factor(
    as.character(opportunities$processing_count_status),
    levels = INV_PROCESSING_COUNT_STATUS_LEVELS
  ))
  stats::setNames(as.integer(counts), names(counts))
}

# These support conditions can overlap the dominant record_status. For example,
# a usable reported zero with no benthic area has record_status =
# "area_unavailable" and reported_zero_count = TRUE. Never use the mutually
# exclusive status ledger to total these flags.
inv_support_counts <- function(opportunities) {
  if (is.null(opportunities) || !nrow(opportunities)) {
    return(c(
      sampling_impractical = 0L, nonstandard_collection = 0L,
      unstratifiable = 0L, processing_unknown = 0L,
      taxonomy_count_unavailable = 0L, reported_zero_count = 0L,
      displayed_zero_percent_authoritative_estimate = 0L
    ))
  }
  practical <- as.logical(opportunities$sampling_practical)
  c(
    sampling_impractical = sum(practical %in% FALSE),
    nonstandard_collection = sum(
      as.logical(opportunities$nonstandard_collection) %in% TRUE
    ),
    unstratifiable = sum(as.logical(opportunities$unstratifiable) %in% TRUE),
    processing_unknown = sum(
      as.logical(opportunities$processing_unknown) %in% TRUE
    ),
    taxonomy_count_unavailable = sum(
      as.logical(opportunities$taxonomy_count_unavailable) %in% TRUE
    ),
    displayed_zero_percent_authoritative_estimate = sum(
      as.logical(
        opportunities$displayed_zero_percent_authoritative_estimate
      ) %in% TRUE
    ),
    reported_zero_count = sum(
      as.logical(opportunities$reported_zero_count) %in% TRUE
    )
  )
}

inv_stratum_label <- function(row, include_event = TRUE) {
  event <- if (isTRUE(include_event)) paste0(row$eventID, " · ") else ""
  paste0(
    event, row$aquaticSiteType, " · ", row$habitatType, " · ", row$samplerType
  )
}

inv_stratum_choices <- function(strata) {
  if (is.null(strata) || !nrow(strata)) return(character())
  labels <- vapply(seq_len(nrow(strata)), function(i) {
    inv_stratum_label(strata[i, , drop = FALSE], include_event = TRUE)
  }, character(1))
  stats::setNames(as.character(strata$stratum_key), labels)
}

inv_taxon_label <- function(scientific_name, rank, is_ept = FALSE) {
  nm <- inv_chr(scientific_name)
  rk <- inv_chr(rank)
  ifelse(
    is.na(nm), "Unnamed taxon",
    paste0(nm, ifelse(is.na(rk), " [rank unavailable]", paste0(" [", rk, "]")),
           ifelse(inv_true(is_ept), " · EPT", ""))
  )
}

inv_taxa_for_stratum <- function(taxa, key) {
  if (is.null(taxa) || !nrow(taxa) || is.null(key) || !nzchar(key)) {
    return(taxa[0, , drop = FALSE])
  }
  out <- taxa[as.character(taxa$stratum_key) == as.character(key), , drop = FALSE]
  if (!nrow(out)) return(out)
  out$taxon_label <- inv_taxon_label(out$scientificName, out$taxonRank,
                                     out$is_ept)
  out[order(-num(out$support_pct), -num(out$total_estimated_count),
            out$taxon_label), , drop = FALSE]
}

inv_opportunity_export <- function(opportunities) {
  keep <- intersect(
    c("opportunity_id", "sampleID", "sampleCode", "siteID", "eventID",
      "collectDate", "aquaticSiteType", "habitatType", "samplerType",
      "namedLocation", "samplingImpractical", "record_status",
      "primary_stratum", "processing_unknown",
      "taxonomy_count_unavailable",
      "displayed_zero_percent_authoritative_estimate",
      "processing_count_status", "taxonomy_rows", "count_issue",
      "density_issue",
      "benthicArea_m2", "total_estimated_count", "count_eligible",
      "density_eligible", "reported_zero_count", "sample_density_m2",
      "taxa_observed", "ept_taxa_observed",
      "pct_ept_of_all_estimated_count",
      "pct_order_classified_estimated_count"),
    names(opportunities)
  )
  opportunities[, keep, drop = FALSE]
}

inv_codebook <- function() {
  data.frame(
    field = c(
      "record_status", "n_opportunities", "n_count_samples",
      "n_composition_samples", "n_density_samples", "reported_zero_count",
      "mean_sample_density_m2", "mean_sample_taxa_observed",
      "mean_sample_pct_ept_of_all_estimated_count",
      "mean_sample_pct_order_classified_estimated_count", "support_pct",
      "total_estimated_count", "taxonRank", "NA"
    ),
    interpretation = c(
      "Mutually exclusive field-first processing state; use the status ledger for definitions.",
      "All field opportunities in the exact stratum.",
      "Processed samples with usable expanded counts in the exact stratum.",
      "Count-eligible samples whose expanded total is positive; denominator for composition means.",
      "Count-eligible samples with usable benthic area in the exact stratum.",
      "A usable expanded laboratory count reported as zero; not a field-verified absence.",
      "Arithmetic mean of sample densities among density-eligible samples in one exact stratum; descriptive collection density only.",
      "Arithmetic mean of recorded mixed-rank taxon counts among count-eligible samples in one exact stratum.",
      "Mean sample EPT expanded-count share; all positive counts, including unknown order, remain in the denominator.",
      "Mean share of positive expanded counts whose order is recorded; classification-support diagnostic.",
      "Positive-count samples divided by count-eligible samples for one taxon in one exact stratum; eligible samples without the taxon are zero-filled.",
      "Expanded laboratory count summed over count-eligible samples in one exact stratum; not a population count.",
      "Identification rank is retained; mixed ranks must not be read as species-only diversity.",
      "Unavailable or inapplicable under the stated denominator; never silently converted to zero."
    ),
    stringsAsFactors = FALSE
  )
}

inv_provenance_table <- function(bundle) {
  source <- bundle$provenance$source %||% list()
  data.frame(
    item = c(
      "Data product", "Release", "Provisional included", "Publication through",
      "Fetched (UTC)", "Raw artifact SHA-256", "Source receipt SHA-256",
      "Science contract", "Bundle schema", "Analysis grain"
    ),
    value = c(
      source$dpid %||% "Unavailable", source$release %||% "Unavailable",
      if (isTRUE(source$include_provisional)) "Yes" else "No",
      source$publication_date_max %||% "Unavailable",
      source$fetched_at_utc %||% "Unavailable",
      source$artifact_sha256 %||% "Unavailable",
      source$receipt_sha256 %||% "Unavailable",
      bundle$provenance$science_version %||% "Unavailable",
      bundle$schema_version %||% "Unavailable", INV_EXACT_GRAIN
    ),
    stringsAsFactors = FALSE
  )
}

inv_safe_filename <- function(site, suffix, extension = "csv") {
  paste0("neon-inverts-", tolower(gsub("[^A-Za-z0-9]+", "-", site)), "-",
         suffix, ".", extension)
}

INV_NETWORK_EXPORT_COLUMNS <- c(
  "site", "name", "aquaticSiteType", "collectDate_min", "collectDate_max",
  "n_opportunities", "n_primary_opportunities", "n_events", "n_strata",
  "n_count_samples", "n_composition_samples", "n_density_samples",
  "n_reported_zero_count", "n_unstratifiable", "n_processing_unknown",
  "n_processed_no_taxonomy", "n_taxonomy_count_unavailable",
  "n_displayed_zero_percent_authoritative_estimate", "n_taxa_recorded",
  "n_sampling_impractical", "n_nonstandard_collection",
  "n_count_unavailable", "n_area_unavailable", "n_density_unavailable",
  "taxonomic_ranks", "source_stamp"
)

inv_comparison_choices <- c(
  n_opportunities = "Field opportunities",
  n_primary_opportunities = "Primary-stratum opportunities",
  n_events = "Collection events",
  n_strata = "Exact event strata",
  n_count_samples = "Count-eligible samples",
  n_composition_samples = "Positive-total composition samples",
  n_density_samples = "Density-eligible samples",
  n_reported_zero_count = "Reported zero-count samples",
  n_unstratifiable = "Opportunities with unavailable stratum fields",
  n_taxa_recorded = "Distinct mixed-rank taxa recorded",
  n_sampling_impractical = "Sampling-impractical opportunities",
  n_processing_unknown = "Field opportunities with unknown processing outcome",
  n_processed_no_taxonomy =
    "Per-sample processing records with no taxonomy outcome",
  n_taxonomy_count_unavailable = "Taxonomy outcomes with count unavailable",
  n_displayed_zero_percent_authoritative_estimate =
    "Published estimates linked to integer-displayed 0% subsamples"
)

inv_comparison_label <- function(key) {
  unname(inv_comparison_choices[[key]]) %||% key
}
