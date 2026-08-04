#!/usr/bin/env Rscript

source("scripts/inv_science_contract.R", local = TRUE)

checks <- 0L

expect_true <- function(value, label) {
  checks <<- checks + 1L
  if (!isTRUE(value)) stop(sprintf("Check failed: %s", label), call. = FALSE)
}

expect_equal <- function(actual, expected, label, tolerance = 1e-8) {
  checks <<- checks + 1L
  ok <- if (is.numeric(actual) || is.numeric(expected)) {
    length(actual) == length(expected) &&
      all(is.na(actual) == is.na(expected)) &&
      all(abs(actual[!is.na(actual)] - expected[!is.na(expected)]) <= tolerance)
  } else {
    identical(actual, expected)
  }
  if (!isTRUE(ok)) {
    stop(sprintf("Check failed: %s\nactual: %s\nexpected: %s", label,
                 paste(actual, collapse = ", "), paste(expected, collapse = ", ")),
         call. = FALSE)
  }
}

expect_error <- function(expr, pattern) {
  checks <<- checks + 1L
  message_text <- tryCatch({ force(expr); NA_character_ },
                           error = function(error) conditionMessage(error))
  if (is.na(message_text) || !grepl(pattern, message_text, perl = TRUE)) {
    stop(sprintf("Expected error /%s/; got: %s", pattern, message_text),
         call. = FALSE)
  }
}

fixture_science_source <- function() {
  field <- data.frame(
    namedLocation = rep("SYCA.AOS.reach", 7),
    eventID = c(rep("SYCA.2024.1", 6), "SYCA.2024.2"),
    sampleID = c("SYCA.S1", "SYCA.S2", "SYCA.S3", NA, "SYCA.S5",
                 "SYCA.S6.DNA", "SYCA.S7"),
    sampleCode = c("S1", "S2", "S3", NA, "S5", "DNA", "S7"),
    habitatType = c("riffle", "riffle", "pool", "riffle", "riffle",
                    "riffle", "riffle"),
    samplerType = c("Surber", "Surber", "core", "Surber", "Surber",
                    "Surber", "Surber"),
    sampleNumber = as.character(seq_len(7)),
    siteID = "SYCA",
    collectDate = c(rep("2024-03-01", 6), "2024-09-01"),
    aquaticSiteType = "wadeable stream",
    benthicArea = c(0.1, 0.2, 0.1, NA, 0.1, 0.1, 0.1),
    samplingImpractical = c("OK", "OK", "OK", "location dry", "OK", "OK", "OK"),
    stringsAsFactors = FALSE
  )
  per_sample <- data.frame(
    sampleID = c("SYCA.S1", "SYCA.S2", "SYCA.S3", "SYCA.S5", "SYCA.S7"),
    sampleCode = c("S1", "S2", "S3", "S5", "S7"),
    stringsAsFactors = FALSE
  )
  taxonomy <- data.frame(
    uid = sprintf("30000000-0000-4000-8000-%012d", 1:6),
    sampleID = c("SYCA.S1", "SYCA.S1", "SYCA.S1", "SYCA.S2", "SYCA.S3", "SYCA.S7"),
    sampleCode = c("S1", "S1", "S1", "S2", "S3", "S7"),
    acceptedTaxonID = c("A", "A", "B", "A", "C", "D"),
    scientificName = c("Alpha", "Alpha", "Beta", "Alpha", "Gamma", "Delta"),
    taxonRank = c("genus", "genus", "family", "genus", "species", "genus"),
    order = c("Ephemeroptera", "Ephemeroptera", "Diptera",
              "Ephemeroptera", "Coleoptera", "Diptera"),
    family = c("Baetidae", "Baetidae", "Betaidae", "Baetidae", "Gammaidae", "Deltaidae"),
    class = "Insecta", subclass = NA_character_,
    individualCount = c(4, 6, 10, 20, 5, 0),
    estimatedTotalCount = c(4, 6, 10, 20, 5, 0),
    subsamplePercent = 100,
    stringsAsFactors = FALSE
  )
  list(inv_fieldData = field, inv_persample = per_sample,
       inv_taxonomyProcessed = taxonomy)
}

fixture_grain_source <- function() {
  dimensions <- data.frame(
    sampleID = paste0("GRAIN.S", 1:5), sampleCode = paste0("G", 1:5),
    siteID = c("SYCA", "ARIK", "SYCA", "SYCA", "SYCA"),
    eventID = "shared-event",
    aquaticSiteType = c("stream", "stream", "river", "stream", "stream"),
    habitatType = c("riffle", "riffle", "riffle", "pool", "riffle"),
    samplerType = c("Surber", "Surber", "Surber", "Surber", "core"),
    stringsAsFactors = FALSE
  )
  field <- data.frame(
    namedLocation = paste0(dimensions$siteID, ".AOS.reach"),
    eventID = dimensions$eventID, sampleID = dimensions$sampleID,
    sampleCode = dimensions$sampleCode, habitatType = dimensions$habitatType,
    samplerType = dimensions$samplerType, sampleNumber = as.character(1:5),
    siteID = dimensions$siteID, collectDate = "2024-04-01",
    aquaticSiteType = dimensions$aquaticSiteType, benthicArea = 0.1,
    samplingImpractical = "OK", stringsAsFactors = FALSE
  )
  per_sample <- dimensions[c("sampleID", "sampleCode")]
  taxonomy <- data.frame(
    uid = sprintf("40000000-0000-4000-8000-%012d", 1:5),
    sampleID = dimensions$sampleID, sampleCode = dimensions$sampleCode,
    acceptedTaxonID = "A", scientificName = "Alpha", taxonRank = "genus",
    order = "Ephemeroptera", family = "Baetidae", class = "Insecta",
    subclass = NA_character_, individualCount = 1, estimatedTotalCount = 1,
    subsamplePercent = 100, stringsAsFactors = FALSE
  )
  list(inv_fieldData = field, inv_persample = per_sample,
       inv_taxonomyProcessed = taxonomy)
}

