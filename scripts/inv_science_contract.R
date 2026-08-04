#!/usr/bin/env Rscript

# Pure scientific transform for NEON DP1.20120.001 (RELEASE-2026).
#
# The field table is the opportunity ledger. Taxonomy is an outcome attached to
# a practical, processed sample; it is never the starting population. Primary
# comparisons retain the exact site x event x water type x habitat x sampler
# grain. Missing processed-taxonomy children are retained as an explicit
# unknown state and are not silently converted to zero.

INV_SCIENCE_VERSION <- "2.1.0"
INV_EPT_ORDERS <- c("Ephemeroptera", "Plecoptera", "Trichoptera")
INV_STANDARD_SAMPLERS_RELEASE_2026 <- c(
  "surber", "core", "benthicsweep", "petiteponar", "modifiedkicknet",
  "hess", "lwd", "snag", "floatingsweep"
)
INV_NONSTANDARD_SAMPLERS_RELEASE_2026 <- "grab"
INV_REVIEWED_SAMPLERS_RELEASE_2026 <- c(
  INV_STANDARD_SAMPLERS_RELEASE_2026,
  INV_NONSTANDARD_SAMPLERS_RELEASE_2026
)
# `record_status` is deliberately one mutually exclusive label even when an
# opportunity has several audit flags. The first applicable state wins.
INV_RECORD_STATUS_PRECEDENCE <- c(
  "unstratifiable", "sampling_impractical", "nonstandard_collection",
  "processing_unknown", "processed_no_taxonomy", "count_unavailable",
  "area_unavailable", "density_unavailable", "reported_zero_count",
  "quantified_community"
)
INV_RECORD_STATUS_LEVELS <- c(
  "sampling_impractical", "unstratifiable", "nonstandard_collection",
  "processing_unknown", "processed_no_taxonomy", "count_unavailable",
  "area_unavailable", "density_unavailable", "reported_zero_count",
  "quantified_community"
)
INV_PROCESSING_COUNT_STATUS_LEVELS <- c(
  "processing_unknown", "processed_no_taxonomy",
  "taxonomy_count_unavailable", "taxonomy_count_available"
)

inv_science_fail <- function(...) stop(sprintf(...), call. = FALSE)

inv_science_assert <- function(ok, ...) {
  if (!isTRUE(ok)) inv_science_fail(...)
}

inv_science_blank <- function(x) {
  is.na(x) | !nzchar(trimws(as.character(x)))
}

inv_science_chr <- function(x, missing = "(not recorded)") {
  y <- trimws(as.character(x))
  y[is.na(y) | !nzchar(y)] <- missing
  y
}

inv_science_num <- function(x) suppressWarnings(as.numeric(as.character(x)))

inv_science_normalize_sampler_type <- function(x) {
  value <- trimws(as.character(x))
  value[is.na(value) | !nzchar(value)] <- NA_character_
  tolower(gsub("[[:space:]_-]+", "", value))
}

inv_science_is_ept_order <- function(x) {
  value <- trimws(as.character(x))
  value[is.na(value) | !nzchar(value)] <- NA_character_
  tolower(value) %in% tolower(INV_EPT_ORDERS)
}

inv_science_nonstandard_id_hint <- function(sample_id) {
  !inv_science_blank(sample_id) &
    grepl(
      "(^|[._-])(GRAB|BRYOZOAN|MACROALGAE[0-9]*)([._-]|$)",
      as.character(sample_id), ignore.case = TRUE
    )
}

inv_science_require <- function(x, table_name, columns) {
  inv_science_assert(is.data.frame(x), "%s must be a data frame", table_name)
  missing <- setdiff(columns, names(x))
  inv_science_assert(!length(missing), "%s is missing required column(s): %s",
                     table_name, paste(missing, collapse = ", "))
  invisible(x)
}

inv_science_pair_key <- function(sample_id, sample_code) {
  # sampleCode is optional provenance in RELEASE-2026 (1,602 practical field
  # rows omit it). sampleID is complete and unique across practical collection
  # opportunities, so it is the fail-closed analysis join identity.
  inv_science_chr(sample_id)
}

inv_science_stratum_key <- function(site_id, event_id, water_type,
                                    habitat_type, sampler_type) {
  paste(inv_science_chr(site_id), inv_science_chr(event_id),
        inv_science_chr(water_type), inv_science_chr(habitat_type),
        inv_science_chr(sampler_type), sep = "\u241e")
}

inv_science_strict_value <- function(x, label) {
  values <- unique(trimws(as.character(x[!inv_science_blank(x)])))
  inv_science_assert(length(values) <= 1L,
                     "Conflicting %s values within one sample/taxon: %s",
                     label, paste(values, collapse = ", "))
  if (length(values)) values[[1]] else NA_character_
}

inv_science_date_range <- function(x) {
  dates <- suppressWarnings(as.Date(substr(as.character(x), 1L, 10L)))
  dates <- dates[!is.na(dates)]
  if (!length(dates)) return(c(NA_character_, NA_character_))
  as.character(range(dates))
}

inv_science_hill <- function(counts) {
  counts <- inv_science_num(counts)
  counts <- counts[is.finite(counts) & counts > 0]
  if (!length(counts)) return(c(q1 = NA_real_, q2 = NA_real_))
  p <- counts / sum(counts)
  c(q1 = exp(-sum(p * log(p))), q2 = 1 / sum(p^2))
}

inv_science_mean <- function(x) {
  x <- inv_science_num(x)
  x <- x[is.finite(x)]
  if (length(x)) mean(x) else NA_real_
}

inv_science_sd <- function(x) {
  x <- inv_science_num(x)
  x <- x[is.finite(x)]
  if (length(x) <= 1L) return(NA_real_)

  # stats::sd() can overflow internally even when the mathematically correct
  # result is finite (for example, sd(c(1e308, 0))). Scale centered values
  # before squaring so finite sample densities cannot manufacture Inf output.
  center <- mean(x)
  delta <- x - center
  scale <- max(abs(delta))
  if (!is.finite(center) || !is.finite(scale)) return(NA_real_)
  if (scale == 0) return(0)
  value <- scale * sqrt(sum((delta / scale)^2) / (length(x) - 1L))
  if (is.finite(value)) value else NA_real_
}

inv_science_median <- function(x) {
  x <- inv_science_num(x)
  x <- x[is.finite(x)]
  if (length(x)) stats::median(x) else NA_real_
}

inv_science_count_value <- function(estimated, individual, subsample_percent) {
  estimated <- inv_science_num(estimated)
  individual <- inv_science_num(individual)
  subsample_percent <- inv_science_num(subsample_percent)

  issue <- rep(NA_character_, length(estimated))
  value <- estimated

  issue[is.infinite(estimated) | is.nan(estimated)] <-
    "nonfinite_estimated_count"
  issue[is.infinite(individual) | is.nan(individual)] <-
    "nonfinite_individual_count"
  issue[is.infinite(subsample_percent) | is.nan(subsample_percent) |
          (is.finite(subsample_percent) &
             (subsample_percent < 0 | subsample_percent > 100))] <-
    "invalid_subsample_percent"
  issue[is.finite(estimated) & estimated < 0] <- "negative_estimated_count"
  issue[is.finite(individual) & individual < 0] <- "negative_individual_count"
  contradiction <- is.finite(estimated) & is.finite(individual) &
    estimated + sqrt(.Machine$double.eps) < individual
  issue[contradiction] <- "estimated_below_individual_count"

  missing <- !is.finite(value) & is.na(issue)
  issue[missing] <- "estimated_count_unavailable"
  value[!is.na(issue)] <- NA_real_
  displayed_zero_authoritative <- is.finite(subsample_percent) &
    subsample_percent == 0 & is.na(issue)
  data.frame(
    count_used = value, count_issue = issue,
    displayed_zero_percent_authoritative_estimate =
      displayed_zero_authoritative,
             stringsAsFactors = FALSE)
}

