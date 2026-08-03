#!/usr/bin/env Rscript

# Independent, bundle-only verifier for the Pass-9 release. This deliberately
# does not source the producer or science transform.

INV_RELEASE_EXPECTED_SITES <- c(
  "ARIK", "BARC", "BIGC", "BLDE", "BLUE", "BLWA", "CARI", "COMO",
  "CRAM", "CUPE", "FLNT", "GUIL", "HOPB", "KING", "LECO", "LEWI",
  "LIRO", "MART", "MAYF", "MCDI", "MCRA", "OKSR", "POSE", "PRIN",
  "PRLA", "PRPO", "REDB", "SUGG", "SYCA", "TECR", "TOMB", "TOOK",
  "WALK", "WLOU"
)
INV_RELEASE_QC_FIELDS <- list(
  field = "dataQF",
  per_sample = c(
    "dataQF", "qcSortDate", "qcSortingEfficacy", "qcIterationCount",
    "qcPercentSimilarity", "qcSortedBy", "qcEnumerationDifference",
    "qcTaxonomicDifference"
  ),
  taxonomy_processed = c("qcChecked", "dataQF")
)
INV_RELEASE_ISSUE_FIELDS <- c(
  "id", "parentIssueID", "issueDate", "resolvedDate", "dateRangeStart",
  "dateRangeEnd", "locationAffected", "issue", "resolution"
)
INV_RELEASE_ISSUE_ANNOTATIONS <- c(
  "bundle_site", "site_scope_basis", "site_scope_match",
  "site_collect_date_min", "site_collect_date_max", "date_scope_basis",
  "date_overlap", "potentially_applicable", "annotation_only"
)
INV_RELEASE_STATUS_LEVELS <- c(
  "sampling_impractical", "unstratifiable", "nonstandard_collection",
  "processed_no_taxonomy", "count_unavailable", "area_unavailable",
  "density_unavailable", "reported_zero_count", "quantified_community"
)
INV_RELEASE_BUNDLE_MEMBERS <- c(
  "schema_version", "opportunities", "event_strata", "taxon_strata",
  "site_summary", "meta", "metric_contract", "qc", "provenance"
)
INV_RELEASE_OPPORTUNITY_COLUMNS <- c(
  "opportunity_id", "sample_key", "sampleID", "sampleCode", "siteID",
  "eventID", "collectDate", "aquaticSiteType", "habitatType", "samplerType",
  "namedLocation", "sampleNumber", "samplingImpractical", "stratum_key",
  "has_per_sample", "sampling_practical", "sampler_type_normalized",
  "nonstandard_id_hint", "grain_complete", "unstratifiable",
  "nonstandard_collection", "primary_stratum", "taxonomy_rows",
  "record_status", "count_issue", "density_issue", "benthicArea_m2",
  "total_estimated_count", "count_eligible", "density_eligible",
  "reported_zero_count", "sample_density_m2", "taxa_observed",
  "ept_taxa_observed", "hill_q1", "hill_q2",
  "pct_ept_of_all_estimated_count",
  "pct_order_classified_estimated_count"
)
INV_RELEASE_EVENT_COLUMNS <- c(
  "stratum_key", "siteID", "eventID", "aquaticSiteType", "habitatType",
  "samplerType", "collectDate_min", "collectDate_max", "n_opportunities",
  "n_sampling_impractical", "n_processed_no_taxonomy",
  "n_count_unavailable", "n_area_unavailable", "n_density_unavailable",
  "n_count_samples", "n_composition_samples", "n_density_samples",
  "n_reported_zero_count", "mean_sample_density_m2",
  "median_sample_density_m2", "sd_sample_density_m2",
  "se_sample_density_m2", "mean_sample_taxa_observed",
  "mean_sample_ept_taxa_observed", "mean_sample_hill_q1",
  "mean_sample_hill_q2", "mean_sample_pct_ept_of_all_estimated_count",
  "mean_sample_pct_order_classified_estimated_count"
)
INV_RELEASE_TAXON_COLUMNS <- c(
  "stratum_key", "siteID", "eventID", "aquaticSiteType", "habitatType",
  "samplerType", "taxon_key", "acceptedTaxonID", "scientificName",
  "taxonRank", "order", "family", "class", "subclass", "is_ept",
  "order_classified", "n_count_eligible_samples",
  "n_density_eligible_samples", "n_samples_present", "support_pct",
  "mean_sample_density_m2", "median_sample_density_m2",
  "total_estimated_count"
)
INV_RELEASE_SITE_SUMMARY_COLUMNS <- c(
  "siteID", "collectDate_min", "collectDate_max", "n_events", "n_strata",
  "n_opportunities", "n_sampling_impractical", "n_nonstandard_collection",
  "n_unstratifiable", "n_processed_no_taxonomy", "n_count_samples",
  "n_density_samples", "n_taxa_recorded", "taxonomic_ranks"
)
INV_RELEASE_SITE_INDEX_COLUMNS <- c(
  "site", "aquaticSiteType", "lat", "lng", "elevation", "collectDate_min",
  "collectDate_max", "n_events", "n_strata", "n_opportunities",
  "n_primary_opportunities", "n_count_samples", "n_composition_samples",
  "n_density_samples", "n_reported_zero_count", "n_unstratifiable",
  "n_taxa_recorded", "n_sampling_impractical", "n_nonstandard_collection",
  "n_processed_no_taxonomy", "n_count_unavailable", "n_area_unavailable",
  "n_density_unavailable", "taxonomic_ranks", "source_stamp",
  "science_version"
)
INV_RELEASE_SEARCH_TAXON_COLUMNS <- c(
  "siteID", "eventID", "aquaticSiteType", "habitatType", "samplerType",
  "taxon_key", "acceptedTaxonID", "scientificName", "taxonRank", "order",
  "family", "class", "subclass", "is_ept", "order_classified",
  "n_count_eligible_samples", "n_samples_present", "support_pct"
)
INV_RELEASE_FIELD_QC_IDENTITY <- c(
  "siteID", "namedLocation", "eventID", "sampleID", "sampleCode",
  "habitatType", "samplerType", "sampleNumber", "collectDate"
)
INV_RELEASE_PER_SAMPLE_QC_IDENTITY <- c("siteID", "sampleID", "sampleCode")
INV_RELEASE_TAXONOMY_QC_IDENTITY <- c(
  "siteID", "sampleID", "sampleCode", "slideID", "slideCode",
  "scientificName", "morphospeciesID", "invertebrateLifeStage", "sizeClass",
  "sizeCategory", "immatureSpecimen", "indeterminateSpecies",
  "taxonRankQualifier", "sampleCondition", "distinctTaxon",
  "identificationRemarks", "acceptedTaxonID", "taxonRank"
)
INV_RELEASE_MEASUREMENT_METADATA <- data.frame(
  table = c("inv_fieldData", rep("inv_taxonomyProcessed", 3L)),
  fieldName = c(
    "benthicArea", "individualCount", "subsamplePercent",
    "estimatedTotalCount"
  ),
  description = c(
    "Area of the benthos sampled",
    "Number of individuals of the same type",
    "Percent of the total sample contained in the subsample",
    paste(
      "Estimated total count of individuals within a sample, of given taxon,",
      "life stage, and size class"
    )
  ),
  dataType = c("real", "unsigned integer", "real", "real"),
  units = c("squareMeter", "number", "percent", "number"),
  stringsAsFactors = FALSE
)

inv_release_fail <- function(...) stop(sprintf(...), call. = FALSE)

inv_release_assert <- function(ok, ...) {
  if (!isTRUE(ok)) inv_release_fail(...)
}

inv_release_blank <- function(x) {
  is.na(x) | !nzchar(trimws(as.character(x)))
}

inv_release_chr <- function(x, missing = "(not recorded)") {
  value <- trimws(as.character(x))
  value[is.na(value) | !nzchar(value)] <- missing
  value
}

inv_release_num <- function(x) suppressWarnings(as.numeric(as.character(x)))

inv_release_pair_key <- function(sample_id, sample_code) {
  paste(inv_release_chr(sample_id), inv_release_chr(sample_code), sep = "\u241f")
}

inv_release_date_range <- function(x) {
  dates <- suppressWarnings(as.Date(substr(as.character(x), 1L, 10L)))
  dates <- dates[!is.na(dates)]
  if (!length(dates)) return(c(NA_character_, NA_character_))
  as.character(range(dates))
}

inv_release_mean <- function(x) {
  x <- inv_release_num(x)
  x <- x[is.finite(x)]
  if (length(x)) mean(x) else NA_real_
}

inv_release_median <- function(x) {
  x <- inv_release_num(x)
  x <- x[is.finite(x)]
  if (length(x)) stats::median(x) else NA_real_
}

inv_release_sd <- function(x) {
  x <- inv_release_num(x)
  x <- x[is.finite(x)]
  if (length(x) <= 1L) return(NA_real_)
  center <- mean(x)
  delta <- x - center
  scale <- max(abs(delta))
  if (!is.finite(center) || !is.finite(scale)) return(NA_real_)
  if (scale == 0) return(0)
  value <- scale * sqrt(sum((delta / scale)^2) / (length(x) - 1L))
  if (is.finite(value)) value else NA_real_
}