all_contract_names <- function(x) {
  own <- names(x)
  if (is.null(own)) own <- character()
  if (!is.list(x)) return(own)
  unique(c(own, unlist(lapply(x, all_contract_names), use.names = FALSE)))
}

result <- build_inv_science_contract(fixture_science_source())
opp <- result$opportunities

expect_equal(result$summary$opportunities, 6L,
             "metabarcoding field row is excluded from collection opportunities")
expect_equal(result$summary$excluded_metabarcoding_rows, 1L,
             "metabarcoding exclusion is auditable")
expect_equal(opp$record_status[opp$sampleID %in% "SYCA.S5"],
             "processed_no_taxonomy",
             "processed sample without taxonomy is explicit unknown")
expect_true(!opp$density_eligible[opp$sampleID %in% "SYCA.S5"],
            "processed-no-taxonomy is not silently zero-filled")
expect_true(!opp$reported_zero_count[opp$sampleID %in% "SYCA.S5"],
            "taxonomy absence is not an explicit reported zero")

masked_unstratifiable <- fixture_science_source()
masked_unstratifiable$inv_fieldData$habitatType[
  masked_unstratifiable$inv_fieldData$sampleID %in% "SYCA.S5"
] <- NA_character_
masked_unstratifiable_result <- build_inv_science_contract(
  masked_unstratifiable
)
masked_unstratifiable_row <- masked_unstratifiable_result$opportunities[
  masked_unstratifiable_result$opportunities$sampleID %in% "SYCA.S5",
  , drop = FALSE
]
expect_true(
  nrow(masked_unstratifiable_row) == 1L &&
    masked_unstratifiable_row$processing_count_status ==
      "processed_no_taxonomy" &&
    masked_unstratifiable_row$record_status == "unstratifiable" &&
    identical(
      masked_unstratifiable_result$site_summary$n_processed_no_taxonomy,
      1L
    ),
  paste(
    "processed-without-taxonomy outcome survives unstratifiable primary-status",
    "precedence in the site support summary"
  )
)

masked_nonstandard <- fixture_science_source()
masked_nonstandard$inv_fieldData$sampleID[
  masked_nonstandard$inv_fieldData$sampleID %in% "SYCA.S5"
] <- "SYCA.20240301.GRAB.5"
masked_nonstandard$inv_fieldData$sampleCode[
  masked_nonstandard$inv_fieldData$sampleCode %in% "S5"
] <- "GRAB5"
masked_nonstandard$inv_fieldData$samplerType[
  masked_nonstandard$inv_fieldData$sampleID %in% "SYCA.20240301.GRAB.5"
] <- "GRAB"
masked_nonstandard$inv_persample$sampleID[
  masked_nonstandard$inv_persample$sampleID %in% "SYCA.S5"
] <- "SYCA.20240301.GRAB.5"
masked_nonstandard$inv_persample$sampleCode[
  masked_nonstandard$inv_persample$sampleCode %in% "S5"
] <- "GRAB5"
masked_nonstandard_result <- build_inv_science_contract(masked_nonstandard)
masked_nonstandard_row <- masked_nonstandard_result$opportunities[
  masked_nonstandard_result$opportunities$sampleID %in%
    "SYCA.20240301.GRAB.5", , drop = FALSE
]
expect_true(
  nrow(masked_nonstandard_row) == 1L &&
    masked_nonstandard_row$processing_count_status ==
      "processed_no_taxonomy" &&
    masked_nonstandard_row$record_status == "nonstandard_collection" &&
    identical(
      masked_nonstandard_result$site_summary$n_processed_no_taxonomy,
      1L
    ),
  paste(
    "processed-without-taxonomy outcome survives nonstandard-collection",
    "primary-status precedence in the site support summary"
  )
)

expect_equal(opp$record_status[opp$sampleID %in% "SYCA.S7"],
             "reported_zero_count", "explicit zero count remains distinct")
expect_true(opp$reported_zero_count[opp$sampleID %in% "SYCA.S7"],
            "explicit published zero count is auditable without calling absence verified")
expect_equal(sum(opp$record_status == "sampling_impractical"), 1L,
             "impractical field opportunity is retained")
expect_true(
  sum(result$summary$processing_count_status_counts) ==
      result$summary$practical_processing_count_opportunities &&
    result$summary$practical_processing_count_opportunities ==
      sum(opp$sampling_practical) &&
    all(!is.na(opp$processing_count_status[opp$sampling_practical])) &&
    all(is.na(opp$processing_count_status[!opp$sampling_practical])),
  paste(
    "every practical field opportunity has one mutually exclusive",
    "processing/count outcome"
  )
)

riffle <- result$event_strata[
  result$event_strata$eventID == "SYCA.2024.1" &
    result$event_strata$habitatType == "riffle", , drop = FALSE
]
expect_equal(nrow(riffle), 1L, "exact habitat/sampler stratum is unique")
expect_equal(riffle$n_opportunities, 4L,
             "stratum denominator includes impractical and unknown outcomes")
expect_equal(riffle$n_density_samples, 2L,
             "numeric denominator includes only verified quantified samples")
expect_equal(riffle$n_count_samples, 2L,
             "count-metric denominator is explicit and independent")
expect_equal(riffle$mean_sample_density_m2, 150,
             "event density is arithmetic mean of sample densities")
expect_true(abs(riffle$mean_sample_density_m2 - (40 / 0.3)) > 1,
            "event density is not pooled-count/pooled-area weighting")

expect_equal(nrow(result$event_strata[result$event_strata$eventID == "SYCA.2024.1", ]),
             2L, "mixed habitat and sampler records are never modal-collapsed")