inv_science_taxon_key <- function(accepted_id, scientific_name, taxon_rank,
                                  uid, individual_count,
                                  estimated_total_count) {
  accepted <- trimws(as.character(accepted_id))
  unresolved <- inv_science_blank(accepted)
  inv_science_assert(
    !any(unresolved &
           (!is.na(inv_science_num(individual_count)) |
              !is.na(inv_science_num(estimated_total_count)))),
    paste0(
      "Unresolved taxonomy placeholder has a reported individual or ",
      "estimated count at row %d"
    ),
    if (any(unresolved &
              (!is.na(inv_science_num(individual_count)) |
                 !is.na(inv_science_num(estimated_total_count))))) {
      which(unresolved &
              (!is.na(inv_science_num(individual_count)) |
                 !is.na(inv_science_num(estimated_total_count))))[[1]]
    } else 0L
  )
  inv_science_assert(
    !any(unresolved & inv_science_blank(uid)),
    "Unresolved taxonomy placeholder lacks source UID at row %d",
    if (any(unresolved & inv_science_blank(uid))) {
      which(unresolved & inv_science_blank(uid))[[1]]
    } else 0L
  )
  accepted[unresolved] <- paste0(
    "unresolved-source-record:", as.character(uid[unresolved])
  )
  accepted
}

inv_science_assert_taxon_metadata <- function(collapsed) {
  if (!nrow(collapsed)) return(invisible(collapsed))
  groups <- split(seq_len(nrow(collapsed)), collapsed$taxon_key, drop = TRUE)
  fields <- c("acceptedTaxonID", "scientificName", "taxonRank", "order",
              "family", "class", "subclass")
  for (taxon in names(groups)) {
    part <- collapsed[groups[[taxon]], , drop = FALSE]
    for (field in fields) {
      inv_science_strict_value(
        part[[field]], sprintf("%s for taxon_key %s", field, taxon)
      )
    }
  }
  invisible(collapsed)
}