inv_release_vector_equal <- function(actual, expected, tolerance = 1e-10) {
  if (length(actual) != length(expected)) return(FALSE)
  if (is.numeric(actual) || is.integer(actual) ||
      is.numeric(expected) || is.integer(expected)) {
    actual <- inv_release_num(actual)
    expected <- inv_release_num(expected)
    if (!identical(is.na(actual), is.na(expected))) return(FALSE)
    keep <- !is.na(actual)
    if (!all(is.finite(actual[keep]) == is.finite(expected[keep]))) return(FALSE)
    finite <- keep & is.finite(actual) & is.finite(expected)
    if (any(abs(actual[finite] - expected[finite]) >
            tolerance * pmax(1, abs(actual[finite]), abs(expected[finite])))) {
      return(FALSE)
    }
    nonfinite <- keep & !is.finite(actual)
    return(identical(as.character(actual[nonfinite]),
                     as.character(expected[nonfinite])))
  }
  if (is.logical(actual) || is.logical(expected)) {
    return(identical(as.logical(actual), as.logical(expected)))
  }
  identical(as.character(actual), as.character(expected))
}

inv_release_frame_equal <- function(actual, expected, tolerance = 1e-10) {
  if (!is.data.frame(actual) || !is.data.frame(expected) ||
      !identical(names(actual), names(expected)) || nrow(actual) != nrow(expected)) {
    return(FALSE)
  }
  all(vapply(names(actual), function(column) {
    inv_release_vector_equal(actual[[column]], expected[[column]], tolerance)
  }, logical(1)))
}

inv_release_assert_frame_equal <- function(actual, expected, label,
                                           tolerance = 1e-10) {
  inv_release_assert(inv_release_frame_equal(actual, expected, tolerance),
                     "%s differs from its independently recomputed table", label)
  invisible(actual)
}

inv_release_sort_frame <- function(x, keys) {
  if (!nrow(x)) {
    rownames(x) <- NULL
    return(x)
  }
  ordering <- do.call(order, c(lapply(x[keys], function(value) {
    out <- as.character(value)
    out[is.na(out)] <- "<NA>"
    out
  }), list(na.last = TRUE, method = "radix")))
  out <- x[ordering, , drop = FALSE]
  rownames(out) <- NULL
  out
}

inv_release_status_count <- function(opportunities, status) {
  as.integer(sum(as.character(opportunities$record_status) == status))
}

inv_release_sha256 <- function(path) {
  inv_release_assert(requireNamespace("digest", quietly = TRUE),
                     "digest is required for release verification")
  inv_release_assert(file.exists(path), "Missing release file: %s", path)
  unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
}

inv_release_valid_git_sha <- function(value) {
  length(value) == 1L && !is.na(value) &&
    grepl("^[0-9a-f]{40}$", as.character(value))
}

inv_release_recursive_names <- function(x) {
  own <- names(x)
  if (is.null(own)) own <- character()
  if (!is.list(x)) return(own)
  unique(c(own, unlist(lapply(x, inv_release_recursive_names), use.names = FALSE)))
}

inv_release_require_columns <- function(x, label, columns) {
  inv_release_assert(is.data.frame(x), "%s is not a data frame", label)
  missing <- setdiff(columns, names(x))
  inv_release_assert(!length(missing), "%s lacks required columns: %s",
                     label, paste(missing, collapse = ", "))
  invisible(x)
}