taxa <- result$taxon_strata
tax_a <- taxa[taxa$eventID == "SYCA.2024.1" & taxa$habitatType == "riffle" &
                taxa$taxon_key == "A", , drop = FALSE]
tax_b <- taxa[taxa$eventID == "SYCA.2024.1" & taxa$habitatType == "riffle" &
                taxa$taxon_key == "B", , drop = FALSE]
expect_equal(tax_a$total_estimated_count, 30,
             "repeated size-class rows collapse before sample density")
expect_equal(tax_a$mean_sample_density_m2, 100,
             "taxon A density is zero-fill compatible")
expect_equal(tax_b$n_count_eligible_samples, 2L,
             "taxon support denominator is the full count-eligible stratum")
expect_equal(tax_b$n_density_eligible_samples, 2L,
             "taxon density denominator is explicit")
expect_equal(tax_b$n_samples_present, 1L,
             "taxon presence numerator counts positive samples")
expect_equal(tax_b$support_pct, 50,
             "taxon support exposes one-of-two samples")
expect_equal(tax_b$mean_sample_density_m2, 50,
             "taxon mean density zero-fills verified eligible samples")
expect_equal(tax_b$taxonRank, "family", "taxonomic rank is retained")
expect_true(tax_b$mean_sample_density_m2 < 100,
            "presence-conditioned mean inflation is prevented")

expect_true(!any(grepl("chao|raref", all_contract_names(result), ignore.case = TRUE)),
            "unsafe richness estimators are absent recursively")
expect_true(all(result$metric_contract$boundary != ""),
            "every exposed metric has an interpretation boundary")
expected_metric_columns <- list(
  opportunities = c(
    "total_estimated_count", "sample_density_m2", "taxa_observed",
    "ept_taxa_observed", "hill_q1", "hill_q2",
    "pct_ept_of_all_estimated_count",
    "pct_order_classified_estimated_count"
  ),
  event_strata = grep(
    "^(mean|median|sd|se)_", names(result$event_strata), value = TRUE
  ),
  taxon_strata = c(
    "mean_sample_density_m2", "median_sample_density_m2", "support_pct",
    "total_estimated_count"
  )
)
expected_metric_keys <- unlist(lapply(
  names(expected_metric_columns),
  function(table_name) paste(table_name, expected_metric_columns[[table_name]], sep = "::")
), use.names = FALSE)
actual_metric_keys <- paste(result$metric_contract$table,
                            result$metric_contract$column, sep = "::")
expect_true(all(c("metric", "table", "column", "grain", "denominator", "boundary") %in%
                  names(result$metric_contract)),
            "metric contract declares its source table and exact output column")
expect_true(!anyDuplicated(actual_metric_keys) &&
              !anyDuplicated(result$metric_contract$metric),
            "metric contract identities are unambiguous")
expect_true(setequal(actual_metric_keys, expected_metric_keys),
            "metric contract covers every exposed analytical metric exactly")

bad <- fixture_science_source()
bad$inv_taxonomyProcessed$taxonRank[2] <- "species"
expect_error(build_inv_science_contract(bad), "Conflicting taxonRank")

bad <- fixture_science_source()
bad$inv_taxonomyProcessed$taxonRank[4] <- "family"
bad$inv_taxonomyProcessed$scientificName[4] <- "Alpha family label"
expect_error(build_inv_science_contract(bad),
             "Conflicting (scientificName|taxonRank) for taxon_key A")

bad <- fixture_science_source()
bad$inv_taxonomyProcessed$acceptedTaxonID[3] <- NA_character_
expect_error(build_inv_science_contract(bad),
             "Unresolved taxonomy placeholder has a reported")

bad <- fixture_science_source()
bad$inv_taxonomyProcessed$estimatedTotalCount[1] <- 2
bad_result <- build_inv_science_contract(bad)
bad_s1 <- bad_result$opportunities[bad_result$opportunities$sampleID %in% "SYCA.S1", ]
expect_equal(bad_s1$record_status, "count_unavailable",
             "estimated count below individual count is quarantined")
expect_true(!bad_s1$density_eligible,
            "quarantined count never enters a partial sample total")
expect_true(!bad_s1$count_eligible,
            "quarantined count never enters occurrence or count metrics")

bad <- fixture_science_source()
bad$inv_taxonomyProcessed$estimatedTotalCount[
  bad$inv_taxonomyProcessed$sampleID %in% "SYCA.S2"
] <- NA_real_
bad_result <- build_inv_science_contract(bad)
bad_s2 <- bad_result$opportunities[
  bad_result$opportunities$sampleID %in% "SYCA.S2", , drop = FALSE
]
expect_true(
  identical(bad_s2$record_status, "count_unavailable") &&
    grepl("estimated_count_unavailable", bad_s2$count_issue) &&
    !bad_s2$count_eligible && !bad_s2$density_eligible,
  "missing estimatedTotalCount never falls back to individualCount"
)

bad <- fixture_science_source()
bad$inv_taxonomyProcessed$estimatedTotalCount[
  bad$inv_taxonomyProcessed$sampleID %in% "SYCA.S7"
] <- NA_real_
bad_result <- build_inv_science_contract(bad)
bad_s7 <- bad_result$opportunities[
  bad_result$opportunities$sampleID %in% "SYCA.S7", , drop = FALSE
]
expect_true(
  identical(bad_s7$record_status, "count_unavailable") &&
    !bad_s7$count_eligible && !bad_s7$reported_zero_count &&
    is.na(bad_s7$total_estimated_count),
  paste(
    "missing estimatedTotalCount with individualCount zero and 100-percent",
    "subsample remains unavailable, never a reported zero"
  )
)