inv_science_canonical_taxon_metadata <- function(collapsed) {
  if (!nrow(collapsed)) {
    return(data.frame(
      taxon_key = character(), acceptedTaxonID = character(),
      scientificName = character(), taxonRank = character(), order = character(),
      family = character(), class = character(), subclass = character(),
      order_classified = logical(), is_ept = logical(),
      stringsAsFactors = FALSE
    ))
  }
  groups <- split(seq_len(nrow(collapsed)), collapsed$taxon_key, drop = TRUE)
  rows <- lapply(names(groups), function(taxon) {
    part <- collapsed[groups[[taxon]], , drop = FALSE]
    order_value <- inv_science_strict_value(
      part$order, sprintf("order for taxon_key %s", taxon)
    )
    data.frame(
      taxon_key = taxon,
      acceptedTaxonID = inv_science_strict_value(
        part$acceptedTaxonID, sprintf("acceptedTaxonID for taxon_key %s", taxon)
      ),
      scientificName = inv_science_strict_value(
        part$scientificName, sprintf("scientificName for taxon_key %s", taxon)
      ),
      taxonRank = inv_science_strict_value(
        part$taxonRank, sprintf("taxonRank for taxon_key %s", taxon)
      ),
      order = order_value,
      family = inv_science_strict_value(
        part$family, sprintf("family for taxon_key %s", taxon)
      ),
      class = inv_science_strict_value(
        part$class, sprintf("class for taxon_key %s", taxon)
      ),
      subclass = inv_science_strict_value(
        part$subclass, sprintf("subclass for taxon_key %s", taxon)
      ),
      order_classified = !is.na(order_value),
      is_ept = identical(inv_science_is_ept_order(order_value), TRUE),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out <- out[order(out$taxon_key), , drop = FALSE]
  rownames(out) <- NULL
  out
}

inv_science_empty_taxon_strata <- function() {
  data.frame(
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
  )
}

inv_science_empty_opportunities <- function() {
  data.frame(
    opportunity_id = character(), sample_key = character(),
    sampleID = character(), sampleCode = character(), siteID = character(),
    eventID = character(), collectDate = character(),
    aquaticSiteType = character(), habitatType = character(),
    samplerType = character(), namedLocation = character(),
    sampleNumber = character(), samplingImpractical = character(),
    stratum_key = character(), has_per_sample = logical(),
    sampling_practical = logical(), sampler_type_normalized = character(),
    nonstandard_id_hint = logical(), grain_complete = logical(),
    unstratifiable = logical(), nonstandard_collection = logical(),
    primary_stratum = logical(), processing_unknown = logical(),
    taxonomy_count_unavailable = logical(),
    displayed_zero_percent_authoritative_estimate = logical(),
    processing_count_status = character(), taxonomy_rows = integer(),
    record_status = character(), count_issue = character(),
    density_issue = character(), benthicArea_m2 = numeric(),
    total_estimated_count = numeric(), count_eligible = logical(),
    density_eligible = logical(), reported_zero_count = logical(),
    sample_density_m2 = numeric(), taxa_observed = integer(),
    ept_taxa_observed = integer(), hill_q1 = numeric(), hill_q2 = numeric(),
    pct_ept_of_all_estimated_count = numeric(),
    pct_order_classified_estimated_count = numeric(),
    stringsAsFactors = FALSE
  )
}

inv_science_empty_site_summary <- function() {
  data.frame(
    siteID = character(), collectDate_min = character(),
    collectDate_max = character(), n_events = integer(),
    n_strata = integer(), n_opportunities = integer(),
    n_sampling_impractical = integer(), n_nonstandard_collection = integer(),
    n_unstratifiable = integer(), n_processing_unknown = integer(),
    n_processed_no_taxonomy = integer(),
    n_taxonomy_count_unavailable = integer(),
    n_displayed_zero_percent_authoritative_estimate = integer(),
    n_count_samples = integer(), n_density_samples = integer(),
    n_taxa_recorded = integer(), taxonomic_ranks = character(),
    stringsAsFactors = FALSE
  )
}

inv_science_collapse_taxonomy <- function(taxonomy) {
  if (!nrow(taxonomy)) {
    return(data.frame(
      sample_key = character(), sampleID = character(), sampleCode = character(),
      taxon_key = character(), acceptedTaxonID = character(),
      scientificName = character(), taxonRank = character(), order = character(),
      family = character(), class = character(), subclass = character(),
      estimated_count = numeric(), count_valid = logical(),
      count_issue = character(),
      displayed_zero_percent_authoritative_estimate = logical(),
      order_classified = logical(),
      is_ept = logical(), stringsAsFactors = FALSE
    ))
  }

  counts <- inv_science_count_value(
    taxonomy$estimatedTotalCount, taxonomy$individualCount,
    taxonomy$subsamplePercent
  )
  # Keep derived keys outside the 320k-row source frame. Appending several
  # columns and then splitting that wide frame once per sample/taxon group
  # creates a large transient allocation on constrained Actions runners.
  sample_key <- inv_science_pair_key(taxonomy$sampleID, taxonomy$sampleCode)
  taxon_key <- inv_science_taxon_key(
    taxonomy$acceptedTaxonID, taxonomy$scientificName, taxonomy$taxonRank,
    taxonomy$uid, taxonomy$individualCount, taxonomy$estimatedTotalCount
  )
  group_key <- paste(sample_key, taxon_key, sep = "\u241d")
  unique_group_key <- unique(group_key)
  group_id <- match(group_key, unique_group_key)
  n_groups <- length(unique_group_key)
  first_index <- match(seq_len(n_groups), group_id)

  strict_group_values <- function(values, label) {
    normalized <- trimws(as.character(values))
    nonblank <- !is.na(normalized) & nzchar(normalized)
    result <- rep(NA_character_, n_groups)
    if (!any(nonblank)) return(result)

    present_group <- group_id[nonblank]
    present_value <- normalized[nonblank]
    first <- !duplicated(present_group)
    result[present_group[first]] <- present_value[first]
    conflict <- present_value != result[present_group]
    inv_science_assert(
      !any(conflict), "Conflicting %s values within one sample/taxon: %s",
      label,
      if (any(conflict)) {
        paste(unique(present_value[conflict]), collapse = ", ")
      } else ""
    )
    result
  }

  count_input <- counts$count_used
  count_input[!is.finite(count_input)] <- 0
  collapsed_count <- as.numeric(rowsum(
    count_input, group = group_id, reorder = TRUE
  ))
  invalid_row <- !is.na(counts$count_issue)
  invalid_groups <- unique(group_id[invalid_row])
  count_valid <- !seq_len(n_groups) %in% invalid_groups
  count_issue <- rep(NA_character_, n_groups)
  if (any(invalid_row)) {
    issue_groups <- split(counts$count_issue[invalid_row], group_id[invalid_row])
    issue_id <- as.integer(names(issue_groups))
    count_issue[issue_id] <- vapply(
      issue_groups,
      function(issue) paste(sort(unique(issue)), collapse = ";"),
      character(1)
    )
  }
  overflow <- count_valid & !is.finite(collapsed_count)
  count_valid[overflow] <- FALSE
  count_issue[overflow] <- "nonfinite_collapsed_count"
  collapsed_count[!count_valid] <- NA_real_

  out <- data.frame(
    sample_key = sample_key[first_index],
    sampleID = strict_group_values(taxonomy$sampleID, "sampleID"),
    sampleCode = strict_group_values(taxonomy$sampleCode, "sampleCode"),
    taxon_key = taxon_key[first_index],
    acceptedTaxonID = strict_group_values(
      taxonomy$acceptedTaxonID, "acceptedTaxonID"
    ),
    scientificName = strict_group_values(
      taxonomy$scientificName, "scientificName"
    ),
    taxonRank = strict_group_values(taxonomy$taxonRank, "taxonRank"),
    order = strict_group_values(taxonomy$order, "order"),
    family = strict_group_values(taxonomy$family, "family"),
    class = strict_group_values(taxonomy$class, "class"),
    subclass = strict_group_values(taxonomy$subclass, "subclass"),
    estimated_count = collapsed_count, count_valid = count_valid,
    count_issue = count_issue,
    displayed_zero_percent_authoritative_estimate = as.numeric(rowsum(
      as.integer(counts$displayed_zero_percent_authoritative_estimate),
      group = group_id, reorder = TRUE
    )) > 0,
    order_classified = logical(n_groups), is_ept = logical(n_groups),
    stringsAsFactors = FALSE
  )
  out$order_classified <- !is.na(out$order)
  out$is_ept <- inv_science_is_ept_order(out$order)
  inv_science_assert_taxon_metadata(out)
  out <- out[order(out$sample_key, out$taxon_key), , drop = FALSE]
  rownames(out) <- NULL
  out
}

inv_science_opportunity_id <- function(field) {
  sample_key <- inv_science_pair_key(field$sampleID, field$sampleCode)
  has_sample <- !inv_science_blank(field$sampleID)
  field_key <- apply(
    data.frame(
      namedLocation = inv_science_chr(field$namedLocation),
      eventID = inv_science_chr(field$eventID),
      sampleID = inv_science_chr(field$sampleID),
      sampleCode = inv_science_chr(field$sampleCode),
      habitatType = inv_science_chr(field$habitatType),
      samplerType = inv_science_chr(field$samplerType),
      sampleNumber = inv_science_chr(field$sampleNumber),
      stringsAsFactors = FALSE
    ), 1L, paste, collapse = "\u241c"
  )
  ifelse(has_sample, paste0("sample:", sample_key), paste0("field:", field_key))
}

inv_science_sample_metrics <- function(collapsed, sample_keys) {
  n_samples <- length(sample_keys)
  result <- data.frame(
    sample_key = sample_keys, taxa_observed = integer(n_samples),
    ept_taxa_observed = integer(n_samples),
    hill_q1 = rep(NA_real_, n_samples), hill_q2 = rep(NA_real_, n_samples),
    pct_ept_of_all_estimated_count = rep(NA_real_, n_samples),
    pct_order_classified_estimated_count = rep(NA_real_, n_samples),
    stringsAsFactors = FALSE
  )
  if (!length(sample_keys) || !nrow(collapsed)) return(result)

  groups <- split(seq_len(nrow(collapsed)), collapsed$sample_key, drop = TRUE)
  for (i in seq_along(sample_keys)) {
    key <- sample_keys[[i]]
    index <- groups[[key]]
    if (is.null(index)) next
    part <- collapsed[index, , drop = FALSE]
    positive <- part$count_valid & is.finite(part$estimated_count) &
      part$estimated_count > 0
    counts <- part$estimated_count[positive]
    result$taxa_observed[[i]] <- sum(positive)
    result$ept_taxa_observed[[i]] <- sum(positive & part$is_ept)
    hill <- inv_science_hill(counts)
    result$hill_q1[[i]] <- hill[["q1"]]
    result$hill_q2[[i]] <- hill[["q2"]]
    total <- sum(counts)
    if (is.finite(total) && total > 0) {
      result$pct_ept_of_all_estimated_count[[i]] <-
        100 * sum(part$estimated_count[positive & part$is_ept]) / total
      result$pct_order_classified_estimated_count[[i]] <-
        100 * sum(part$estimated_count[positive & part$order_classified]) / total
    }
  }
  result
}

inv_science_event_strata <- function(opportunities) {
  opportunities <- opportunities[opportunities$primary_stratum, , drop = FALSE]
  if (!nrow(opportunities)) {
    return(data.frame(
      stratum_key = character(), siteID = character(), eventID = character(),
      aquaticSiteType = character(), habitatType = character(),
      samplerType = character(), collectDate_min = character(),
      collectDate_max = character(), n_opportunities = integer(),
      n_sampling_impractical = integer(), n_processing_unknown = integer(),
      n_processed_no_taxonomy = integer(),
      n_taxonomy_count_unavailable = integer(),
      n_displayed_zero_percent_authoritative_estimate = integer(),
      n_count_unavailable = integer(), n_area_unavailable = integer(),
      n_density_unavailable = integer(), n_count_samples = integer(),
      n_composition_samples = integer(), n_density_samples = integer(),
      n_reported_zero_count = integer(), mean_sample_density_m2 = numeric(),
      median_sample_density_m2 = numeric(), sd_sample_density_m2 = numeric(),
      se_sample_density_m2 = numeric(), mean_sample_taxa_observed = numeric(),
      mean_sample_ept_taxa_observed = numeric(), mean_sample_hill_q1 = numeric(),
      mean_sample_hill_q2 = numeric(),
      mean_sample_pct_ept_of_all_estimated_count = numeric(),
      mean_sample_pct_order_classified_estimated_count = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  groups <- split(seq_len(nrow(opportunities)), opportunities$stratum_key,
                  drop = TRUE)
  rows <- lapply(groups, function(index) {
    part <- opportunities[index, , drop = FALSE]
    count_part <- part[part$count_eligible, , drop = FALSE]
    composition_part <- count_part[
      is.finite(count_part$total_estimated_count) &
        count_part$total_estimated_count > 0, , drop = FALSE
    ]
    density_part <- part[part$density_eligible, , drop = FALSE]
    dates <- inv_science_date_range(part$collectDate)
    density_sd <- inv_science_sd(density_part$sample_density_m2)
    n_density <- nrow(density_part)
    data.frame(
      stratum_key = part$stratum_key[[1]], siteID = part$siteID[[1]],
      eventID = part$eventID[[1]], aquaticSiteType = part$aquaticSiteType[[1]],
      habitatType = part$habitatType[[1]], samplerType = part$samplerType[[1]],
      collectDate_min = dates[[1]], collectDate_max = dates[[2]],
      n_opportunities = nrow(part),
      n_sampling_impractical = sum(part$record_status == "sampling_impractical"),
      n_processing_unknown = sum(part$processing_unknown),
      n_processed_no_taxonomy = sum(
        part$processing_count_status %in% "processed_no_taxonomy"
      ),
      n_taxonomy_count_unavailable = sum(part$taxonomy_count_unavailable),
      n_displayed_zero_percent_authoritative_estimate = sum(
        part$displayed_zero_percent_authoritative_estimate
      ),
      n_count_unavailable = sum(part$record_status == "count_unavailable"),
      n_area_unavailable = sum(part$record_status == "area_unavailable"),
      n_density_unavailable = sum(part$record_status == "density_unavailable"),
      n_count_samples = nrow(count_part),
      n_composition_samples = nrow(composition_part),
      n_density_samples = n_density,
      n_reported_zero_count = sum(part$reported_zero_count),
      mean_sample_density_m2 = inv_science_mean(density_part$sample_density_m2),
      median_sample_density_m2 = inv_science_median(density_part$sample_density_m2),
      sd_sample_density_m2 = density_sd,
      se_sample_density_m2 = if (n_density > 1L) density_sd / sqrt(n_density) else NA_real_,
      mean_sample_taxa_observed = inv_science_mean(count_part$taxa_observed),
      mean_sample_ept_taxa_observed = inv_science_mean(count_part$ept_taxa_observed),
      mean_sample_hill_q1 = inv_science_mean(composition_part$hill_q1),
      mean_sample_hill_q2 = inv_science_mean(composition_part$hill_q2),
      mean_sample_pct_ept_of_all_estimated_count =
        inv_science_mean(composition_part$pct_ept_of_all_estimated_count),
      mean_sample_pct_order_classified_estimated_count =
        inv_science_mean(composition_part$pct_order_classified_estimated_count),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out[order(out$siteID, out$eventID, out$aquaticSiteType,
            out$habitatType, out$samplerType), , drop = FALSE]
}

inv_science_taxon_strata <- function(opportunities, collapsed) {
  count_opportunities <- opportunities[
    opportunities$primary_stratum & opportunities$count_eligible,
    c(
      "sample_key", "stratum_key", "siteID", "eventID",
      "aquaticSiteType", "habitatType", "samplerType", "density_eligible",
      "benthicArea_m2"
    ), drop = FALSE
  ]
  if (!nrow(count_opportunities) || !nrow(collapsed)) {
    return(inv_science_empty_taxon_strata())
  }

  # Each collapsed row is already unique at sample x taxon. A narrow match
  # avoids copying the full collapsed table through merge(), and one group-id
  # ledger replaces repeated stratum/taxon scans and per-row data frames.
  sample_index <- match(collapsed$sample_key, count_opportunities$sample_key)
  keep <- !is.na(sample_index) & collapsed$count_valid &
    is.finite(collapsed$estimated_count)
  if (!any(keep)) return(inv_science_empty_taxon_strata())
  sample_index <- sample_index[keep]
  joined_sample_key <- collapsed$sample_key[keep]
  joined_taxon_key <- collapsed$taxon_key[keep]
  joined_count <- collapsed$estimated_count[keep]
  joined_stratum_key <- count_opportunities$stratum_key[sample_index]

  canonical_metadata <- inv_science_canonical_taxon_metadata(collapsed)

  unique_stratum <- unique(count_opportunities$stratum_key)
  opportunity_stratum_id <- match(
    count_opportunities$stratum_key, unique_stratum
  )
  n_count_by_stratum <- tabulate(
    opportunity_stratum_id, nbins = length(unique_stratum)
  )
  n_density_by_stratum <- tabulate(
    opportunity_stratum_id[count_opportunities$density_eligible],
    nbins = length(unique_stratum)
  )

  group_key <- paste(joined_stratum_key, joined_taxon_key, sep = "\u241d")
  unique_group_key <- unique(group_key)
  group_id <- match(group_key, unique_group_key)
  n_groups <- length(unique_group_key)
  first_index <- match(seq_len(n_groups), group_id)
  group_stratum <- joined_stratum_key[first_index]
  group_taxon <- joined_taxon_key[first_index]
  group_stratum_id <- match(group_stratum, unique_stratum)
  taxon_total <- as.numeric(rowsum(
    joined_count, group = group_id, reorder = TRUE
  ))
  n_present <- as.integer(as.numeric(rowsum(
    as.integer(joined_count > 0), group = group_id, reorder = TRUE
  )))
  inv_science_assert(
    all(is.finite(taxon_total)),
    "Nonfinite cross-sample taxon total for stratum %s and taxon_key %s",
    if (any(!is.finite(taxon_total))) {
      group_stratum[which(!is.finite(taxon_total))[[1L]]]
    } else "",
    if (any(!is.finite(taxon_total))) {
      group_taxon[which(!is.finite(taxon_total))[[1L]]]
    } else ""
  )
  positive_group <- taxon_total > 0
  if (!any(positive_group)) return(inv_science_empty_taxon_strata())

  joined_density_eligible <-
    count_opportunities$density_eligible[sample_index]
  joined_density <- rep(0, length(joined_count))
  joined_density[joined_density_eligible] <-
    joined_count[joined_density_eligible] /
    count_opportunities$benthicArea_m2[sample_index[joined_density_eligible]]
  positive_density <- joined_density_eligible & joined_density > 0
  positive_density_groups <- split(
    joined_density[positive_density], group_id[positive_density], drop = TRUE
  )
  density_scale <- numeric(n_groups)
  if (length(positive_density_groups)) {
    positive_group_id <- as.integer(names(positive_density_groups))
    density_scale[positive_group_id] <- vapply(
      positive_density_groups, max, numeric(1)
    )
  }
  scaled_density <- numeric(length(joined_density))
  scaled_density[positive_density] <-
    joined_density[positive_density] / density_scale[group_id[positive_density]]
  scaled_density_sum <- as.numeric(rowsum(
    scaled_density, group = group_id, reorder = TRUE
  ))
  zero_filled_median <- function(id, denominator) {
    if (!denominator) return(NA_real_)
    positive <- sort(positive_density_groups[[as.character(id)]])
    if (is.null(positive)) positive <- numeric()
    zero_count <- denominator - length(positive)
    ranked_value <- function(rank) {
      if (rank <= zero_count) 0 else positive[[rank - zero_count]]
    }
    lower <- as.integer(floor((denominator + 1) / 2))
    upper <- as.integer(ceiling((denominator + 1) / 2))
    lower_value <- ranked_value(lower)
    upper_value <- ranked_value(upper)
    lower_value + (upper_value - lower_value) / 2
  }

  retained_id <- which(positive_group)
  retained_stratum_id <- group_stratum_id[retained_id]
  stratum_row <- match(group_stratum[retained_id],
                       count_opportunities$stratum_key)
  metadata_row <- match(group_taxon[retained_id],
                        canonical_metadata$taxon_key)
  inv_science_assert(
    !anyNA(metadata_row),
    "Canonical metadata is unavailable for a retained taxon stratum"
  )
  n_count <- n_count_by_stratum[retained_stratum_id]
  n_density <- n_density_by_stratum[retained_stratum_id]
  median_density <- vapply(seq_along(retained_id), function(index) {
    zero_filled_median(retained_id[[index]], n_density[[index]])
  }, numeric(1))
  out <- data.frame(
    stratum_key = group_stratum[retained_id],
    siteID = count_opportunities$siteID[stratum_row],
    eventID = count_opportunities$eventID[stratum_row],
    aquaticSiteType = count_opportunities$aquaticSiteType[stratum_row],
    habitatType = count_opportunities$habitatType[stratum_row],
    samplerType = count_opportunities$samplerType[stratum_row],
    taxon_key = group_taxon[retained_id],
    acceptedTaxonID = canonical_metadata$acceptedTaxonID[metadata_row],
    scientificName = canonical_metadata$scientificName[metadata_row],
    taxonRank = canonical_metadata$taxonRank[metadata_row],
    order = canonical_metadata$order[metadata_row],
    family = canonical_metadata$family[metadata_row],
    class = canonical_metadata$class[metadata_row],
    subclass = canonical_metadata$subclass[metadata_row],
    is_ept = canonical_metadata$is_ept[metadata_row],
    order_classified = canonical_metadata$order_classified[metadata_row],
    n_count_eligible_samples = as.integer(n_count),
    n_density_eligible_samples = as.integer(n_density),
    n_samples_present = n_present[retained_id],
    support_pct = 100 * n_present[retained_id] / n_count,
    mean_sample_density_m2 = ifelse(
      n_density > 0,
      density_scale[retained_id] *
        (scaled_density_sum[retained_id] / n_density),
      NA_real_
    ),
    median_sample_density_m2 = median_density,
    total_estimated_count = taxon_total[retained_id],
    stringsAsFactors = FALSE
  )
  rownames(out) <- NULL
  out <- out[order(out$siteID, out$eventID, out$aquaticSiteType,
                   out$habitatType, out$samplerType,
            -out$mean_sample_density_m2, out$taxon_key), , drop = FALSE]
  rownames(out) <- NULL
  out
}

inv_science_site_summary <- function(opportunities, taxon_strata) {
  recorded_site <- !inv_science_blank(opportunities$siteID) &
    opportunities$siteID != "(not recorded)"
  opportunities <- opportunities[recorded_site, , drop = FALSE]
  if (!nrow(opportunities)) return(inv_science_empty_site_summary())

  groups <- split(seq_len(nrow(opportunities)), opportunities$siteID, drop = TRUE)
  rows <- lapply(groups, function(index) {
    part <- opportunities[index, , drop = FALSE]
    dates <- inv_science_date_range(part$collectDate)
    site_taxa <- if (nrow(taxon_strata)) {
      unique(taxon_strata$taxon_key[taxon_strata$siteID == part$siteID[[1]]])
    } else character()
    ranks <- if (nrow(taxon_strata)) {
      sort(unique(taxon_strata$taxonRank[
        taxon_strata$siteID == part$siteID[[1]] &
          !inv_science_blank(taxon_strata$taxonRank)
      ]))
    } else character()
    data.frame(
      siteID = part$siteID[[1]],
      collectDate_min = dates[[1]], collectDate_max = dates[[2]],
      n_events = length(unique(part$eventID[part$primary_stratum])),
      n_strata = length(unique(part$stratum_key[part$primary_stratum])),
      n_opportunities = nrow(part),
      n_sampling_impractical = sum(!part$sampling_practical),
      n_nonstandard_collection = sum(part$nonstandard_collection),
      n_unstratifiable = sum(part$unstratifiable),
      n_processing_unknown = sum(part$processing_unknown),
      n_processed_no_taxonomy = sum(
        part$processing_count_status %in% "processed_no_taxonomy"
      ),
      n_taxonomy_count_unavailable = sum(part$taxonomy_count_unavailable),
      n_displayed_zero_percent_authoritative_estimate = sum(
        part$displayed_zero_percent_authoritative_estimate
      ),
      n_count_samples = sum(part$count_eligible),
      n_density_samples = sum(part$density_eligible),
      n_taxa_recorded = length(site_taxa),
      taxonomic_ranks = paste(ranks, collapse = ", "),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out <- out[order(out$siteID), , drop = FALSE]
  rownames(out) <- NULL
  out
}

inv_science_metric_contract <- function() {
  data.frame(
    metric = c(
      "sample_total_estimated_count", "sample_density_m2",
      "sample_taxa_observed", "sample_ept_taxa_observed",
      "sample_hill_q1", "sample_hill_q2",
      "sample_pct_ept_of_all_estimated_count",
      "sample_pct_order_classified_estimated_count",
      "mean_sample_density_m2", "median_sample_density_m2",
      "sd_sample_density_m2", "se_sample_density_m2",
      "mean_sample_taxa_observed", "mean_sample_ept_taxa_observed",
      "mean_sample_hill_q1", "mean_sample_hill_q2",
      "mean_sample_pct_ept_of_all_estimated_count",
      "mean_sample_pct_order_classified_estimated_count",
      "taxon_mean_sample_density_m2", "taxon_median_sample_density_m2",
      "taxon_support_pct", "taxon_total_estimated_count"
    ),
    table = c(
      rep("opportunities", 8), rep("event_strata", 10),
      rep("taxon_strata", 4)
    ),
    column = c(
      "total_estimated_count", "sample_density_m2", "taxa_observed",
      "ept_taxa_observed", "hill_q1", "hill_q2",
      "pct_ept_of_all_estimated_count",
      "pct_order_classified_estimated_count",
      "mean_sample_density_m2", "median_sample_density_m2",
      "sd_sample_density_m2", "se_sample_density_m2",
      "mean_sample_taxa_observed", "mean_sample_ept_taxa_observed",
      "mean_sample_hill_q1", "mean_sample_hill_q2",
      "mean_sample_pct_ept_of_all_estimated_count",
      "mean_sample_pct_order_classified_estimated_count",
      "mean_sample_density_m2", "median_sample_density_m2",
      "support_pct", "total_estimated_count"
    ),
    grain = c(
      rep("site x event x aquaticSiteType x habitatType x samplerType x sample", 8),
      rep("site x event x aquaticSiteType x habitatType x samplerType", 10),
      rep("site x event x aquaticSiteType x habitatType x samplerType x taxon", 4)
    ),
    denominator = c(
      "sum of valid expanded taxon counts within the count-eligible sample",
      "sample total expanded count / published usable benthic area",
      "positive-count accepted taxon identities within the count-eligible sample",
      "positive-count accepted taxon identities assigned to an EPT order within the count-eligible sample",
      "Hill q=1 from positive expanded taxon counts within the count-eligible sample",
      "Hill q=2 from positive expanded taxon counts within the count-eligible sample",
      "EPT positive expanded counts / all positive expanded counts within the sample; denominator includes classified and unclassified orders",
      "positive expanded counts with a recorded order / all positive expanded counts within the sample",
      "arithmetic mean of density-eligible sample-level total density",
      "median of density-eligible sample-level total density",
      "sample SD of density-eligible sample-level total density",
      "sample SD / sqrt(number of density-eligible samples)",
      "arithmetic mean of count-eligible sample-level recorded taxon counts",
      "arithmetic mean of count-eligible sample-level EPT taxon counts",
      "arithmetic mean across positive-total count-eligible sample-level Hill q=1 values",
      "arithmetic mean across positive-total count-eligible sample-level Hill q=2 values",
      "arithmetic mean across positive-total count-eligible sample EPT expanded-count shares; denominator includes classified and unclassified order counts",
      "arithmetic mean across positive-total count-eligible sample shares whose positive expanded counts have a recorded order",
      "zero-filled mean across density-eligible samples in the exact stratum",
      "zero-filled median across density-eligible samples in the exact stratum",
      "positive-count samples / count-eligible samples in the exact stratum",
      "sum of expanded counts across count-eligible samples in the exact stratum"
    ),
    boundary = c(
      "expanded laboratory count sum; not a population count",
      "descriptive collection density; not a population estimate",
      "mixed-rank taxa recorded; not species richness or estimated true richness",
      "mixed-rank EPT taxa recorded; descriptive only",
      "mixed-rank effective common-taxon count; not species diversity",
      "mixed-rank effective dominant-taxon count; not species diversity",
      "unknown-order counts remain in the denominator; descriptive only, never a water-quality score",
      "classification-support diagnostic for EPT and order summaries",
      "descriptive collection density; not a population estimate",
      "descriptive collection density; not a population estimate",
      "spread of sample density; not temporal or population uncertainty",
      "standard error of collected sample densities; not population uncertainty",
      "mixed-rank taxa recorded; not species richness or estimated true richness",
      "mixed-rank EPT taxa recorded; descriptive only",
      "mixed-rank effective common-taxon count; not species diversity",
      "mixed-rank effective dominant-taxon count; not species diversity",
      "unknown-order counts remain in the denominator; descriptive only, never a water-quality score",
      "classification-support diagnostic for EPT and order summaries",
      "taxon zeros are added only across count-valid processed samples; density also requires usable benthic area",
      "taxon zeros are added only across count-valid processed samples; density also requires usable benthic area",
      "processed-no-taxonomy records are unknown and excluded, not verified absences",
      "expanded laboratory count sum; not a population count"
    ),
    stringsAsFactors = FALSE
  )
}

build_inv_science_contract <- function(source) {
  inv_science_assert(is.list(source), "source must be a named list")
  field <- source$inv_fieldData
  per_sample <- source$inv_persample
  taxonomy <- source$inv_taxonomyProcessed

  inv_science_require(field, "inv_fieldData", c(
    "namedLocation", "eventID", "sampleID", "sampleCode", "habitatType",
    "samplerType", "sampleNumber", "siteID", "collectDate",
    "aquaticSiteType", "benthicArea", "samplingImpractical"
  ))
  inv_science_require(per_sample, "inv_persample", c("sampleID", "sampleCode"))
  inv_science_require(taxonomy, "inv_taxonomyProcessed", c(
    "uid", "sampleID", "sampleCode", "acceptedTaxonID", "scientificName",
    "taxonRank", "order", "family", "class", "subclass",
    "individualCount", "estimatedTotalCount", "subsamplePercent"
  ))

  # The NEON user guide identifies *.DNA samples as metabarcoding material,
  # not collection opportunities for DP1.20120.001 community summaries.
  dna_field <- !inv_science_blank(field$sampleID) &
    grepl("\\.DNA$", trimws(as.character(field$sampleID)), ignore.case = TRUE)
  excluded_dna <- field[dna_field, , drop = FALSE]
  field <- field[!dna_field, , drop = FALSE]

  practical_flag <- trimws(as.character(field$samplingImpractical))
  practical <- is.na(practical_flag) | !nzchar(practical_flag) |
    toupper(practical_flag) == "OK"
  practical_rows <- field[practical, , drop = FALSE]
  inv_science_assert(!any(inv_science_blank(practical_rows$sampleID)),
                     "Every practical collection row must have sampleID")

  field$sample_key <- inv_science_pair_key(field$sampleID, field$sampleCode)
  per_sample$sample_key <- inv_science_pair_key(per_sample$sampleID,
                                                 per_sample$sampleCode)
  taxonomy$sample_key <- inv_science_pair_key(taxonomy$sampleID,
                                               taxonomy$sampleCode)
  practical_keys <- field$sample_key[practical]
  inv_science_assert(!anyDuplicated(practical_keys),
                     "Practical collection sample keys must be unique")
  inv_science_assert(!anyDuplicated(per_sample$sample_key),
                     "inv_persample sample keys must be unique")
  orphan_per <- setdiff(per_sample$sample_key, practical_keys)
  inv_science_assert(!length(orphan_per),
                     "inv_persample child has no practical collection parent: %s",
                     if (length(orphan_per)) orphan_per[[1]] else "")
  orphan_tax <- setdiff(unique(taxonomy$sample_key), practical_keys)
  inv_science_assert(!length(orphan_tax),
                     "Taxonomy child has no practical collection parent: %s",
                     if (length(orphan_tax)) orphan_tax[[1]] else "")

  assert_code_alignment <- function(child, label) {
    field_index <- match(child$sample_key, field$sample_key)
    field_code <- field$sampleCode[field_index]
    both_blank <- inv_science_blank(child$sampleCode) &
      inv_science_blank(field_code)
    both_present_equal <- !inv_science_blank(child$sampleCode) &
      !inv_science_blank(field_code) &
      as.character(child$sampleCode) == as.character(field_code)
    valid <- both_blank | both_present_equal
    inv_science_assert(
      all(valid), "%s sampleCode conflicts with field provenance for %s",
      label, if (any(!valid)) child$sample_key[which(!valid)[[1]]] else ""
    )
  }
  assert_code_alignment(per_sample, "inv_persample")
  assert_code_alignment(taxonomy, "inv_taxonomyProcessed")

  collapsed <- inv_science_collapse_taxonomy(taxonomy)
  tax_groups <- split(seq_len(nrow(collapsed)), collapsed$sample_key, drop = TRUE)

  field$opportunity_id <- inv_science_opportunity_id(field)
  inv_science_assert(!anyDuplicated(field$opportunity_id),
                     "Opportunity identifiers are not unique")
  grain_fields <- c(
    "siteID", "eventID", "aquaticSiteType", "habitatType", "samplerType"
  )
  field$grain_complete <- Reduce(
    `&`, lapply(field[grain_fields], function(value) !inv_science_blank(value))
  )
  field$unstratifiable <- !field$grain_complete
  field$sampling_practical <- practical
  field$sampler_type_normalized <-
    inv_science_normalize_sampler_type(field$samplerType)
  unknown_sampler <- !is.na(field$sampler_type_normalized) &
    !field$sampler_type_normalized %in% INV_REVIEWED_SAMPLERS_RELEASE_2026
  inv_science_assert(
    !any(unknown_sampler),
    paste0(
      "inv_fieldData contains an unreviewed RELEASE-2026 samplerType at row %d: %s; ",
      "update the release-locked sampler roster before metric construction"
    ),
    if (any(unknown_sampler)) which(unknown_sampler)[[1]] else 0L,
    if (any(unknown_sampler)) as.character(field$samplerType[which(unknown_sampler)[[1]]]) else ""
  )
  field$nonstandard_id_hint <- inv_science_nonstandard_id_hint(field$sampleID)
  id_sampler_mismatch <- field$nonstandard_id_hint &
    !is.na(field$sampler_type_normalized) &
    field$sampler_type_normalized != INV_NONSTANDARD_SAMPLERS_RELEASE_2026
  inv_science_assert(
    !any(id_sampler_mismatch),
    paste0(
      "Sample %s has a nonstandard identity token but documented samplerType %s; ",
      "the RELEASE-2026 sampler assertion failed"
    ),
    if (any(id_sampler_mismatch))
      as.character(field$sampleID[which(id_sampler_mismatch)[[1]]]) else "",
    if (any(id_sampler_mismatch))
      as.character(field$samplerType[which(id_sampler_mismatch)[[1]]]) else ""
  )
  field$siteID <- inv_science_chr(field$siteID)
  field$eventID <- inv_science_chr(field$eventID)
  field$aquaticSiteType <- inv_science_chr(field$aquaticSiteType)
  field$habitatType <- inv_science_chr(field$habitatType)
  field$samplerType <- inv_science_chr(field$samplerType)
  field$benthicArea_m2 <- inv_science_num(field$benthicArea)
  field$stratum_key <- inv_science_stratum_key(
    field$siteID, field$eventID, field$aquaticSiteType,
    field$habitatType, field$sampler_type_normalized
  )
  field$has_per_sample <- field$sample_key %in% per_sample$sample_key
  field$nonstandard_collection <- field$sampler_type_normalized %in%
    INV_NONSTANDARD_SAMPLERS_RELEASE_2026
  field$primary_stratum <- !field$nonstandard_collection & !field$unstratifiable
  field$taxonomy_rows <- integer(nrow(field))
  field$displayed_zero_percent_authoritative_estimate <-
    rep(FALSE, nrow(field))
  field$total_estimated_count <- rep(NA_real_, nrow(field))
  field$count_issue <- rep(NA_character_, nrow(field))

  for (i in seq_len(nrow(field))) {
    if (!practical[[i]]) next
    index <- tax_groups[[field$sample_key[[i]]]]
    if (is.null(index)) next
    part <- collapsed[index, , drop = FALSE]
    field$taxonomy_rows[[i]] <- nrow(part)
    field$displayed_zero_percent_authoritative_estimate[[i]] <- any(
      part$displayed_zero_percent_authoritative_estimate
    )
    issues <- unique(part$count_issue[!part$count_valid])
    if (length(issues)) {
      field$count_issue[[i]] <- paste(sort(issues), collapse = ";")
    } else {
      sample_total <- sum(part$estimated_count)
      if (is.finite(sample_total)) {
        field$total_estimated_count[[i]] <- sample_total
      } else {
        field$count_issue[[i]] <- "nonfinite_sample_total"
      }
    }
  }

  valid_area <- is.finite(field$benthicArea_m2) & field$benthicArea_m2 > 0
  analysis_practical <- practical & field$primary_stratum
  field$processing_unknown <- practical & !field$has_per_sample &
    field$taxonomy_rows == 0L
  field$taxonomy_count_unavailable <- practical &
    field$taxonomy_rows > 0L & !is.na(field$count_issue)
  field$processing_count_status <- rep(NA_character_, nrow(field))
  field$processing_count_status[field$processing_unknown] <-
    "processing_unknown"
  field$processing_count_status[
    practical & field$has_per_sample & field$taxonomy_rows == 0L
  ] <- "processed_no_taxonomy"
  field$processing_count_status[field$taxonomy_count_unavailable] <-
    "taxonomy_count_unavailable"
  field$processing_count_status[
    practical & field$taxonomy_rows > 0L & is.na(field$count_issue)
  ] <- "taxonomy_count_available"
  practical_outcome_counts <- table(factor(
    field$processing_count_status[practical],
    levels = INV_PROCESSING_COUNT_STATUS_LEVELS
  ))
  inv_science_assert(
    !anyNA(field$processing_count_status[practical]) &&
      all(is.na(field$processing_count_status[!practical])) &&
      sum(practical_outcome_counts) == sum(practical),
    paste0(
      "Every practical field opportunity must have exactly one mutually ",
      "exclusive processing/count outcome"
    )
  )
  # Precedence is explicit: incomplete comparison grain remains the primary
  # status even when sampling was also impractical. Marginal support ledgers
  # count the underlying booleans, not these mutually exclusive labels.
  field$record_status <- rep(NA_character_, nrow(field))
  field$record_status[field$unstratifiable] <- "unstratifiable"
  field$record_status[is.na(field$record_status) & !practical] <-
    "sampling_impractical"
  field$record_status[is.na(field$record_status) &
                        field$nonstandard_collection] <-
    "nonstandard_collection"
  field$record_status[analysis_practical & field$processing_unknown] <-
    "processing_unknown"
  field$record_status[analysis_practical & field$has_per_sample &
                        field$taxonomy_rows == 0L] <-
    "processed_no_taxonomy"
  field$record_status[analysis_practical &
                        field$taxonomy_count_unavailable] <-
    "count_unavailable"
  field$record_status[analysis_practical & field$taxonomy_rows > 0L &
                        is.na(field$count_issue) & !valid_area] <- "area_unavailable"
  field$count_eligible <- analysis_practical & field$taxonomy_rows > 0L &
    is.na(field$count_issue)
  field$density_issue <- rep(NA_character_, nrow(field))
  candidate_density <- rep(NA_real_, nrow(field))
  density_candidates <- field$count_eligible & valid_area
  candidate_density[density_candidates] <-
    field$total_estimated_count[density_candidates] /
    field$benthicArea_m2[density_candidates]
  nonfinite_density <- density_candidates & !is.finite(candidate_density)
  field$density_issue[nonfinite_density] <- "nonfinite_sample_density"
  field$density_eligible <- density_candidates & !nonfinite_density
  field$reported_zero_count <- field$count_eligible &
    is.finite(field$total_estimated_count) & field$total_estimated_count == 0
  field$record_status[nonfinite_density] <- "density_unavailable"
  field$record_status[field$density_eligible & field$total_estimated_count > 0] <-
    "quantified_community"
  field$record_status[field$density_eligible & field$reported_zero_count] <-
    "reported_zero_count"
  inv_science_assert(!anyNA(field$record_status),
                     "Every retained opportunity must have one record status")
  field$sample_density_m2 <- candidate_density
  field$sample_density_m2[!field$density_eligible] <- NA_real_

  sample_metrics <- inv_science_sample_metrics(collapsed, field$sample_key)
  metric_index <- match(field$sample_key, sample_metrics$sample_key)
  field$taxa_observed <- sample_metrics$taxa_observed[metric_index]
  field$ept_taxa_observed <- sample_metrics$ept_taxa_observed[metric_index]
  field$hill_q1 <- sample_metrics$hill_q1[metric_index]
  field$hill_q2 <- sample_metrics$hill_q2[metric_index]
  field$pct_ept_of_all_estimated_count <-
    sample_metrics$pct_ept_of_all_estimated_count[metric_index]
  field$pct_order_classified_estimated_count <-
    sample_metrics$pct_order_classified_estimated_count[metric_index]
  field$taxa_observed[!field$count_eligible] <- NA_integer_
  field$ept_taxa_observed[!field$count_eligible] <- NA_integer_
  field$hill_q1[!field$count_eligible] <- NA_real_
  field$hill_q2[!field$count_eligible] <- NA_real_
  field$pct_ept_of_all_estimated_count[!field$count_eligible] <- NA_real_
  field$pct_order_classified_estimated_count[!field$count_eligible] <- NA_real_

  opportunities <- if (nrow(field)) {
    field[c(
      "opportunity_id", "sample_key", "sampleID", "sampleCode", "siteID",
      "eventID", "collectDate", "aquaticSiteType", "habitatType", "samplerType",
      "namedLocation", "sampleNumber", "samplingImpractical", "stratum_key",
      "has_per_sample", "sampling_practical", "sampler_type_normalized",
      "nonstandard_id_hint", "grain_complete", "unstratifiable",
      "nonstandard_collection", "primary_stratum",
      "processing_unknown", "taxonomy_count_unavailable",
      "displayed_zero_percent_authoritative_estimate",
      "processing_count_status",
      "taxonomy_rows", "record_status", "count_issue", "density_issue",
      "benthicArea_m2", "total_estimated_count", "count_eligible",
      "density_eligible", "reported_zero_count", "sample_density_m2",
      "taxa_observed", "ept_taxa_observed", "hill_q1", "hill_q2",
      "pct_ept_of_all_estimated_count",
      "pct_order_classified_estimated_count"
    )]
  } else {
    inv_science_empty_opportunities()
  }
  opportunities <- opportunities[
    order(opportunities$siteID, opportunities$eventID,
          opportunities$aquaticSiteType, opportunities$habitatType,
          opportunities$samplerType, opportunities$collectDate,
          opportunities$opportunity_id), , drop = FALSE
  ]
  rownames(opportunities) <- NULL
  if (nrow(excluded_dna)) {
    excluded_dna <- excluded_dna[
      order(as.character(excluded_dna$siteID),
            as.character(excluded_dna$sampleID)), , drop = FALSE
    ]
    rownames(excluded_dna) <- NULL
  }
  event_strata <- inv_science_event_strata(opportunities)
  taxon_strata <- inv_science_taxon_strata(opportunities, collapsed)
  site_summary <- inv_science_site_summary(opportunities, taxon_strata)

  status_counts <- table(factor(
    opportunities$record_status,
    levels = INV_RECORD_STATUS_LEVELS
  ))
  unresolved_rows <- inv_science_blank(taxonomy$acceptedTaxonID)
  unresolved_ids <- unique(as.character(taxonomy$sampleID[unresolved_rows]))
  unresolved_with_counted_taxa <- vapply(unresolved_ids, function(sample_id) {
    rows <- as.character(taxonomy$sampleID) == sample_id &
      !inv_science_blank(taxonomy$acceptedTaxonID) &
      is.finite(inv_science_num(taxonomy$estimatedTotalCount))
    any(rows)
  }, logical(1))

  list(
    science_version = INV_SCIENCE_VERSION,
    opportunities = opportunities,
    event_strata = event_strata,
    taxon_strata = taxon_strata,
    site_summary = site_summary,
    metric_contract = inv_science_metric_contract(),
    excluded_metabarcoding_field_rows = excluded_dna,
    summary = list(
      opportunities = nrow(opportunities),
      primary_opportunities = sum(opportunities$primary_stratum),
      count_eligible_samples = sum(opportunities$count_eligible),
      density_eligible_samples = sum(opportunities$density_eligible),
      sites = length(unique(opportunities$siteID[
        opportunities$siteID != "(not recorded)"
      ])),
      events = length(unique(paste(opportunities$siteID,
                                   opportunities$eventID, sep = "\u241f")[
                                     opportunities$primary_stratum
                                   ])),
      strata = nrow(event_strata),
      taxonomy_rows_collapsed = nrow(collapsed),
      excluded_metabarcoding_rows = nrow(excluded_dna),
      processing_unknown_opportunities = sum(opportunities$processing_unknown),
      taxonomy_count_unavailable_opportunities = sum(
        opportunities$taxonomy_count_unavailable
      ),
      displayed_zero_percent_authoritative_estimate_opportunities = sum(
        opportunities$displayed_zero_percent_authoritative_estimate
      ),
      practical_processing_count_opportunities = sum(
        opportunities$sampling_practical
      ),
      processing_count_status_counts = stats::setNames(
        as.integer(practical_outcome_counts), names(practical_outcome_counts)
      ),
      unresolved_taxonomy_placeholder_rows = sum(unresolved_rows),
      unresolved_taxonomy_placeholder_samples = length(unresolved_ids),
      placeholder_samples_with_other_counted_taxa = sum(
        unresolved_with_counted_taxa
      ),
      placeholder_only_samples = sum(!unresolved_with_counted_taxa),
      status_counts = stats::setNames(as.integer(status_counts),
                                      names(status_counts))
    )
  )
}