inv_release_expected_events <- function(opportunities) {
  primary <- opportunities[opportunities$primary_stratum, , drop = FALSE]
  if (!nrow(primary)) {
    empty <- as.data.frame(stats::setNames(replicate(
      length(INV_RELEASE_EVENT_COLUMNS), logical(), simplify = FALSE
    ), INV_RELEASE_EVENT_COLUMNS), stringsAsFactors = FALSE)
    return(empty)
  }
  groups <- split(seq_len(nrow(primary)), primary$stratum_key, drop = TRUE)
  rows <- lapply(groups, function(index) {
    part <- primary[index, , drop = FALSE]
    count_part <- part[part$count_eligible, , drop = FALSE]
    composition_part <- count_part[
      is.finite(count_part$total_estimated_count) &
        count_part$total_estimated_count > 0, , drop = FALSE
    ]
    density_part <- part[part$density_eligible, , drop = FALSE]
    dates <- inv_release_date_range(part$collectDate)
    density_sd <- inv_release_sd(density_part$sample_density_m2)
    n_density <- nrow(density_part)
    data.frame(
      stratum_key = as.character(part$stratum_key[[1]]),
      siteID = as.character(part$siteID[[1]]),
      eventID = as.character(part$eventID[[1]]),
      aquaticSiteType = as.character(part$aquaticSiteType[[1]]),
      habitatType = as.character(part$habitatType[[1]]),
      samplerType = as.character(part$samplerType[[1]]),
      collectDate_min = dates[[1]], collectDate_max = dates[[2]],
      n_opportunities = nrow(part),
      n_sampling_impractical = inv_release_status_count(
        part, "sampling_impractical"
      ),
      n_processed_no_taxonomy = inv_release_status_count(
        part, "processed_no_taxonomy"
      ),
      n_count_unavailable = inv_release_status_count(part, "count_unavailable"),
      n_area_unavailable = inv_release_status_count(part, "area_unavailable"),
      n_density_unavailable = inv_release_status_count(
        part, "density_unavailable"
      ),
      n_count_samples = nrow(count_part),
      n_composition_samples = nrow(composition_part),
      n_density_samples = n_density,
      n_reported_zero_count = sum(part$reported_zero_count),
      mean_sample_density_m2 = inv_release_mean(
        density_part$sample_density_m2
      ),
      median_sample_density_m2 = inv_release_median(
        density_part$sample_density_m2
      ),
      sd_sample_density_m2 = density_sd,
      se_sample_density_m2 = if (n_density > 1L) {
        density_sd / sqrt(n_density)
      } else NA_real_,
      mean_sample_taxa_observed = inv_release_mean(count_part$taxa_observed),
      mean_sample_ept_taxa_observed = inv_release_mean(
        count_part$ept_taxa_observed
      ),
      mean_sample_hill_q1 = inv_release_mean(composition_part$hill_q1),
      mean_sample_hill_q2 = inv_release_mean(composition_part$hill_q2),
      mean_sample_pct_ept_of_all_estimated_count = inv_release_mean(
        composition_part$pct_ept_of_all_estimated_count
      ),
      mean_sample_pct_order_classified_estimated_count = inv_release_mean(
        composition_part$pct_order_classified_estimated_count
      ),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out <- inv_release_sort_frame(
    out, c("siteID", "eventID", "aquaticSiteType", "habitatType", "samplerType")
  )
  out[INV_RELEASE_EVENT_COLUMNS]
}

inv_release_expected_site_summary <- function(opportunities, taxa) {
  dates <- inv_release_date_range(opportunities$collectDate)
  primary <- opportunities[opportunities$primary_stratum, , drop = FALSE]
  taxon_keys <- if (nrow(taxa)) unique(as.character(taxa$taxon_key)) else character()
  ranks <- if (nrow(taxa)) {
    sort(unique(as.character(taxa$taxonRank[!inv_release_blank(taxa$taxonRank)])))
  } else character()
  data.frame(
    siteID = as.character(opportunities$siteID[[1]]),
    collectDate_min = dates[[1]], collectDate_max = dates[[2]],
    n_events = length(unique(as.character(primary$eventID))),
    n_strata = length(unique(as.character(primary$stratum_key))),
    n_opportunities = nrow(opportunities),
    n_sampling_impractical = sum(!opportunities$sampling_practical),
    n_nonstandard_collection = sum(opportunities$nonstandard_collection),
    n_unstratifiable = sum(opportunities$unstratifiable),
    n_processed_no_taxonomy = inv_release_status_count(
      opportunities, "processed_no_taxonomy"
    ),
    n_count_samples = sum(opportunities$count_eligible),
    n_density_samples = sum(opportunities$density_eligible),
    n_taxa_recorded = length(taxon_keys),
    taxonomic_ranks = paste(ranks, collapse = ", "),
    stringsAsFactors = FALSE
  )
}

inv_release_reconcile_taxa <- function(opportunities, events, taxa, site) {
  event_keys <- as.character(events$stratum_key)
  taxon_keys <- unique(as.character(taxa$stratum_key))
  inv_release_assert(!length(setdiff(taxon_keys, event_keys)),
                     "%s taxon rows contain an unknown event stratum", site)
  primary <- opportunities[opportunities$primary_stratum, , drop = FALSE]
  for (stratum in event_keys) {
    samples <- primary[primary$stratum_key == stratum, , drop = FALSE]
    count_samples <- samples[samples$count_eligible, , drop = FALSE]
    density_samples <- samples[samples$density_eligible, , drop = FALSE]
    taxon_part <- taxa[taxa$stratum_key == stratum, , drop = FALSE]
    expected_total <- sum(count_samples$total_estimated_count)
    actual_total <- sum(taxon_part$total_estimated_count)
    inv_release_assert(
      inv_release_vector_equal(actual_total, expected_total),
      "%s taxon totals do not reconcile for stratum %s", site, stratum
    )
    inv_release_assert(
      identical(as.integer(sum(taxon_part$n_samples_present)),
                as.integer(sum(count_samples$taxa_observed))),
      "%s taxon presence support does not reconcile for stratum %s", site,
      stratum
    )
    ept_presence <- if (nrow(taxon_part)) {
      sum(taxon_part$n_samples_present[taxon_part$is_ept])
    } else 0L
    inv_release_assert(
      identical(as.integer(ept_presence),
                as.integer(sum(count_samples$ept_taxa_observed))),
      "%s EPT presence support does not reconcile for stratum %s", site,
      stratum
    )
    if (nrow(taxon_part)) {
      inv_release_assert(
        all(as.integer(taxon_part$n_count_eligible_samples) ==
              nrow(count_samples)) &&
          all(as.integer(taxon_part$n_density_eligible_samples) ==
                nrow(density_samples)),
        "%s taxon denominators differ from event support for stratum %s",
        site, stratum
      )
    }
    expected_density_mean <- inv_release_mean(density_samples$sample_density_m2)
    actual_density_mean <- if (nrow(taxon_part)) {
      sum(taxon_part$mean_sample_density_m2)
    } else if (nrow(density_samples)) 0 else NA_real_
    inv_release_assert(
      inv_release_vector_equal(actual_density_mean, expected_density_mean),
      "%s taxon mean densities do not reconcile for stratum %s", site,
      stratum
    )
  }
  invisible(TRUE)
}

inv_release_reconcile_bundle <- function(bundle, site) {
  opportunities <- bundle$opportunities
  inv_release_assert(identical(names(opportunities),
                               INV_RELEASE_OPPORTUNITY_COLUMNS),
                     "%s opportunity columns differ from the exact schema", site)
  events <- bundle$event_strata
  taxa <- bundle$taxon_strata
  summary <- bundle$site_summary
  qc <- bundle$qc

  expected_events <- inv_release_expected_events(opportunities)
  inv_release_assert_frame_equal(events, expected_events,
                                 paste(site, "event strata"))
  inv_release_reconcile_taxa(opportunities, events, taxa, site)
  expected_summary <- inv_release_expected_site_summary(opportunities, taxa)
  inv_release_assert_frame_equal(summary, expected_summary,
                                 paste(site, "site summary"))

  expected_status <- table(factor(
    opportunities$record_status, levels = INV_RELEASE_STATUS_LEVELS
  ))
  expected_status <- data.frame(
    record_status = names(expected_status), n = as.integer(expected_status),
    stringsAsFactors = FALSE
  )
  inv_release_assert_frame_equal(qc$status_counts, expected_status,
                                 paste(site, "status counts"))

  composition <- opportunities$count_eligible &
    is.finite(opportunities$total_estimated_count) &
    opportunities$total_estimated_count > 0
  source_qc_rows <- c(
    field = nrow(qc$source_quality$field),
    per_sample = nrow(qc$source_quality$per_sample),
    taxonomy_processed = nrow(qc$source_quality$taxonomy_processed),
    issue_log = nrow(qc$issue_log)
  )
  expected_reconciliation <- list(
    opportunity_rows = nrow(opportunities), status_rows = nrow(opportunities),
    primary_opportunities = sum(opportunities$primary_stratum),
    count_eligible_samples = sum(opportunities$count_eligible),
    composition_eligible_samples = sum(composition),
    density_eligible_samples = sum(opportunities$density_eligible),
    reported_zero_count = sum(opportunities$reported_zero_count),
    unstratifiable = sum(opportunities$unstratifiable),
    taxonomy_rows_collapsed = sum(opportunities$taxonomy_rows),
    opportunity_complete = identical(
      nrow(opportunities),
      as.integer(qc$source_rows$collection_field_rows)
    ),
    count_contains_density = all(
      !opportunities$density_eligible | opportunities$count_eligible
    ),
    source_qc_rows_retained = source_qc_rows,
    qc_alters_metric_eligibility = FALSE
  )
  inv_release_assert(identical(names(qc$reconciliation),
                               names(expected_reconciliation)),
                     "%s QC reconciliation members differ from the exact schema",
                     site)
  for (field in names(expected_reconciliation)) {
    inv_release_assert(
      inv_release_vector_equal(qc$reconciliation[[field]],
                               expected_reconciliation[[field]]),
      "%s QC reconciliation field %s differs from the opportunity ledger",
      site, field
    )
  }

  meta_expected <- list(
    collectDate_min = expected_summary$collectDate_min,
    collectDate_max = expected_summary$collectDate_max,
    n_events = expected_summary$n_events,
    n_strata = expected_summary$n_strata,
    n_opportunities = expected_summary$n_opportunities,
    n_primary_opportunities = sum(opportunities$primary_stratum),
    n_count_samples = expected_summary$n_count_samples,
    n_composition_samples = sum(composition),
    n_density_samples = expected_summary$n_density_samples,
    n_reported_zero_count = sum(opportunities$reported_zero_count),
    n_unstratifiable = expected_summary$n_unstratifiable,
    n_taxa_recorded = expected_summary$n_taxa_recorded,
    taxonomic_ranks = expected_summary$taxonomic_ranks
  )
  for (field in names(meta_expected)) {
    inv_release_assert(
      inv_release_vector_equal(bundle$meta[[field]], meta_expected[[field]]),
      "%s meta$%s differs from the opportunity/taxon ledgers", site, field
    )
  }
  invisible(TRUE)
}

inv_release_verify_bundle <- function(bundle, site, contract) {
  inv_release_assert(identical(names(bundle), INV_RELEASE_BUNDLE_MEMBERS),
                     "%s bundle members differ from the exact schema", site)
  inv_release_assert(identical(as.character(bundle$schema_version),
                               as.character(contract$bundle_schema_version)),
                     "%s bundle schema version differs from release contract", site)
  inv_release_assert(identical(bundle$metric_contract, contract$metric_contract),
                     "%s metric contract differs from release contract", site)
  inv_release_assert(identical(as.character(bundle$meta$site), site),
                     "%s bundle carries meta$site=%s", site,
                     as.character(bundle$meta$site))
  inv_release_assert(identical(as.character(bundle$provenance$science_version),
                               as.character(contract$science_version)),
                     "%s science version differs from release contract", site)
  inv_release_assert(isTRUE(bundle$provenance$field_first),
                     "%s does not attest a field-first opportunity population", site)
  inv_release_assert(identical(bundle$provenance$qc_contract,
                               contract$qc_contract),
                     "%s provenance does not pin the official vF QC contract",
                     site)
  inv_release_assert(identical(bundle$provenance$source, contract$source),
                     "%s source provenance differs from release contract", site)
  inv_release_assert(
    identical(as.integer(bundle$provenance$source$metadata_rows[[
      "issueLog_20120"
    ]]), as.integer(bundle$qc$source_rows$issue_log_rows)),
    "%s issue-log rows differ from source provenance", site
  )

  opportunities <- bundle$opportunities
  inv_release_require_columns(opportunities, paste(site, "opportunities"), c(
    "opportunity_id", "sample_key", "siteID", "eventID", "aquaticSiteType",
    "habitatType", "samplerType", "stratum_key", "record_status",
    "primary_stratum", "count_eligible", "density_eligible",
    "reported_zero_count", "total_estimated_count", "taxonomy_rows"
  ))
  inv_release_assert(nrow(opportunities) > 0L &&
                       all(as.character(opportunities$siteID) == site),
                     "%s opportunity ledger is empty or crosses sites", site)
  inv_release_assert(!anyNA(opportunities$opportunity_id) &&
                       !anyDuplicated(opportunities$opportunity_id),
                     "%s opportunity identifiers are missing or duplicated", site)
  inv_release_assert(all(!opportunities$density_eligible |
                           opportunities$count_eligible),
                     "%s has density-eligible rows outside count eligibility", site)
  inv_release_assert(all(!opportunities$reported_zero_count |
                           (opportunities$count_eligible &
                              is.finite(opportunities$total_estimated_count) &
                              opportunities$total_estimated_count == 0)),
                     "%s has an unsupported reported-zero state", site)

  qc <- bundle$qc
  inv_release_assert(identical(qc$contract, contract$qc_contract),
                     "%s QC contract differs from release contract", site)
  inv_release_assert(isTRUE(qc$contract$retain_verbatim) &&
                       identical(qc$contract$automatic_exclusion, FALSE) &&
                       identical(as.character(qc$contract$eligibility_effect),
                                 "none"),
                     "%s QC contract permits silent filtering", site)
  inv_release_require_columns(qc$status_counts, paste(site, "status counts"),
                              c("record_status", "n"))
  inv_release_require_columns(qc$source_rows, paste(site, "source rows"), c(
    "site", "collection_field_rows", "metabarcode_field_rows",
    "per_sample_rows", "taxonomy_processed_rows", "field_qc_rows",
    "per_sample_qc_rows", "taxonomy_qc_rows", "issue_log_rows"
  ))
  inv_release_assert(nrow(qc$source_rows) == 1L &&
                       identical(as.character(qc$source_rows$site), site),
                     "%s source-row receipt is not site-exact", site)
  inv_release_assert(
    identical(as.integer(qc$source_rows$field_qc_rows),
              as.integer(qc$source_rows$collection_field_rows +
                           qc$source_rows$metabarcode_field_rows)) &&
      identical(as.integer(qc$source_rows$per_sample_qc_rows),
                as.integer(qc$source_rows$per_sample_rows)) &&
      identical(as.integer(qc$source_rows$taxonomy_qc_rows),
                as.integer(qc$source_rows$taxonomy_processed_rows)),
    "%s source-QC row ledger does not reconcile to source tables", site
  )
  inv_release_assert(identical(nrow(opportunities),
                               as.integer(qc$source_rows$collection_field_rows)),
                     "%s field-first opportunity rows do not reconcile to source", site)
  inv_release_assert(identical(sum(as.integer(qc$status_counts$n)),
                               nrow(opportunities)),
                     "%s record-status rows do not reconcile", site)
  inv_release_assert(isTRUE(qc$reconciliation$opportunity_complete) &&
                       isTRUE(qc$reconciliation$count_contains_density),
                     "%s QC reconciliation flags are not closed", site)
  inv_release_assert(
    identical(as.integer(qc$reconciliation$unstratifiable),
              sum(opportunities$unstratifiable)),
    "%s QC unstratifiable count does not reconcile", site
  )
  inv_release_assert(is.list(qc$source_quality) &&
                       identical(names(qc$source_quality),
                                 c("field", "per_sample",
                                   "taxonomy_processed")),
                     "%s source-QC tables are incomplete", site)
  for (table_name in names(INV_RELEASE_QC_FIELDS)) {
    table <- qc$source_quality[[table_name]]
    identity <- switch(
      table_name,
      field = INV_RELEASE_FIELD_QC_IDENTITY,
      per_sample = INV_RELEASE_PER_SAMPLE_QC_IDENTITY,
      taxonomy_processed = INV_RELEASE_TAXONOMY_QC_IDENTITY
    )
    inv_release_require_columns(
      table, paste(site, table_name, "QC"),
      c(identity, INV_RELEASE_QC_FIELDS[[table_name]])
    )
    inv_release_assert(all(as.character(table$siteID) == site),
                       "%s %s QC rows cross sites", site, table_name)
  }
  expected_qc_rows <- c(
    field = as.integer(qc$source_rows$field_qc_rows),
    per_sample = as.integer(qc$source_rows$per_sample_qc_rows),
    taxonomy_processed = as.integer(qc$source_rows$taxonomy_qc_rows),
    issue_log = as.integer(qc$source_rows$issue_log_rows)
  )
  actual_qc_rows <- c(
    field = nrow(qc$source_quality$field),
    per_sample = nrow(qc$source_quality$per_sample),
    taxonomy_processed = nrow(qc$source_quality$taxonomy_processed),
    issue_log = nrow(qc$issue_log)
  )
  inv_release_assert(identical(actual_qc_rows, expected_qc_rows) &&
                       identical(
                         as.integer(qc$reconciliation$source_qc_rows_retained),
                         unname(expected_qc_rows)
                       ),
                     "%s source-QC rows were not retained verbatim", site)
  inv_release_require_columns(
    qc$issue_log, paste(site, "issue log"),
    c(INV_RELEASE_ISSUE_FIELDS, INV_RELEASE_ISSUE_ANNOTATIONS)
  )
  inv_release_assert(
    !nrow(qc$issue_log) ||
      (all(as.character(qc$issue_log$bundle_site) == site) &&
         all(qc$issue_log$annotation_only)),
    "%s issue-log applicability annotations are invalid", site
  )
  inv_release_assert(
    identical(qc$reconciliation$qc_alters_metric_eligibility, FALSE),
    "%s QC evidence changes metric eligibility", site
  )

  events <- bundle$event_strata
  inv_release_assert(identical(names(events), INV_RELEASE_EVENT_COLUMNS),
                     "%s event-strata columns differ from the exact schema", site)
  inv_release_require_columns(events, paste(site, "event strata"), c(
    "stratum_key", "siteID", "eventID", "aquaticSiteType", "habitatType",
    "samplerType", "n_opportunities", "n_count_samples",
    "n_composition_samples", "n_density_samples", "n_reported_zero_count"
  ))
  if (nrow(events)) {
    inv_release_assert(all(as.character(events$siteID) == site) &&
                         !anyDuplicated(events$stratum_key),
                       "%s event strata cross sites or duplicate exact grain", site)
  }
  primary <- opportunities[opportunities$primary_stratum, , drop = FALSE]
  composition <- primary$count_eligible &
    is.finite(primary$total_estimated_count) & primary$total_estimated_count > 0
  inv_release_assert(identical(sum(events$n_opportunities), nrow(primary)),
                     "%s event opportunities do not reconcile", site)
  inv_release_assert(identical(sum(events$n_count_samples),
                               sum(primary$count_eligible)),
                     "%s event count denominator does not reconcile", site)
  inv_release_assert(identical(sum(events$n_composition_samples), sum(composition)),
                     "%s event composition denominator does not reconcile", site)
  inv_release_assert(identical(sum(events$n_density_samples),
                               sum(primary$density_eligible)),
                     "%s event density denominator does not reconcile", site)
  inv_release_assert(identical(sum(events$n_reported_zero_count),
                               sum(primary$reported_zero_count)),
                     "%s event reported-zero count does not reconcile", site)

  taxa <- bundle$taxon_strata
  inv_release_assert(identical(names(taxa), INV_RELEASE_TAXON_COLUMNS),
                     "%s taxon-strata columns differ from the exact schema", site)
  inv_release_require_columns(taxa, paste(site, "taxon strata"), c(
    "stratum_key", "siteID", "eventID", "aquaticSiteType", "habitatType",
    "samplerType", "taxon_key", "acceptedTaxonID", "scientificName",
    "taxonRank", "order", "family", "class", "subclass", "is_ept",
    "order_classified", "n_count_eligible_samples",
    "n_density_eligible_samples", "n_samples_present", "support_pct",
    "mean_sample_density_m2", "median_sample_density_m2",
    "total_estimated_count"
  ))
  if (nrow(taxa)) {
    taxon_key <- paste(taxa$stratum_key, taxa$taxon_key, sep = "\u241d")
    inv_release_assert(all(as.character(taxa$siteID) == site) &&
                         !anyDuplicated(taxon_key),
                       "%s taxon strata cross sites or duplicate exact grain", site)
    inv_release_assert(all(taxa$stratum_key %in% events$stratum_key),
                       "%s taxon row has no exact event stratum", site)
    inv_release_assert(all(taxa$n_count_eligible_samples > 0L) &&
                         all(taxa$n_density_eligible_samples <=
                               taxa$n_count_eligible_samples) &&
                         all(taxa$n_samples_present <=
                               taxa$n_count_eligible_samples),
                       "%s taxon support denominators are invalid", site)
    expected_support <- 100 * taxa$n_samples_present /
      taxa$n_count_eligible_samples
    inv_release_assert(all(abs(taxa$support_pct - expected_support) <= 1e-10),
                       "%s taxon support percentages do not reconcile", site)
  }

  summary <- bundle$site_summary
  inv_release_assert(identical(names(summary),
                               INV_RELEASE_SITE_SUMMARY_COLUMNS),
                     "%s site-summary columns differ from the exact schema", site)
  inv_release_require_columns(summary, paste(site, "site summary"), c(
    "siteID", "collectDate_min", "collectDate_max", "n_events", "n_strata",
    "n_opportunities", "n_count_samples", "n_density_samples",
    "n_unstratifiable", "n_taxa_recorded", "taxonomic_ranks"
  ))
  inv_release_assert(nrow(summary) == 1L &&
                       identical(as.character(summary$siteID), site),
                     "%s site summary is not one site-exact row", site)
  inv_release_assert(identical(as.integer(bundle$meta$n_opportunities),
                               nrow(opportunities)) &&
                       identical(as.integer(bundle$meta$n_count_samples),
                                 sum(opportunities$count_eligible)) &&
                       identical(as.integer(bundle$meta$n_density_samples),
                                 sum(opportunities$density_eligible)),
                     "%s meta denominators do not reconcile", site)
  inv_release_assert(
    identical(as.integer(bundle$meta$n_unstratifiable),
              sum(opportunities$unstratifiable)) &&
      identical(as.integer(summary$n_unstratifiable),
                as.integer(bundle$meta$n_unstratifiable)),
    "%s unstratifiable support count does not reconcile", site
  )

  unsafe <- grep("chao|raref|health_score", inv_release_recursive_names(bundle),
                 ignore.case = TRUE, value = TRUE)
  inv_release_assert(!length(unsafe), "%s exposes prohibited field(s): %s",
                     site, paste(unsafe, collapse = ", "))
  inv_release_reconcile_bundle(bundle, site)
  invisible(TRUE)
}

inv_release_expected_site_index <- function(bundles) {
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
      site = site, aquaticSiteType = as.character(meta$aquaticSiteType),
      lat = inv_release_num(meta$lat), lng = inv_release_num(meta$lng),
      elevation = inv_release_num(meta$elevation),
      collectDate_min = as.character(meta$collectDate_min),
      collectDate_max = as.character(meta$collectDate_max),
      n_events = as.integer(meta$n_events), n_strata = as.integer(meta$n_strata),
      n_opportunities = as.integer(meta$n_opportunities),
      n_primary_opportunities = as.integer(meta$n_primary_opportunities),
      n_count_samples = as.integer(meta$n_count_samples),
      n_composition_samples = as.integer(meta$n_composition_samples),
      n_density_samples = as.integer(meta$n_density_samples),
      n_reported_zero_count = as.integer(meta$n_reported_zero_count),
      n_unstratifiable = as.integer(meta$n_unstratifiable),
      n_taxa_recorded = as.integer(meta$n_taxa_recorded),
      n_sampling_impractical = sum(!opportunities$sampling_practical),
      n_nonstandard_collection = sum(opportunities$nonstandard_collection),
      n_processed_no_taxonomy = status_count("processed_no_taxonomy"),
      n_count_unavailable = status_count("count_unavailable"),
      n_area_unavailable = status_count("area_unavailable"),
      n_density_unavailable = status_count("density_unavailable"),
      taxonomic_ranks = as.character(meta$taxonomic_ranks),
      source_stamp = as.character(meta$source_stamp),
      science_version = as.character(bundle$provenance$science_version),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out <- out[order(out$site), INV_RELEASE_SITE_INDEX_COLUMNS, drop = FALSE]
  rownames(out) <- NULL
  out
}

inv_release_expected_search_taxa <- function(bundles) {
  rows <- lapply(bundles, function(bundle) {
    bundle$taxon_strata[INV_RELEASE_SEARCH_TAXON_COLUMNS]
  })
  out <- do.call(rbind, rows)
  if (!nrow(out)) {
    rownames(out) <- NULL
    return(out)
  }
  out <- out[order(out$scientificName, out$siteID, out$eventID,
                   out$aquaticSiteType, out$habitatType, out$samplerType,
                   out$taxon_key), , drop = FALSE]
  rownames(out) <- NULL
  out
}

inv_release_expected_science_summary <- function(bundles) {
  opportunities <- do.call(rbind, lapply(bundles, `[[`, "opportunities"))
  rownames(opportunities) <- NULL
  status <- table(factor(opportunities$record_status,
                         levels = INV_RELEASE_STATUS_LEVELS))
  primary <- opportunities[opportunities$primary_stratum, , drop = FALSE]
  list(
    opportunities = nrow(opportunities),
    primary_opportunities = sum(opportunities$primary_stratum),
    count_eligible_samples = sum(opportunities$count_eligible),
    density_eligible_samples = sum(opportunities$density_eligible),
    sites = length(unique(as.character(opportunities$siteID))),
    events = length(unique(paste(primary$siteID, primary$eventID,
                                 sep = "\u241f"))),
    strata = sum(vapply(bundles, function(bundle) nrow(bundle$event_strata),
                        integer(1))),
    taxonomy_rows_collapsed = sum(opportunities$taxonomy_rows),
    excluded_metabarcoding_rows = sum(vapply(bundles, function(bundle) {
      as.integer(bundle$qc$source_rows$metabarcode_field_rows)
    }, integer(1))),
    status_counts = stats::setNames(as.integer(status), names(status))
  )
}

inv_release_compare_named_list <- function(actual, expected, label) {
  inv_release_assert(identical(names(actual), names(expected)),
                     "%s members differ from the exact schema", label)
  for (field in names(expected)) {
    if (is.list(expected[[field]]) && !is.data.frame(expected[[field]])) {
      inv_release_compare_named_list(actual[[field]], expected[[field]],
                                     paste(label, field))
    } else {
      inv_release_assert(
        inv_release_vector_equal(actual[[field]], expected[[field]]),
        "%s field %s differs from independently recomputed release data",
        label, field
      )
    }
  }
  invisible(TRUE)
}

inv_verify_release_data <- function(root = ".") {
  contract_path <- file.path(root, "data", "release_contract.rds")
  receipt_path <- file.path(root, "data", "source_receipt.json")
  inv_release_assert(file.exists(contract_path),
                     "Missing data/release_contract.rds")
  inv_release_assert(file.exists(receipt_path), "Missing data/source_receipt.json")
  contract <- readRDS(contract_path)
  inv_release_assert(identical(as.character(contract$schema_version), "1.0.0"),
                     "Release contract schema is not 1.0.0")
  inv_release_assert(identical(as.character(contract$site_ids),
                               INV_RELEASE_EXPECTED_SITES),
                     "Release contract site roster is not canonical")
  inv_release_assert(isTRUE(contract$support_index_only),
                     "Release contract does not require a support-only index")
  inv_release_assert(is.list(contract$qc_contract) &&
                       isTRUE(contract$qc_contract$retain_verbatim) &&
                       identical(contract$qc_contract$automatic_exclusion,
                                 FALSE) &&
                       identical(contract$qc_contract$table_fields,
                                 list(
                                   inv_fieldData = INV_RELEASE_QC_FIELDS$field,
                                   inv_persample = INV_RELEASE_QC_FIELDS$per_sample,
                                   inv_taxonomyProcessed =
                                     INV_RELEASE_QC_FIELDS$taxonomy_processed
                                 )) &&
                       identical(as.character(
                         contract$qc_contract$issue_log_fields
                       ), INV_RELEASE_ISSUE_FIELDS),
                     "Release contract does not pin the official vF QC schema")
  inv_release_assert(identical(inv_release_sha256(receipt_path),
                               as.character(contract$source$receipt_sha256)),
                     "Published source receipt hash differs from release contract")

  inv_release_assert(requireNamespace("jsonlite", quietly = TRUE),
                     "jsonlite is required for source receipt verification")
  receipt <- jsonlite::fromJSON(receipt_path, simplifyVector = TRUE,
                                simplifyDataFrame = FALSE,
                                simplifyMatrix = FALSE)
  inv_release_assert(
    identical(as.character(receipt$receipt_schema_version), "1.1.0") &&
      identical(as.character(contract$source$receipt_schema_version),
                "1.1.0") &&
      identical(as.character(receipt$source_request$dpid), "DP1.20120.001") &&
      identical(as.character(receipt$source_request$release), "RELEASE-2026") &&
      identical(isTRUE(receipt$source_request$include_provisional), FALSE) &&
      inv_release_valid_git_sha(receipt$producer$git_sha) &&
      identical(as.character(receipt$producer$git_sha),
                as.character(contract$source$producer_git_sha)) &&
      identical(as.character(receipt$artifact$sha256),
                as.character(contract$source$artifact_sha256)),
    "Published source receipt is not the exact non-provisional RELEASE-2026 source"
  )
  inv_release_assert(identical(names(receipt$relations), c(
    "practical_field_rows", "impractical_field_rows",
    "processed_without_taxonomy"
  )), "Published source receipt uses an obsolete or inexact relation schema")
  receipt_measurement <- receipt$measurement_metadata
  inv_release_assert(is.list(receipt_measurement) &&
                       length(receipt_measurement) ==
                         nrow(INV_RELEASE_MEASUREMENT_METADATA),
                     "Published source receipt lacks measurement metadata")
  receipt_measurement <- data.frame(
    table = vapply(receipt_measurement, function(row) {
      as.character(row$table)
    }, character(1)),
    fieldName = vapply(receipt_measurement, function(row) {
      as.character(row$fieldName)
    }, character(1)),
    description = vapply(receipt_measurement, function(row) {
      as.character(row$description)
    }, character(1)),
    dataType = vapply(receipt_measurement, function(row) {
      as.character(row$dataType)
    }, character(1)),
    units = vapply(receipt_measurement, function(row) {
      as.character(row$units)
    }, character(1)),
    stringsAsFactors = FALSE
  )
  inv_release_assert_frame_equal(
    receipt_measurement, INV_RELEASE_MEASUREMENT_METADATA,
    "published receipt measurement metadata"
  )

  bundle_paths <- file.path(root, "data", "sites",
                            paste0(INV_RELEASE_EXPECTED_SITES, ".rds"))
  actual_files <- sort(list.files(file.path(root, "data", "sites"),
                                  pattern = "^[A-Z0-9]{4}[.]rds$"))
  inv_release_assert(identical(actual_files,
                               paste0(INV_RELEASE_EXPECTED_SITES, ".rds")),
                     "Published site-bundle inventory is not the exact roster")
  bundles <- stats::setNames(vector("list", length(bundle_paths)),
                             INV_RELEASE_EXPECTED_SITES)
  for (site in INV_RELEASE_EXPECTED_SITES) {
    path <- file.path(root, "data", "sites", paste0(site, ".rds"))
    inv_release_assert(identical(inv_release_sha256(path),
                                 as.character(contract$bundle_sha256[[site]])),
                       "%s bundle hash differs from release contract", site)
    bundle <- readRDS(path)
    inv_release_verify_bundle(bundle, site, contract)
    bundles[[site]] <- bundle
  }
  inv_release_assert(identical(as.character(contract$bundle_members),
                               INV_RELEASE_BUNDLE_MEMBERS),
                     "Release contract bundle-member schema is not exact")
  inv_release_compare_named_list(
    contract$science_summary, inv_release_expected_science_summary(bundles),
    "release science summary"
  )
  source_table_rows <- c(
    inv_fieldData = sum(vapply(bundles, function(bundle) {
      as.integer(bundle$qc$source_rows$field_qc_rows)
    }, integer(1))),
    inv_persample = sum(vapply(bundles, function(bundle) {
      as.integer(bundle$qc$source_rows$per_sample_rows)
    }, integer(1))),
    inv_taxonomyProcessed = sum(vapply(bundles, function(bundle) {
      as.integer(bundle$qc$source_rows$taxonomy_processed_rows)
    }, integer(1)))
  )
  inv_release_assert(
    inv_release_vector_equal(contract$source$table_rows[names(source_table_rows)],
                             source_table_rows),
    "Release source table-row totals do not reconcile across site bundles"
  )
  issue_reference <- bundles[[1L]]$qc$issue_log[
    INV_RELEASE_ISSUE_FIELDS
  ]
  for (site in INV_RELEASE_EXPECTED_SITES[-1L]) {
    inv_release_assert(
      identical(bundles[[site]]$qc$issue_log[INV_RELEASE_ISSUE_FIELDS],
                issue_reference),
      "%s does not retain the same verbatim global issue log", site
    )
  }

  site_index <- readRDS(file.path(root, "data", "site_index.rds"))
  cross_site <- readRDS(file.path(root, "data", "cross_site.rds"))
  inv_release_assert(identical(names(site_index), INV_RELEASE_SITE_INDEX_COLUMNS),
                     "Site-index columns differ from the exact support schema")
  expected_site_index <- inv_release_expected_site_index(bundles)
  inv_release_assert_frame_equal(site_index, expected_site_index, "site index")
  inv_release_assert_frame_equal(cross_site, expected_site_index,
                                 "cross-site index")
  prohibited <- as.character(contract$prohibited_cross_site_fields)
  inv_release_assert(!length(intersect(prohibited, names(site_index))),
                     "Support-only site index exposes prohibited cross-site fields: %s",
                     paste(intersect(prohibited, names(site_index)), collapse = ", "))
  search <- readRDS(file.path(root, "data", "search_index.rds"))
  inv_release_assert(is.list(search) && identical(names(search), c(
    "schema_version", "taxa", "sites", "metric_contract", "source", "built",
    "boundary"
  )), "Search index differs from the exact schema")
  inv_release_assert_frame_equal(search$sites, expected_site_index,
                                 "search site index")
  inv_release_assert(identical(search$metric_contract, contract$metric_contract),
                     "Search metric contract differs from release contract")
  inv_release_assert(identical(search$source, contract$source),
                     "Search source provenance differs from release contract")
  inv_release_assert(identical(as.character(search$schema_version),
                               as.character(contract$producer_schema_version)) &&
                       identical(as.character(search$built),
                                 as.character(contract$source$publication_date_max)),
                     "Search schema/stamp differs from the release contract")
  expected_search_taxa <- inv_release_expected_search_taxa(bundles)
  inv_release_assert_frame_equal(search$taxa, expected_search_taxa,
                                 "search taxon index")
  search_unsafe <- grep("density|chao|raref|health", names(search$taxa),
                        ignore.case = TRUE, value = TRUE)
  inv_release_assert(!length(search_unsafe),
                     "Search index exposes prohibited cross-site field(s): %s",
                     paste(search_unsafe, collapse = ", "))
  demo <- readRDS(file.path(root, "data-sample", "demo.rds"))
  inv_release_assert(identical(demo, bundles$SYCA),
                     "Demo bundle is not the exact SYCA bundle")

  list(
    sites = length(bundles),
    opportunities = sum(site_index$n_opportunities),
    count_samples = sum(site_index$n_count_samples),
    density_samples = sum(site_index$n_density_samples),
    unstratifiable = sum(site_index$n_unstratifiable),
    taxon_search_rows = nrow(search$taxa),
    source_stamp = unique(site_index$source_stamp),
    artifact_sha256 = as.character(contract$source$artifact_sha256)
  )
}

inv_release_raw_opportunity_id <- function(field) {
  sample_key <- inv_release_pair_key(field$sampleID, field$sampleCode)
  has_sample <- !inv_release_blank(field$sampleID) &
    !inv_release_blank(field$sampleCode)
  field_key <- apply(data.frame(
    namedLocation = inv_release_chr(field$namedLocation),
    eventID = inv_release_chr(field$eventID),
    sampleID = inv_release_chr(field$sampleID),
    sampleCode = inv_release_chr(field$sampleCode),
    habitatType = inv_release_chr(field$habitatType),
    samplerType = inv_release_chr(field$samplerType),
    sampleNumber = inv_release_chr(field$sampleNumber),
    stringsAsFactors = FALSE
  ), 1L, paste, collapse = "\u241c")
  ifelse(has_sample, paste0("sample:", sample_key), paste0("field:", field_key))
}

inv_release_strict_value <- function(x, label) {
  values <- unique(trimws(as.character(x[!inv_release_blank(x)])))
  inv_release_assert(length(values) <= 1L,
                     "Raw source has conflicting %s values: %s", label,
                     paste(values, collapse = ", "))
  if (length(values)) values[[1]] else NA_character_
}

inv_release_raw_count_values <- function(taxonomy) {
  estimated <- inv_release_num(taxonomy$estimatedTotalCount)
  individual <- inv_release_num(taxonomy$individualCount)
  subsample <- inv_release_num(taxonomy$subsamplePercent)
  issue <- rep(NA_character_, length(estimated))
  value <- estimated
  issue[is.infinite(estimated) | is.nan(estimated)] <-
    "nonfinite_estimated_count"
  issue[is.infinite(individual) | is.nan(individual)] <-
    "nonfinite_individual_count"
  issue[is.infinite(subsample) | is.nan(subsample) |
          (is.finite(subsample) & (subsample <= 0 | subsample > 100))] <-
    "invalid_subsample_percent"
  issue[is.finite(estimated) & estimated < 0] <- "negative_estimated_count"
  issue[is.finite(individual) & individual < 0] <- "negative_individual_count"
  contradiction <- is.finite(estimated) & is.finite(individual) &
    estimated + sqrt(.Machine$double.eps) < individual
  issue[contradiction] <- "estimated_below_individual_count"
  issue[!is.finite(value) & is.na(issue)] <- "estimated_count_unavailable"
  value[!is.na(issue)] <- NA_real_
  list(value = value, issue = issue)
}

inv_release_raw_collapsed_taxonomy <- function(taxonomy) {
  if (!nrow(taxonomy)) {
    return(data.frame(
      sample_key = character(), taxon_key = character(),
      acceptedTaxonID = character(), scientificName = character(),
      taxonRank = character(), order = character(), family = character(),
      class = character(), subclass = character(), estimated_count = numeric(),
      count_valid = logical(), order_classified = logical(), is_ept = logical(),
      stringsAsFactors = FALSE
    ))
  }
  count <- inv_release_raw_count_values(taxonomy)
  sample_key <- inv_release_pair_key(taxonomy$sampleID, taxonomy$sampleCode)
  taxon_key <- trimws(as.character(taxonomy$acceptedTaxonID))
  inv_release_assert(!any(inv_release_blank(taxon_key)),
                     "Raw taxonomy has a blank acceptedTaxonID")
  group_key <- paste(sample_key, taxon_key, sep = "\u241d")
  groups <- split(seq_len(nrow(taxonomy)), group_key, drop = TRUE)
  rows <- lapply(groups, function(index) {
    issues <- unique(count$issue[index][!is.na(count$issue[index])])
    valid <- !length(issues)
    value <- if (valid) sum(count$value[index]) else NA_real_
    if (valid && !is.finite(value)) valid <- FALSE
    order_value <- inv_release_strict_value(taxonomy$order[index], "order")
    data.frame(
      sample_key = sample_key[index[[1]]], taxon_key = taxon_key[index[[1]]],
      acceptedTaxonID = inv_release_strict_value(
        taxonomy$acceptedTaxonID[index], "acceptedTaxonID"
      ),
      scientificName = inv_release_strict_value(
        taxonomy$scientificName[index], "scientificName"
      ),
      taxonRank = inv_release_strict_value(taxonomy$taxonRank[index], "taxonRank"),
      order = order_value,
      family = inv_release_strict_value(taxonomy$family[index], "family"),
      class = inv_release_strict_value(taxonomy$class[index], "class"),
      subclass = inv_release_strict_value(taxonomy$subclass[index], "subclass"),
      estimated_count = if (valid) value else NA_real_, count_valid = valid,
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

inv_release_raw_canonical_taxa <- function(collapsed) {
  if (!nrow(collapsed)) return(collapsed[FALSE, c(
    "taxon_key", "acceptedTaxonID", "scientificName", "taxonRank", "order",
    "family", "class", "subclass", "order_classified", "is_ept"
  ), drop = FALSE])
  groups <- split(seq_len(nrow(collapsed)), collapsed$taxon_key, drop = TRUE)
  rows <- lapply(names(groups), function(key) {
    index <- groups[[key]]
    order_value <- inv_release_strict_value(collapsed$order[index],
                                            paste("order for", key))
    data.frame(
      taxon_key = key,
      acceptedTaxonID = inv_release_strict_value(
        collapsed$acceptedTaxonID[index], paste("acceptedTaxonID for", key)
      ),
      scientificName = inv_release_strict_value(
        collapsed$scientificName[index], paste("scientificName for", key)
      ),
      taxonRank = inv_release_strict_value(
        collapsed$taxonRank[index], paste("taxonRank for", key)
      ),
      order = order_value,
      family = inv_release_strict_value(collapsed$family[index],
                                        paste("family for", key)),
      class = inv_release_strict_value(collapsed$class[index],
                                       paste("class for", key)),
      subclass = inv_release_strict_value(collapsed$subclass[index],
                                          paste("subclass for", key)),
      order_classified = !is.na(order_value),
      is_ept = !is.na(order_value) && tolower(order_value) %in%
        tolower(c("Ephemeroptera", "Plecoptera", "Trichoptera")),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out <- out[order(out$taxon_key), , drop = FALSE]
  rownames(out) <- NULL
  out
}

inv_release_expected_raw_taxa <- function(collapsed, opportunities) {
  count_opportunities <- opportunities[
    opportunities$primary_stratum & opportunities$count_eligible, , drop = FALSE
  ]
  if (!nrow(count_opportunities) || !nrow(collapsed)) {
    return(data.frame(
      stratum_key = character(), siteID = character(), eventID = character(),
      aquaticSiteType = character(), habitatType = character(),
      samplerType = character(), taxon_key = character(),
      acceptedTaxonID = character(), scientificName = character(),
      taxonRank = character(), order = character(), family = character(),
      class = character(), subclass = character(), is_ept = logical(),
      order_classified = logical(), n_count_eligible_samples = integer(),
      n_density_eligible_samples = integer(), n_samples_present = integer(),
      support_pct = numeric(), mean_sample_density_m2 = numeric(),
      median_sample_density_m2 = numeric(), total_estimated_count = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  metadata <- inv_release_raw_canonical_taxa(collapsed)
  rows <- list()
  cursor <- 0L
  groups <- split(seq_len(nrow(count_opportunities)),
                  count_opportunities$stratum_key, drop = TRUE)
  for (stratum in names(groups)) {
    samples <- count_opportunities[groups[[stratum]], , drop = FALSE]
    part <- collapsed[
      collapsed$sample_key %in% samples$sample_key & collapsed$count_valid,
      , drop = FALSE
    ]
    taxa <- unique(as.character(part$taxon_key[
      is.finite(part$estimated_count) & part$estimated_count > 0
    ]))
    for (taxon in taxa) {
      taxon_part <- part[part$taxon_key == taxon, , drop = FALSE]
      counts <- stats::setNames(rep(0, nrow(samples)), samples$sample_key)
      observed <- tapply(taxon_part$estimated_count,
                         taxon_part$sample_key, sum)
      counts[names(observed)] <- observed
      density_samples <- samples[samples$density_eligible, , drop = FALSE]
      density <- numeric()
      if (nrow(density_samples)) {
        density <- counts[density_samples$sample_key] /
          stats::setNames(density_samples$benthicArea_m2,
                          density_samples$sample_key)
      }
      meta <- metadata[metadata$taxon_key == taxon, , drop = FALSE]
      inv_release_assert(nrow(meta) == 1L,
                         "Raw canonical metadata is unavailable for %s", taxon)
      cursor <- cursor + 1L
      rows[[cursor]] <- data.frame(
        stratum_key = stratum, siteID = samples$siteID[[1]],
        eventID = samples$eventID[[1]],
        aquaticSiteType = samples$aquaticSiteType[[1]],
        habitatType = samples$habitatType[[1]],
        samplerType = samples$samplerType[[1]], taxon_key = taxon,
        acceptedTaxonID = meta$acceptedTaxonID,
        scientificName = meta$scientificName, taxonRank = meta$taxonRank,
        order = meta$order, family = meta$family, class = meta$class,
        subclass = meta$subclass, is_ept = meta$is_ept,
        order_classified = meta$order_classified,
        n_count_eligible_samples = nrow(samples),
        n_density_eligible_samples = nrow(density_samples),
        n_samples_present = sum(counts > 0),
        support_pct = 100 * sum(counts > 0) / nrow(samples),
        mean_sample_density_m2 = inv_release_mean(density),
        median_sample_density_m2 = inv_release_median(density),
        total_estimated_count = sum(counts), stringsAsFactors = FALSE
      )
    }
  }
  if (!length(rows)) {
    return(inv_release_expected_raw_taxa(collapsed[FALSE, , drop = FALSE],
                                         opportunities[FALSE, , drop = FALSE]))
  }
  out <- do.call(rbind, rows)
  out <- out[order(out$siteID, out$eventID, out$aquaticSiteType,
                   out$habitatType, out$samplerType,
                   -out$mean_sample_density_m2, out$taxon_key),
             INV_RELEASE_TAXON_COLUMNS, drop = FALSE]
  rownames(out) <- NULL
  out
}

inv_release_raw_opportunity_projection <- function(field) {
  data.frame(
    opportunity_id = inv_release_raw_opportunity_id(field),
    sample_key = inv_release_pair_key(field$sampleID, field$sampleCode),
    sampleID = as.character(field$sampleID),
    sampleCode = as.character(field$sampleCode),
    siteID = inv_release_chr(field$siteID),
    eventID = inv_release_chr(field$eventID),
    collectDate = as.character(field$collectDate),
    aquaticSiteType = inv_release_chr(field$aquaticSiteType),
    habitatType = inv_release_chr(field$habitatType),
    samplerType = inv_release_chr(field$samplerType),
    namedLocation = as.character(field$namedLocation),
    sampleNumber = as.character(field$sampleNumber),
    samplingImpractical = as.character(field$samplingImpractical),
    benthicArea_m2 = inv_release_num(field$benthicArea),
    stringsAsFactors = FALSE
  )
}

inv_verify_release_against_source <- function(root, artifact_path,
                                              source_receipt_path) {
  inv_verify_release_data(root)
  inv_release_assert(file.exists(artifact_path),
                     "Raw source artifact is missing: %s", artifact_path)
  inv_release_assert(file.exists(source_receipt_path),
                     "Raw source receipt is missing: %s", source_receipt_path)
  contract <- readRDS(file.path(root, "data", "release_contract.rds"))
  published_receipt <- file.path(root, "data", "source_receipt.json")
  inv_release_assert(
    identical(inv_release_sha256(source_receipt_path),
              inv_release_sha256(published_receipt)),
    "Downloaded and published source receipts are not byte-identical"
  )
  receipt <- jsonlite::fromJSON(source_receipt_path, simplifyVector = TRUE,
                                simplifyDataFrame = FALSE,
                                simplifyMatrix = FALSE)
  raw_sha <- inv_release_sha256(artifact_path)
  inv_release_assert(
    identical(raw_sha, as.character(receipt$artifact$sha256)) &&
      identical(raw_sha, as.character(contract$source$artifact_sha256)),
    "Raw source hash differs from its receipt or release contract"
  )
  source <- readRDS(artifact_path)
  required <- c("inv_fieldData", "inv_persample", "inv_taxonomyProcessed",
                "issueLog_20120", "variables_20120")
  inv_release_assert(is.list(source) && all(required %in% names(source)),
                     "Raw source lacks a required RELEASE-2026 table")
  for (table_name in required) {
    inv_release_assert(is.data.frame(source[[table_name]]),
                       "Raw source object %s is not a data frame", table_name)
  }
  variables <- source$variables_20120
  inv_release_require_columns(
    variables, "raw variables_20120",
    c("table", "fieldName", "description", "dataType", "units")
  )
  variable_key <- paste(as.character(variables$table),
                        as.character(variables$fieldName), sep = "\u241f")
  inv_release_assert(!anyDuplicated(variable_key),
                     "Raw variables_20120 has duplicate field identities")
  qc_tables <- c(
    field = "inv_fieldData", per_sample = "inv_persample",
    taxonomy_processed = "inv_taxonomyProcessed"
  )
  for (qc_name in names(INV_RELEASE_QC_FIELDS)) {
    table_name <- unname(qc_tables[[qc_name]])
    fields <- as.character(variables$fieldName[
      as.character(variables$table) == table_name &
        (as.character(variables$fieldName) == "dataQF" |
           grepl("^qc", as.character(variables$fieldName)))
    ])
    inv_release_assert(
      identical(sort(fields), sort(INV_RELEASE_QC_FIELDS[[qc_name]])),
      "Raw variables_20120 QC fields differ for %s", table_name
    )
  }
  measurement_key <- paste(INV_RELEASE_MEASUREMENT_METADATA$table,
                           INV_RELEASE_MEASUREMENT_METADATA$fieldName,
                           sep = "\u241f")
  index <- match(measurement_key, variable_key)
  inv_release_assert(!anyNA(index),
                     "Raw variables_20120 lacks measurement metadata")
  measurement <- data.frame(
    table = as.character(variables$table[index]),
    fieldName = as.character(variables$fieldName[index]),
    description = as.character(variables$description[index]),
    dataType = as.character(variables$dataType[index]),
    units = as.character(variables$units[index]),
    stringsAsFactors = FALSE
  )
  inv_release_assert_frame_equal(
    measurement, INV_RELEASE_MEASUREMENT_METADATA,
    "raw release-locked measurement metadata"
  )
  inv_release_assert(
    identical(nrow(variables), as.integer(
      receipt$required_metadata$variables_20120$row_count
    )),
    "Raw variables_20120 row count differs from the source receipt"
  )
  for (table_name in c("inv_fieldData", "inv_persample",
                       "inv_taxonomyProcessed")) {
    table <- source[[table_name]]
    inv_release_assert(all(as.character(table$release) == "RELEASE-2026"),
                       "Raw %s contains a non-RELEASE-2026 row", table_name)
    receipt_rows <- as.integer(receipt$required_tables[[table_name]]$row_count)
    inv_release_assert(identical(nrow(table), receipt_rows),
                       "Raw %s row count differs from the source receipt",
                       table_name)
  }

  field <- source$inv_fieldData
  sample_id <- trimws(as.character(field$sampleID))
  dna_any_case <- !inv_release_blank(sample_id) &
    grepl("^.+[.]DNA$", sample_id, ignore.case = TRUE)
  dna <- !inv_release_blank(sample_id) & grepl("^.+[.]DNA$", sample_id)
  inv_release_assert(!any(dna_any_case & !dna),
                     "Raw field source has a noncanonical .DNA suffix")
  collection <- field[!dna, , drop = FALSE]
  inv_release_assert(identical(sort(unique(as.character(collection$siteID))),
                               INV_RELEASE_EXPECTED_SITES),
                     "Raw collection field roster is not the canonical 34 sites")
  inv_release_assert(!any(grepl("[.]DNA$", source$inv_persample$sampleID,
                                ignore.case = TRUE)) &&
                       !any(grepl("[.]DNA$",
                                  source$inv_taxonomyProcessed$sampleID,
                                  ignore.case = TRUE)),
                     "Raw child tables contain metabarcoding sample rows")

  bundles <- stats::setNames(lapply(INV_RELEASE_EXPECTED_SITES, function(site) {
    readRDS(file.path(root, "data", "sites", paste0(site, ".rds")))
  }), INV_RELEASE_EXPECTED_SITES)
  opportunities <- do.call(rbind, lapply(bundles, `[[`, "opportunities"))
  rownames(opportunities) <- NULL
  expected_opportunities <- inv_release_raw_opportunity_projection(collection)
  actual_opportunities <- data.frame(
    opportunity_id = as.character(opportunities$opportunity_id),
    sample_key = as.character(opportunities$sample_key),
    sampleID = as.character(opportunities$sampleID),
    sampleCode = as.character(opportunities$sampleCode),
    siteID = as.character(opportunities$siteID),
    eventID = as.character(opportunities$eventID),
    collectDate = as.character(opportunities$collectDate),
    aquaticSiteType = as.character(opportunities$aquaticSiteType),
    habitatType = as.character(opportunities$habitatType),
    samplerType = as.character(opportunities$samplerType),
    namedLocation = as.character(opportunities$namedLocation),
    sampleNumber = as.character(opportunities$sampleNumber),
    samplingImpractical = as.character(opportunities$samplingImpractical),
    benthicArea_m2 = inv_release_num(opportunities$benthicArea_m2),
    stringsAsFactors = FALSE
  )
  expected_opportunities <- inv_release_sort_frame(
    expected_opportunities, "opportunity_id"
  )
  actual_opportunities <- inv_release_sort_frame(
    actual_opportunities, "opportunity_id"
  )
  inv_release_assert_frame_equal(actual_opportunities,
                                 expected_opportunities,
                                 "raw-to-bundle opportunity identity")

  pair_to_site <- stats::setNames(
    as.character(collection$siteID),
    inv_release_pair_key(collection$sampleID, collection$sampleCode)
  )
  per_sites <- unname(pair_to_site[inv_release_pair_key(
    source$inv_persample$sampleID, source$inv_persample$sampleCode
  )])
  tax_sites <- unname(pair_to_site[inv_release_pair_key(
    source$inv_taxonomyProcessed$sampleID,
    source$inv_taxonomyProcessed$sampleCode
  )])
  inv_release_assert(!anyNA(per_sites) && !anyNA(tax_sites),
                     "Raw child row lacks a collection-field site mapping")
  for (site in INV_RELEASE_EXPECTED_SITES) {
    bundle <- bundles[[site]]
    source_rows <- bundle$qc$source_rows
    raw_counts <- c(
      collection_field_rows = sum(as.character(collection$siteID) == site),
      metabarcode_field_rows = sum(as.character(field$siteID[dna]) == site),
      per_sample_rows = sum(per_sites == site),
      taxonomy_processed_rows = sum(tax_sites == site),
      field_qc_rows = sum(as.character(field$siteID) == site),
      per_sample_qc_rows = sum(per_sites == site),
      taxonomy_qc_rows = sum(tax_sites == site),
      issue_log_rows = nrow(source$issueLog_20120)
    )
    inv_release_assert(
      inv_release_vector_equal(unlist(source_rows[names(raw_counts)],
                                      use.names = FALSE), unname(raw_counts)),
      "%s source-row ledger differs from the raw artifact", site
    )
    expected_field_qc <- field[as.character(field$siteID) == site,
      c(INV_RELEASE_FIELD_QC_IDENTITY, INV_RELEASE_QC_FIELDS$field), drop = FALSE]
    expected_per_qc <- source$inv_persample[per_sites == site,
      c("sampleID", "sampleCode", INV_RELEASE_QC_FIELDS$per_sample), drop = FALSE]
    expected_per_qc <- data.frame(siteID = rep(site, nrow(expected_per_qc)),
                                  expected_per_qc, check.names = FALSE,
                                  stringsAsFactors = FALSE)
    tax_identity_without_site <- setdiff(INV_RELEASE_TAXONOMY_QC_IDENTITY,
                                         "siteID")
    expected_tax_qc <- source$inv_taxonomyProcessed[tax_sites == site,
      c(tax_identity_without_site,
        INV_RELEASE_QC_FIELDS$taxonomy_processed), drop = FALSE]
    expected_tax_qc <- data.frame(siteID = rep(site, nrow(expected_tax_qc)),
                                  expected_tax_qc, check.names = FALSE,
                                  stringsAsFactors = FALSE)
    inv_release_assert_frame_equal(bundle$qc$source_quality$field,
                                   expected_field_qc,
                                   paste(site, "raw field QC"))
    inv_release_assert_frame_equal(bundle$qc$source_quality$per_sample,
                                   expected_per_qc,
                                   paste(site, "raw per-sample QC"))
    inv_release_assert_frame_equal(
      bundle$qc$source_quality$taxonomy_processed, expected_tax_qc,
      paste(site, "raw taxonomy QC")
    )
    inv_release_assert_frame_equal(
      bundle$qc$issue_log[INV_RELEASE_ISSUE_FIELDS],
      source$issueLog_20120[INV_RELEASE_ISSUE_FIELDS],
      paste(site, "raw issue log")
    )
    site_field <- collection[as.character(collection$siteID) == site, , drop = FALSE]
    dates <- inv_release_date_range(site_field$collectDate)
    water_types <- sort(unique(inv_release_chr(site_field$aquaticSiteType)))
    inv_release_assert(
      inv_release_vector_equal(bundle$meta$collectDate_min, dates[[1]]) &&
        inv_release_vector_equal(bundle$meta$collectDate_max, dates[[2]]) &&
        identical(as.character(bundle$meta$aquatic_site_types), water_types) &&
        identical(as.character(bundle$meta$aquaticSiteType),
                  paste(water_types, collapse = " | ")) &&
        inv_release_vector_equal(bundle$meta$lat,
                                 inv_release_median(site_field$decimalLatitude)) &&
        inv_release_vector_equal(bundle$meta$lng,
                                 inv_release_median(site_field$decimalLongitude)) &&
        inv_release_vector_equal(bundle$meta$elevation,
                                 inv_release_median(site_field$elevation)) &&
        inv_release_vector_equal(
          bundle$meta$named_location_count,
          length(unique(inv_release_chr(site_field$namedLocation)))
        ),
      "%s context/date metadata differs from the raw field artifact", site
    )
  }

  collapsed <- inv_release_raw_collapsed_taxonomy(
    source$inv_taxonomyProcessed
  )
  collapsed_groups <- split(seq_len(nrow(collapsed)), collapsed$sample_key,
                            drop = TRUE)
  for (i in seq_len(nrow(opportunities))) {
    part_index <- collapsed_groups[[as.character(opportunities$sample_key[[i]])]]
    part <- if (is.null(part_index)) collapsed[FALSE, , drop = FALSE] else
      collapsed[part_index, , drop = FALSE]
    expected_rows <- nrow(part)
    expected_valid <- nrow(part) > 0L && all(part$count_valid)
    expected_total <- if (expected_valid) sum(part$estimated_count) else NA_real_
    expected_count_eligible <- isTRUE(opportunities$primary_stratum[[i]]) &&
      isTRUE(opportunities$sampling_practical[[i]]) && expected_valid
    positive <- expected_valid & is.finite(part$estimated_count) &
      part$estimated_count > 0
    expected_taxa <- if (expected_count_eligible) sum(positive) else NA_integer_
    expected_ept <- if (expected_count_eligible) sum(positive & part$is_ept) else
      NA_integer_
    inv_release_assert(
      identical(as.integer(opportunities$taxonomy_rows[[i]]), expected_rows) &&
        inv_release_vector_equal(opportunities$total_estimated_count[[i]],
                                 expected_total) &&
        identical(isTRUE(opportunities$count_eligible[[i]]),
                  expected_count_eligible) &&
        inv_release_vector_equal(opportunities$taxa_observed[[i]],
                                 expected_taxa) &&
        inv_release_vector_equal(opportunities$ept_taxa_observed[[i]],
                                 expected_ept),
      "Raw taxonomy does not reconcile to opportunity %s",
      as.character(opportunities$opportunity_id[[i]])
    )
  }
  expected_taxa <- inv_release_expected_raw_taxa(collapsed, opportunities)
  actual_taxa <- do.call(rbind, lapply(bundles, `[[`, "taxon_strata"))
  rownames(actual_taxa) <- NULL
  expected_taxa <- inv_release_sort_frame(
    expected_taxa,
    c("siteID", "eventID", "aquaticSiteType", "habitatType", "samplerType",
      "taxon_key")
  )
  actual_taxa <- inv_release_sort_frame(
    actual_taxa,
    c("siteID", "eventID", "aquaticSiteType", "habitatType", "samplerType",
      "taxon_key")
  )
  inv_release_assert_frame_equal(actual_taxa, expected_taxa,
                                 "raw-to-bundle taxon strata")

  publication_dates <- unlist(lapply(c(
    "inv_fieldData", "inv_persample", "inv_taxonomyProcessed"
  ), function(table_name) {
    suppressWarnings(as.Date(substr(
      as.character(source[[table_name]]$publicationDate), 1L, 10L
    )))
  }), use.names = FALSE)
  publication_dates <- as.Date(publication_dates, origin = "1970-01-01")
  publication_dates <- publication_dates[!is.na(publication_dates)]
  inv_release_assert(length(publication_dates) > 0L &&
                       identical(format(max(publication_dates), "%Y-%m-%d"),
                                 as.character(
                                   contract$source$publication_date_max
                                 )),
                     "Raw publication stamp differs from the release contract")
  invisible(list(
    artifact_sha256 = raw_sha, opportunities = nrow(opportunities),
    collapsed_taxa = nrow(collapsed), taxon_strata = nrow(actual_taxa)
  ))
}