bad <- fixture_science_source()
bad$inv_fieldData$benthicArea[bad$inv_fieldData$sampleID %in% "SYCA.S2"] <- 0
bad_result <- build_inv_science_contract(bad)
bad_s2 <- bad_result$opportunities[bad_result$opportunities$sampleID %in% "SYCA.S2", ]
expect_equal(bad_s2$record_status, "area_unavailable",
             "nonpositive effort denominator is retained but excluded")
expect_true(!bad_s2$density_eligible,
            "invalid benthic area cannot produce density")
expect_true(bad_s2$count_eligible,
            "valid counts remain usable when benthic area is unavailable")
expect_equal(bad_s2$taxa_observed, 1L,
             "area failure does not erase recorded count-based taxa")

bad <- fixture_science_source()
bad$inv_fieldData$benthicArea[bad$inv_fieldData$sampleID %in% "SYCA.S7"] <- 0
bad_result <- build_inv_science_contract(bad)
bad_s7 <- bad_result$opportunities[bad_result$opportunities$sampleID %in% "SYCA.S7", ]
expect_equal(bad_s7$record_status, "area_unavailable",
             "zero count and missing area retain the area status")
expect_true(bad_s7$count_eligible && bad_s7$reported_zero_count,
            "reported zero count is retained independently of density eligibility")
expect_true(!bad_s7$density_eligible,
            "reported zero cannot manufacture a density without area")

mixed_composition <- fixture_science_source()
mixed_composition$inv_fieldData$eventID[
  mixed_composition$inv_fieldData$sampleID %in% "SYCA.S7"
] <- "SYCA.2024.1"
mixed_composition$inv_fieldData$collectDate[
  mixed_composition$inv_fieldData$sampleID %in% "SYCA.S7"
] <- "2024-03-01"
mixed_result <- build_inv_science_contract(mixed_composition)
mixed_riffle <- mixed_result$event_strata[
  mixed_result$event_strata$eventID == "SYCA.2024.1" &
    mixed_result$event_strata$habitatType == "riffle", ]
expect_equal(mixed_riffle$n_count_samples, 3L,
             "reported-zero sample remains in count-metric denominator")
expect_equal(mixed_riffle$n_composition_samples, 2L,
             "composition denominator is positive-total count-eligible samples")
expect_equal(mixed_riffle$mean_sample_hill_q1, 1.5,
             "Hill mean uses the explicitly reported composition denominator")
expect_equal(mixed_riffle$mean_sample_pct_ept_of_all_estimated_count, 75,
             "EPT share mean uses the explicitly reported composition denominator")

grab <- fixture_science_source()
grab$inv_fieldData$sampleID[grab$inv_fieldData$sampleID %in% "SYCA.S1"] <-
  "SYCA.20240301.GRAB.1"
grab$inv_fieldData$sampleCode[grab$inv_fieldData$sampleCode %in% "S1"] <- "GRAB1"
grab$inv_fieldData$samplerType[
  grab$inv_fieldData$sampleID %in% "SYCA.20240301.GRAB.1"
] <- "GRAB"
grab$inv_persample$sampleID[grab$inv_persample$sampleID %in% "SYCA.S1"] <-
  "SYCA.20240301.GRAB.1"
grab$inv_persample$sampleCode[grab$inv_persample$sampleCode %in% "S1"] <- "GRAB1"
grab$inv_taxonomyProcessed$sampleID[
  grab$inv_taxonomyProcessed$sampleID %in% "SYCA.S1"
] <- "SYCA.20240301.GRAB.1"
grab$inv_taxonomyProcessed$sampleCode[
  grab$inv_taxonomyProcessed$sampleCode %in% "S1"
] <- "GRAB1"
grab_result <- build_inv_science_contract(grab)
grab_row <- grab_result$opportunities[
  grab_result$opportunities$sampleID %in% "SYCA.20240301.GRAB.1", ]
expect_equal(grab_row$record_status, "nonstandard_collection",
             "GRAB record is retained but identified as nonstandard")
expect_true(!grab_row$primary_stratum && !grab_row$count_eligible &&
              !grab_row$density_eligible,
            "GRAB record cannot enter primary quantitative strata")
grab_riffle <- grab_result$event_strata[
  grab_result$event_strata$eventID == "SYCA.2024.1" &
    grab_result$event_strata$habitatType == "riffle", ]
expect_equal(grab_riffle$n_density_samples, 1L,
             "GRAB record is absent from the primary density denominator")

expect_true(identical(
  inv_science_nonstandard_id_hint(c(
    "SYCA.20240301.GRAB.1", "SYCA.20240301.BRYOZOAN.1",
    "TOOK.20240726.MACROALGAE2.P9", "SYCA.S1",
    "NOTAGRABSTANDARD", "SYCA.20240301.GRABBED.1",
    "TOOK.20240726.MACROALGAEX.P9"
  )),
  c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE)
), paste0(
  "complete GRAB/BRYOZOAN tokens and numbered MACROALGAE tokens are recognized ",
  "without substring false positives"
))

macroalgae <- grab
for (table_name in c("inv_fieldData", "inv_persample", "inv_taxonomyProcessed")) {
  macroalgae[[table_name]]$sampleID[
    macroalgae[[table_name]]$sampleID %in% "SYCA.20240301.GRAB.1"
  ] <- "TOOK.20240726.MACROALGAE2.P9"
}
macroalgae_result <- build_inv_science_contract(macroalgae)
macroalgae_row <- macroalgae_result$opportunities[
  macroalgae_result$opportunities$sampleID %in% "TOOK.20240726.MACROALGAE2.P9", ]
expect_true(macroalgae_row$nonstandard_collection &&
              macroalgae_row$record_status == "nonstandard_collection" &&
              !macroalgae_row$primary_stratum,
            "documented grab sampler catches MACROALGAE collections missed by the old ID regex")

mismatch <- macroalgae
mismatch$inv_fieldData$samplerType[
  mismatch$inv_fieldData$sampleID %in% "TOOK.20240726.MACROALGAE2.P9"
] <- "Surber"
expect_error(build_inv_science_contract(mismatch), "nonstandard identity token")

unknown_sampler <- fixture_science_source()
unknown_sampler$inv_fieldData$samplerType[
  unknown_sampler$inv_fieldData$sampleID %in% "SYCA.S1"
] <- "mystery net"
expect_error(build_inv_science_contract(unknown_sampler),
             "unreviewed RELEASE-2026 samplerType")

for (grain_field in c(
  "siteID", "eventID", "aquaticSiteType", "habitatType", "samplerType"
)) {
  incomplete <- fixture_science_source()
  incomplete$inv_fieldData[[grain_field]][
    incomplete$inv_fieldData$sampleID %in% "SYCA.S1"
  ] <- NA_character_
  incomplete_result <- build_inv_science_contract(incomplete)
  incomplete_row <- incomplete_result$opportunities[
    incomplete_result$opportunities$sampleID %in% "SYCA.S1", ]
  expect_true(incomplete_row$record_status == "unstratifiable" &&
                incomplete_row$unstratifiable && !incomplete_row$grain_complete &&
                !incomplete_row$primary_stratum && !incomplete_row$count_eligible &&
                !incomplete_row$density_eligible,
              sprintf("missing %s is retained but cannot enter metrics", grain_field))
}

expect_equal(
  INV_RECORD_STATUS_PRECEDENCE[1:3],
  c("unstratifiable", "sampling_impractical", "nonstandard_collection"),
  "record-status gate precedence is explicit and release locked"
)
for (grain_field in c("habitatType", "samplerType")) {
  overlap <- fixture_science_source()
  overlap_row <- overlap$inv_fieldData$sampleNumber == "4"
  overlap$inv_fieldData[[grain_field]][overlap_row] <- NA_character_
  overlap_result <- build_inv_science_contract(overlap)
  opportunity <- overlap_result$opportunities[
    overlap_result$opportunities$sampleNumber == "4", , drop = FALSE
  ]
  site <- overlap_result$site_summary[
    overlap_result$site_summary$siteID == "SYCA", , drop = FALSE
  ]
  expect_true(
    nrow(opportunity) == 1L && !opportunity$sampling_practical &&
      opportunity$unstratifiable &&
      identical(opportunity$record_status, "unstratifiable") &&
      identical(site$n_sampling_impractical, 1L) &&
      identical(site$n_unstratifiable, 1L) &&
      identical(unname(overlap_result$summary$status_counts[[
        "unstratifiable"
      ]]), 1L) &&
      identical(unname(overlap_result$summary$status_counts[[
        "sampling_impractical"
      ]]), 0L),
    sprintf(
      "impractical plus missing %s retains both marginal flags under one status",
      grain_field
    )
  )
}

missing_site <- fixture_science_source()
missing_site$inv_fieldData$siteID[
  missing_site$inv_fieldData$sampleID %in% "SYCA.S1"
] <- NA_character_
missing_site_result <- build_inv_science_contract(missing_site)
expect_equal(missing_site_result$summary$sites, 1L,
             "missing site identity is not counted as a real site")
expect_true(!"(not recorded)" %in% missing_site_result$site_summary$siteID &&
              identical(missing_site_result$site_summary$siteID, "SYCA"),
            "unattributed opportunities stay auditable without creating a pseudo-site roster row")

unknown <- fixture_science_source()
unknown$inv_taxonomyProcessed$order[3] <- NA_character_
unknown_result <- build_inv_science_contract(unknown)
unknown_riffle <- unknown_result$event_strata[
  unknown_result$event_strata$eventID == "SYCA.2024.1" &
    unknown_result$event_strata$habitatType == "riffle", ]
expect_equal(unknown_riffle$mean_sample_pct_ept_of_all_estimated_count, 75,
             "EPT share denominator includes unknown-order positive counts")
expect_equal(unknown_riffle$mean_sample_pct_order_classified_estimated_count, 75,
             "order-classification support is emitted beside EPT share")

lowercase_ept <- fixture_science_source()
lowercase_ept$inv_taxonomyProcessed$order[
  lowercase_ept$inv_taxonomyProcessed$order %in% "Ephemeroptera"
] <- "ephemeroptera"
lowercase_ept_result <- build_inv_science_contract(lowercase_ept)
lowercase_riffle <- lowercase_ept_result$event_strata[
  lowercase_ept_result$event_strata$eventID == "SYCA.2024.1" &
    lowercase_ept_result$event_strata$habitatType == "riffle", ]
expect_equal(lowercase_riffle$mean_sample_pct_ept_of_all_estimated_count, 75,
             "EPT classification is robust to harmless source-label casing")
expect_equal(lowercase_riffle$mean_sample_pct_order_classified_estimated_count, 100,
             "case normalization does not alter recorded-order support")
expect_true(all(lowercase_ept_result$taxon_strata$is_ept[
  lowercase_ept_result$taxon_strata$taxon_key %in% "A"
]), "canonical EPT taxon metadata uses case-normalized classification")

partial_metadata <- fixture_science_source()
partial_a <- partial_metadata$inv_taxonomyProcessed$sampleID %in% "SYCA.S1" &
  partial_metadata$inv_taxonomyProcessed$acceptedTaxonID %in% "A"
partial_metadata$inv_taxonomyProcessed$scientificName[partial_a] <- NA_character_
partial_metadata$inv_taxonomyProcessed$taxonRank[partial_a] <- NA_character_
partial_metadata$inv_taxonomyProcessed$order[partial_a] <- NA_character_
partial_metadata$inv_taxonomyProcessed$family[partial_a] <- NA_character_
partial_result <- build_inv_science_contract(partial_metadata)
partial_taxon_a <- partial_result$taxon_strata[
  partial_result$taxon_strata$taxon_key == "A", ]
expect_true(all(partial_taxon_a$scientificName == "Alpha") &&
              all(partial_taxon_a$taxonRank == "genus") &&
              all(partial_taxon_a$order == "Ephemeroptera") &&
              all(partial_taxon_a$family == "Baetidae") &&
              all(partial_taxon_a$order_classified) && all(partial_taxon_a$is_ept),
            "taxon strata use canonical nonblank metadata across samples")
partial_s1 <- partial_result$opportunities[
  partial_result$opportunities$sampleID %in% "SYCA.S1", ]
expect_equal(partial_s1$pct_order_classified_estimated_count, 50,
             "canonical taxon metadata does not impute sample-level classification support")

grain <- build_inv_science_contract(fixture_grain_source())
expect_equal(nrow(grain$event_strata), 5L,
             "site, water type, habitat, and sampler each independently split strata")
expect_true(all(grain$event_strata$n_opportunities == 1L),
            "no exact-grain boundary is accidentally pooled")
expect_true(all(grain$taxon_strata$n_count_eligible_samples == 1L),
            "taxon zero-fill never crosses an exact-grain boundary")

shuffled <- fixture_science_source()
shuffled$inv_fieldData <- shuffled$inv_fieldData[nrow(shuffled$inv_fieldData):1, ]
shuffled$inv_persample <- shuffled$inv_persample[nrow(shuffled$inv_persample):1, ]
shuffled$inv_taxonomyProcessed <-
  shuffled$inv_taxonomyProcessed[nrow(shuffled$inv_taxonomyProcessed):1, ]
shuffled_result <- build_inv_science_contract(shuffled)
for (table_name in c("opportunities", "event_strata", "taxon_strata", "site_summary")) {
  expect_true(identical(result[[table_name]], shuffled_result[[table_name]]),
              sprintf("%s output is canonical under input row reordering", table_name))
}

empty <- fixture_science_source()
empty$inv_taxonomyProcessed <- empty$inv_taxonomyProcessed[FALSE, , drop = FALSE]
empty_result <- build_inv_science_contract(empty)
expect_true(nrow(empty_result$taxon_strata) == 0L &&
              identical(names(empty_result$taxon_strata),
                        names(inv_science_empty_taxon_strata())),
            "empty taxon result preserves a typed stable schema")

fully_empty <- fixture_science_source()
fully_empty$inv_fieldData <- fully_empty$inv_fieldData[FALSE, , drop = FALSE]
fully_empty$inv_persample <- fully_empty$inv_persample[FALSE, , drop = FALSE]
fully_empty$inv_taxonomyProcessed <-
  fully_empty$inv_taxonomyProcessed[FALSE, , drop = FALSE]
fully_empty_result <- build_inv_science_contract(fully_empty)
expect_true(identical(fully_empty_result$opportunities,
                      inv_science_empty_opportunities()),
            "fully empty opportunity output has a stable typed schema")
expect_true(identical(
  fully_empty_result$event_strata,
  inv_science_event_strata(inv_science_empty_opportunities())
), "fully empty event-stratum output has a stable typed schema")
expect_true(identical(fully_empty_result$taxon_strata,
                      inv_science_empty_taxon_strata()),
            "fully empty taxon-stratum output has a stable typed schema")
expect_true(identical(fully_empty_result$site_summary,
                      inv_science_empty_site_summary()),
            "fully empty site-summary output has a stable typed schema")
expect_true(fully_empty_result$summary$opportunities == 0L &&
              fully_empty_result$summary$sites == 0L &&
              all(fully_empty_result$summary$status_counts == 0L),
            "fully empty summary counts remain typed zeros")

dna_only <- fixture_science_source()
dna_only$inv_fieldData <- dna_only$inv_fieldData[
  grepl("[.]DNA$", dna_only$inv_fieldData$sampleID), , drop = FALSE
]
dna_only$inv_persample <- dna_only$inv_persample[FALSE, , drop = FALSE]
dna_only$inv_taxonomyProcessed <-
  dna_only$inv_taxonomyProcessed[FALSE, , drop = FALSE]
dna_only_result <- build_inv_science_contract(dna_only)
expect_true(identical(dna_only_result$opportunities,
                      inv_science_empty_opportunities()) &&
              dna_only_result$summary$excluded_metabarcoding_rows == 1L,
            "an all-metabarcoding slice yields typed empty community outputs")

bad <- fixture_science_source()
bad$inv_taxonomyProcessed$estimatedTotalCount[1] <- NA_real_
bad$inv_taxonomyProcessed$subsamplePercent[1] <- 150
bad_result <- build_inv_science_contract(bad)
expect_equal(bad_result$opportunities$record_status[
  bad_result$opportunities$sampleID %in% "SYCA.S1"
], "count_unavailable", "impossible subsample percentage is quarantined")

displayed_zero <- fixture_science_source()
displayed_rows <- displayed_zero$inv_taxonomyProcessed$sampleID == "SYCA.S1"
displayed_zero$inv_taxonomyProcessed$subsamplePercent[displayed_rows] <- 0
displayed_result <- build_inv_science_contract(displayed_zero)
displayed_s1 <- displayed_result$opportunities[
  displayed_result$opportunities$sampleID %in% "SYCA.S1", , drop = FALSE
]
expect_true(
  nrow(displayed_s1) == 1L && displayed_s1$count_eligible &&
    displayed_s1$density_eligible &&
    displayed_s1$displayed_zero_percent_authoritative_estimate &&
    displayed_s1$processing_count_status == "taxonomy_count_available" &&
    identical(
      displayed_result$summary$
        displayed_zero_percent_authoritative_estimate_opportunities,
      1L
    ),
  paste(
    "integer-displayed zero subsample percent retains finite published",
    "estimatedTotalCount as the authoritative count"
  )
)
displayed_event <- displayed_result$event_strata[
  displayed_result$event_strata$eventID == "SYCA.2024.1" &
    displayed_result$event_strata$habitatType == "riffle", , drop = FALSE
]
displayed_site <- displayed_result$site_summary[
  displayed_result$site_summary$siteID == "SYCA", , drop = FALSE
]
expect_true(
  displayed_event$n_displayed_zero_percent_authoritative_estimate == 1L &&
    displayed_site$n_displayed_zero_percent_authoritative_estimate == 1L,
  "displayed-zero authoritative-estimate support reconciles at event and site"
)
negative_percent <- fixture_science_source()
negative_percent$inv_taxonomyProcessed$subsamplePercent[1L] <- -0.5
negative_result <- build_inv_science_contract(negative_percent)
expect_true(
  negative_result$opportunities$record_status[
    negative_result$opportunities$sampleID %in% "SYCA.S1"
  ] == "count_unavailable" &&
    !negative_result$opportunities$
      displayed_zero_percent_authoritative_estimate[
        negative_result$opportunities$sampleID %in% "SYCA.S1"
      ],
  "negative subsample percent remains invalid and is never authoritative"
)

bad <- fixture_science_source()
bad$inv_taxonomyProcessed$individualCount[1] <- Inf
bad_result <- build_inv_science_contract(bad)
expect_equal(bad_result$opportunities$record_status[
  bad_result$opportunities$sampleID %in% "SYCA.S1"
], "count_unavailable", "nonfinite auxiliary count is quarantined")

bad <- fixture_science_source()
bad$inv_taxonomyProcessed$estimatedTotalCount[1:2] <- 1e308
bad$inv_taxonomyProcessed$individualCount[1:2] <- 1e308
bad_result <- build_inv_science_contract(bad)
bad_s1 <- bad_result$opportunities[bad_result$opportunities$sampleID %in% "SYCA.S1", ]
expect_equal(bad_s1$record_status, "count_unavailable",
             "nonfinite within-taxon collapsed total is quarantined")
expect_true(grepl("nonfinite_collapsed_count", bad_s1$count_issue) &&
              !bad_s1$count_eligible && !bad_s1$density_eligible,
            "collapsed overflow cannot enter count or density metrics")

bad <- fixture_science_source()
bad$inv_taxonomyProcessed$estimatedTotalCount[1:2] <- c(4e307, 6e307)
bad$inv_taxonomyProcessed$individualCount[1:2] <- c(4e307, 6e307)
bad$inv_taxonomyProcessed$estimatedTotalCount[3] <- 1e308
bad$inv_taxonomyProcessed$individualCount[3] <- 1e308
bad_result <- build_inv_science_contract(bad)
bad_s1 <- bad_result$opportunities[bad_result$opportunities$sampleID %in% "SYCA.S1", ]
expect_equal(bad_s1$record_status, "count_unavailable",
             "nonfinite across-taxon sample total is quarantined")
expect_true(grepl("nonfinite_sample_total", bad_s1$count_issue) &&
              !bad_s1$count_eligible,
            "sample-total overflow cannot enter count metrics")

bad <- fixture_science_source()
bad$inv_fieldData$benthicArea[bad$inv_fieldData$sampleID %in% "SYCA.S2"] <-
  .Machine$double.xmin
bad_result <- build_inv_science_contract(bad)
bad_s2 <- bad_result$opportunities[bad_result$opportunities$sampleID %in% "SYCA.S2", ]
expect_equal(bad_s2$record_status, "density_unavailable",
             "nonfinite derived density has an explicit retained status")
expect_true(bad_s2$count_eligible && !bad_s2$density_eligible &&
              grepl("nonfinite_sample_density", bad_s2$density_issue) &&
              is.na(bad_s2$sample_density_m2),
            "density overflow preserves valid counts but cannot enter density metrics")

stable_sd <- fixture_science_source()
stable_sd$inv_fieldData$benthicArea[
  stable_sd$inv_fieldData$sampleID %in% c("SYCA.S1", "SYCA.S2")
] <- 1
stable_sd$inv_taxonomyProcessed$estimatedTotalCount[1:4] <-
  c(5e307, 5e307, 0, 0)
stable_sd$inv_taxonomyProcessed$individualCount[1:4] <-
  c(5e307, 5e307, 0, 0)
stable_sd_result <- build_inv_science_contract(stable_sd)
stable_sd_riffle <- stable_sd_result$event_strata[
  stable_sd_result$event_strata$eventID == "SYCA.2024.1" &
    stable_sd_result$event_strata$habitatType == "riffle", ]
expect_true(is.finite(stable_sd_riffle$sd_sample_density_m2) &&
              abs(stable_sd_riffle$sd_sample_density_m2 /
                    (1e308 / sqrt(2)) - 1) < 1e-12,
            "finite extreme sample densities retain a finite scaled SD")
expect_true(is.finite(stable_sd_riffle$se_sample_density_m2) &&
              abs(stable_sd_riffle$se_sample_density_m2 / 5e307 - 1) < 1e-12,
            "finite extreme sample densities retain a finite scaled SE")

stable_taxon_density <- fixture_science_source()
stable_taxon_density$inv_fieldData$benthicArea[
  stable_taxon_density$inv_fieldData$sampleID %in% c("SYCA.S1", "SYCA.S2")
] <- 1e-308
stable_taxon_density$inv_taxonomyProcessed$estimatedTotalCount[1:4] <-
  c(0.4, 0.6, 0, 1)
stable_taxon_density$inv_taxonomyProcessed$individualCount[1:4] <-
  c(0.4, 0.6, 0, 1)
stable_taxon_result <- build_inv_science_contract(stable_taxon_density)
stable_taxon_a <- stable_taxon_result$taxon_strata[
  stable_taxon_result$taxon_strata$eventID == "SYCA.2024.1" &
    stable_taxon_result$taxon_strata$habitatType == "riffle" &
    stable_taxon_result$taxon_strata$taxon_key == "A", , drop = FALSE
]
expect_true(
  nrow(stable_taxon_a) == 1L &&
    is.finite(stable_taxon_a$mean_sample_density_m2) &&
    is.finite(stable_taxon_a$median_sample_density_m2) &&
    abs(stable_taxon_a$mean_sample_density_m2 / 1e308 - 1) < 1e-12 &&
    abs(stable_taxon_a$median_sample_density_m2 / 1e308 - 1) < 1e-12,
  paste(
    "two finite extreme taxon densities retain finite scaled mean and",
    "overflow-safe midpoint median"
  )
)

cross_sample_overflow <- fixture_science_source()
cross_sample_overflow$inv_fieldData$benthicArea[
  cross_sample_overflow$inv_fieldData$sampleID %in% c("SYCA.S1", "SYCA.S2")
] <- 1
cross_sample_overflow$inv_taxonomyProcessed$estimatedTotalCount[1:4] <-
  c(5e307, 5e307, 0, 1e308)
cross_sample_overflow$inv_taxonomyProcessed$individualCount[1:4] <-
  c(5e307, 5e307, 0, 1e308)
expect_error(
  build_inv_science_contract(cross_sample_overflow),
  "Nonfinite cross-sample taxon total.*taxon_key A"
)

bad <- fixture_science_source()
bad$inv_persample <- bad$inv_persample[!bad$inv_persample$sampleID %in% "SYCA.S2", ]
direct_result <- build_inv_science_contract(bad)
direct_s2 <- direct_result$opportunities[
  direct_result$opportunities$sampleID %in% "SYCA.S2", , drop = FALSE
]
expect_true(
  !direct_s2$has_per_sample && direct_s2$taxonomy_rows == 1L &&
    direct_s2$count_eligible && direct_s2$record_status == "quantified_community",
  "taxonomy may attach directly to a unique practical sampleID without per-sample"
)

processing_unknown <- fixture_science_source()
processing_unknown$inv_persample <- processing_unknown$inv_persample[
  processing_unknown$inv_persample$sampleID != "SYCA.S5", , drop = FALSE
]
processing_result <- build_inv_science_contract(processing_unknown)
processing_s5 <- processing_result$opportunities[
  processing_result$opportunities$sampleID %in% "SYCA.S5", , drop = FALSE
]
expect_true(
  processing_s5$processing_unknown && !processing_s5$has_per_sample &&
    processing_s5$taxonomy_rows == 0L &&
    processing_s5$record_status == "processing_unknown" &&
    !processing_s5$count_eligible && !processing_s5$reported_zero_count,
  "field opportunity without per-sample or taxonomy is processing-unknown, not zero"
)

placeholder_source <- fixture_science_source()
placeholder <- placeholder_source$inv_taxonomyProcessed[1, , drop = FALSE]
placeholder$uid <- "30000000-0000-4000-8000-000000000099"
placeholder$acceptedTaxonID <- NA_character_
placeholder$scientificName <- NA_character_
placeholder$taxonRank <- NA_character_
placeholder$order <- NA_character_
placeholder$family <- NA_character_
placeholder$individualCount <- NA_real_
placeholder$estimatedTotalCount <- NA_real_
placeholder$subsamplePercent <- 100
placeholder_only <- placeholder
placeholder_only$uid <- "30000000-0000-4000-8000-000000000098"
placeholder_only$sampleID <- "SYCA.S5"
placeholder_only$sampleCode <- "S5"
placeholder_source$inv_taxonomyProcessed <- rbind(
  placeholder_source$inv_taxonomyProcessed, placeholder, placeholder_only
)
placeholder_result <- build_inv_science_contract(placeholder_source)
placeholder_opportunities <- placeholder_result$opportunities[
  placeholder_result$opportunities$sampleID %in% c("SYCA.S1", "SYCA.S5"),
  , drop = FALSE
]
expect_true(
  all(placeholder_opportunities$taxonomy_count_unavailable) &&
    all(placeholder_opportunities$record_status == "count_unavailable") &&
    !any(placeholder_opportunities$count_eligible) &&
    !any(placeholder_opportunities$reported_zero_count) &&
    all(is.na(placeholder_opportunities$taxa_observed)) &&
    identical(
      placeholder_result$summary$placeholder_samples_with_other_counted_taxa,
      1L
    ) &&
    identical(placeholder_result$summary$placeholder_only_samples, 1L) &&
    !any(grepl("^unresolved-source-record:",
               placeholder_result$taxon_strata$taxon_key)),
  paste(
    "coexisting and placeholder-only unresolved rows remain count-unavailable",
    "and never enter zero, richness, EPT, or taxon-strata numerators"
  )
)

blank_code <- fixture_science_source()
for (table_name in c("inv_fieldData", "inv_persample",
                     "inv_taxonomyProcessed")) {
  blank_code[[table_name]]$sampleCode[
    blank_code[[table_name]]$sampleID %in% "SYCA.S2"
  ] <- NA_character_
}
blank_code_result <- build_inv_science_contract(blank_code)
expect_true(
  blank_code_result$opportunities$count_eligible[
    blank_code_result$opportunities$sampleID %in% "SYCA.S2"
  ],
  "optional blank sampleCode preserves sampleID-primary joins"
)

misaligned_code <- blank_code
misaligned_code$inv_taxonomyProcessed$sampleCode[
  misaligned_code$inv_taxonomyProcessed$sampleID %in% "SYCA.S2"
] <- "CONFLICT"
expect_error(build_inv_science_contract(misaligned_code),
             "sampleCode conflicts with field provenance")

cat(sprintf("Inverts science-contract fixtures passed (%d checks).\n", checks))
