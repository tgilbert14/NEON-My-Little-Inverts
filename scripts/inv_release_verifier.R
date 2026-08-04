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
  "processing_unknown", "processed_no_taxonomy", "count_unavailable",
  "area_unavailable",
  "density_unavailable", "reported_zero_count", "quantified_community"
)
INV_RELEASE_PROCESSING_COUNT_STATUS_LEVELS <- c(
  "processing_unknown", "processed_no_taxonomy",
  "taxonomy_count_unavailable", "taxonomy_count_available"
)
INV_RELEASE_STANDARD_SAMPLERS <- c(
  "surber", "core", "benthicsweep", "petiteponar", "modifiedkicknet",
  "hess", "lwd", "snag", "floatingsweep"
)
INV_RELEASE_NONSTANDARD_SAMPLER <- "grab"
INV_RELEASE_REVIEWED_SAMPLERS <- c(
  INV_RELEASE_STANDARD_SAMPLERS, INV_RELEASE_NONSTANDARD_SAMPLER
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
  "nonstandard_collection", "primary_stratum", "processing_unknown",
  "taxonomy_count_unavailable",
  "displayed_zero_percent_authoritative_estimate",
  "processing_count_status", "taxonomy_rows",
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
  "n_sampling_impractical", "n_processing_unknown",
  "n_processed_no_taxonomy", "n_taxonomy_count_unavailable",
  "n_displayed_zero_percent_authoritative_estimate",
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
  "n_unstratifiable", "n_processing_unknown", "n_processed_no_taxonomy",
  "n_taxonomy_count_unavailable",
  "n_displayed_zero_percent_authoritative_estimate", "n_count_samples",
  "n_density_samples", "n_taxa_recorded", "taxonomic_ranks"
)
INV_RELEASE_SITE_INDEX_COLUMNS <- c(
  "site", "aquaticSiteType", "lat", "lng", "elevation", "collectDate_min",
  "collectDate_max", "n_events", "n_strata", "n_opportunities",
  "n_primary_opportunities", "n_count_samples", "n_composition_samples",
  "n_density_samples", "n_reported_zero_count", "n_unstratifiable",
  "n_processing_unknown", "n_taxonomy_count_unavailable",
  "n_displayed_zero_percent_authoritative_estimate", "n_taxa_recorded",
  "n_sampling_impractical", "n_nonstandard_collection",
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
  "siteID", "uid", "sampleID", "sampleCode",
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

# Release-exact source reconciliation. These constants are repeated here on
# purpose: this verifier never sources the acquisition or producer code, so it
# can independently reject a self-consistent but scientifically changed build.
INV_RELEASE_RECEIPT_SCHEMA_VERSION <- "1.2.0"
INV_RELEASE_PRODUCER_SCHEMA_VERSION <- "2.1.0"
INV_RELEASE_BUNDLE_SCHEMA_VERSION <- "2.1.0"
INV_RELEASE_SCIENCE_VERSION <- "2.1.0"
INV_RELEASE_DPID <- "DP1.20120.001"
INV_RELEASE_TAG <- "RELEASE-2026"
INV_RELEASE_PACKAGE <- "basic"
INV_RELEASE_DOI <- "10.48443/hp56-s582"
INV_RELEASE_DOI_URL <- paste0("https://doi.org/", INV_RELEASE_DOI)
INV_RELEASE_PRODUCT_URL <- paste0(
  "https://data.neonscience.org/data-products/", INV_RELEASE_DPID, "/",
  INV_RELEASE_TAG
)
INV_RELEASE_ARTIFACT_FILE <- "DP1.20120.001_all.rds"
INV_RELEASE_CITATION_OBJECT <- "citation_20120_RELEASE-2026"
INV_RELEASE_PRODUCER_R_VERSION <- "4.5.2"
INV_RELEASE_NEON_UTILITIES_VERSION <- "4.0.1"
INV_RELEASE_NEON_UTILITIES_SOURCE <- paste0(
  "https://packagemanager.posit.co/cran/2026-07-15/src/contrib/",
  "neonUtilities_4.0.1.tar.gz"
)
# RELEASE-2026 is immutable. Synthetic contract fixtures explicitly set
# INV_SYNTHETIC_FIXTURE_MODE and exercise arbitrary valid publication stamps;
# production verification independently pins the observed release maximum.
INV_RELEASE_PUBLICATION_DATE_MAX <- "2025-12-09"
INV_RELEASE_REQUIRED_TABLES <- c(
  "inv_fieldData", "inv_persample", "inv_taxonomyProcessed"
)
INV_RELEASE_REQUIRED_METADATA <- c(
  "categoricalCodes_20120", "issueLog_20120", "readme_20120",
  "validation_20120", "variables_20120"
)
INV_RELEASE_OBJECT_NAMES <- sort(c(
  INV_RELEASE_REQUIRED_TABLES, INV_RELEASE_REQUIRED_METADATA,
  INV_RELEASE_CITATION_OBJECT
), method = "radix")
INV_RELEASE_SYNTHETIC_OBJECT_NAMES <- sort(c(
  INV_RELEASE_OBJECT_NAMES, "inv_taxonomyRaw"
), method = "radix")
INV_RELEASE_RECEIPT_MEMBERS <- c(
  "receipt_schema_version", "fetched_at_utc", "source_request", "release",
  "producer", "citation", "artifact", "object_names", "required_tables",
  "required_metadata", "all_objects", "site_ids", "segregation",
  "relations", "measurement_metadata"
)
INV_RELEASE_SOURCE_REQUEST_MEMBERS <- c(
  "dpid", "site", "startdate", "enddate", "package", "table",
  "time_index", "cloud_mode", "release", "include_provisional"
)
INV_RELEASE_SOURCE_MEMBERS <- c(
  "dpid", "release", "include_provisional", "package", "doi", "doi_url",
  "product_url", "fetched_at_utc", "publication_date_max", "artifact_file",
  "artifact_bytes", "artifact_sha256", "receipt_schema_version",
  "receipt_sha256", "citation_object", "citation_sha256", "table_rows",
  "metadata_rows", "segregation", "producer_git_sha", "producer_r_version",
  "neonUtilities_version", "neonUtilities_source"
)
INV_RELEASE_SEGREGATION_MEMBERS <- c(
  "collection_field_rows", "metabarcode_field_rows",
  "metabarcode_sample_ids", "metabarcode_site_ids",
  "per_sample_quarantine", "taxonomy_key_reconciliation",
  "dna_family_quarantine", "displayed_zero_percent", "count_unavailable",
  "unresolved_taxonomy"
)
INV_RELEASE_TAXONOMY_OMITTED_FIELDS <- c(
  "vialID", "vialCode", "slideID", "slideCode", "referenceCollection",
  "referenceCount", "referenceID", "referenceCode"
)
INV_RELEASE_TAXONOMY_BASE_KEYS <- c(
  "sampleID", "sampleCode", "scientificName", "morphospeciesID",
  "invertebrateLifeStage", "sizeClass", "sizeCategory", "immatureSpecimen",
  "indeterminateSpecies", "taxonRankQualifier", "sampleCondition",
  "distinctTaxon", "identificationRemarks"
)
INV_RELEASE_TAXONOMY_OMISSION_METADATA <- data.frame(
  fieldName = INV_RELEASE_TAXONOMY_OMITTED_FIELDS,
  description = c(
    "Vial identifier", "Barcode of a vial",
    "Unique identifier associated with each slide per sampleID or subsampleID",
    "Barcode of a slide",
    "Specimen is selected for the reference collection",
    paste(
      "Number of individuals removed from this sample and placed in",
      "reference collection"
    ),
    "Unique identifier associated with the reference collection",
    "Barcode of a reference sample"
  ),
  dataType = c(
    "string", "string", "string", "string", "string",
    "unsigned integer", "string", "string"
  ),
  units = c(NA, NA, NA, NA, NA, "number", NA, NA),
  downloadPkg = rep("expanded", 8L),
  pubFormat = c(
    "asIs", "asIs", "asIs", "asIs", "LOV", "integer", "asIs", "asIs"
  ),
  primaryKey = c("N", "N", "Y", "Y", "N", "N", "N", "N"),
  categoricalCodeName = c(NA, NA, NA, NA, "Yes or No choice", NA, NA, NA),
  stringsAsFactors = FALSE
)
INV_RELEASE_TAXONOMY_COLLISIONS <- list(
  groups = 1284L,
  rows = 3683L,
  group_size_counts = c(
    `2` = 826L, `3` = 240L, `4` = 79L, `5` = 40L, `6` = 31L,
    `7` = 15L, `8` = 24L, `9` = 6L, `10` = 9L, `11` = 6L,
    `12` = 4L, `13` = 2L, `14` = 2L
  ),
  laboratory_group_counts = c(
    `EcoAnalysts Inc.` = 16L, `GEI Consultants Inc.` = 3L,
    `Rhithron Associates, Inc.` = 1265L
  ),
  individual_count_variant_groups = 1080L,
  estimated_total_count_variant_groups = 1083L,
  subsample_percent_variant_groups = 3L,
  inventory_sha256 =
    "b3cabe1d9ec5435c9e10f05ef49ff9b299fcab719cc03fa46fc480acd3024fb5"
)
INV_RELEASE_DNA_FAMILY <- list(
  sample_ids = c(
    "HOPB.20170412.SURBER.3.DNA", "HOPB.20170412.SURBER.4.DNA",
    "HOPB.20170412.SURBER.5.DNA"
  ),
  site_ids = "HOPB",
  rows = c(inv_fieldData = 3L, inv_persample = 3L,
           inv_taxonomyProcessed = 172L),
  taxonomy_rows_by_sample = c(
    `HOPB.20170412.SURBER.3.DNA` = 33L,
    `HOPB.20170412.SURBER.4.DNA` = 66L,
    `HOPB.20170412.SURBER.5.DNA` = 73L
  ),
  uid_inventory_sha256 = c(
    inv_fieldData =
      "bd719c5a15b52167d7ba623161ebf54d8963bd9b3a883d254931acb320893233",
    inv_persample =
      "0202459f40870adc34539e57b97ab3dc8e41f6d0e4dec2add201bffb18aa1b55",
    inv_taxonomyProcessed =
      "dd4e8bc1122e2fee977115625786155ac36c745fb67b78b9068ec847dae5aed1"
  ),
  row_inventory_sha256 = c(
    inv_fieldData =
      "9b14872ba0cc3903d5b26ec7eff4428e4710d12d369a30f08811824f36c5f966",
    inv_persample =
      "5bb394d2f4bf355b95d82450047deb656096efe86bbacf46e2573727333216e0",
    inv_taxonomyProcessed =
      "ae2bc06f175f68c14547486557bccf5242fae9fd131945d6ea719e0f1533a784"
  )
)
INV_RELEASE_SAMPLE_IDENTITY <- list(
  practical_field_rows = 6485L,
  impractical_field_rows = 713L,
  per_sample_rows = 6442L,
  taxonomy_rows = 320068L,
  processed_without_taxonomy = 0L,
  blank_sample_code_rows = c(
    inv_fieldData = 1602L, inv_persample = 1573L,
    inv_taxonomyProcessed = 83303L
  ),
  practical_without_per_sample = 43L,
  taxonomy_without_per_sample_ids = c(
    "PRLA.20180709.BRYOZOAN.P8", "PRLA.20180718.BRYOZOAN.R2",
    "PRPO.20150916.SWEEP.1", "REDB.20151012.SURBER.4",
    "TOOK.20230726.MACROALGAE1.P7", "TOOK.20240726.MACROALGAE1.P10",
    "TOOK.20240726.MACROALGAE2.P2", "TOOK.20240726.MACROALGAE2.P4",
    "TOOK.20240726.MACROALGAE2.P9"
  ),
  taxonomy_without_per_sample_rows = 10L,
  projection_sha256 = c(
    practical_blank_code =
      "2f5fa079e78b81b4e99241d6dce50b4cc60ca9daaf3675ba4b8879d9c7ffe955",
    per_blank_code =
      "0f2172bf0b695b1b64b28f6f619760e7c514b1ec2333699c39783ea1820d5fba",
    taxonomy_blank_code =
      "b27cecdbde49204a5a4dc8bcdde1b2175800e7f74784d3a3a5ddb8191f860450",
    field_without_per =
      "8ab5887e1c7e63e03141b854d55177112c0f2a5e7dca45c4bcd27c79edaf24c4",
    taxonomy_without_per =
      "43cf28a696276245be1d789d2857bd7be0a4bd150d7cd23da6a834324f678d7e"
  ),
  uid_inventory_sha256 = c(
    practical_blank_code =
      "7a4553dbb591b962fdd7845846b7f379dceff84c2f18385d191011606c863cf5",
    per_blank_code =
      "26732748813a8823d771c47721f688f957728093c3db327fbe261944ee84829e",
    taxonomy_blank_code =
      "1fe075a27ace2dd66bbdcb76b38168439b6d1fd7922342f35a61dc9236e62760",
    field_without_per =
      "272168e8468021c811ab2037dc53e3dd800f28f4d4342bbb6d7091d83e943d8e",
    taxonomy_without_per =
      "7090552ea8cedb3dd75ec1799047c678a596c9d18078bed498396033aedaf6f6"
  )
)
INV_RELEASE_UNRESOLVED_TAXONOMY <- list(
  rows = 31L, samples = 31L,
  target_taxa_present_counts = c(N = 31L),
  identification_remark_counts = c(
    `2nd oligochaeta slide created` = 2L, `<blank>` = 20L,
    `No BMI specimens present in sample` = 1L, `No organisms found` = 1L,
    `Oligochaeta slide created by lab with no taxon information` = 4L,
    `no individuals in sample` = 1L, `no organisms found` = 1L,
    `sample arrived broken and not recoverable` = 1L
  ),
  sample_condition_counts = c(
    `<blank>` = 28L, `damaged, affecting taxonomy` = 1L,
    `other (specified in remarks)` = 2L
  ),
  samples_with_other_count_valid_taxa = 7L,
  placeholder_only_samples = 24L,
  sample_id_inventory_sha256 =
    "cf81573c8be01ac02b7e34101126e92d0c20780314477ce2840eabc2c6743f1c",
  projection_sha256 =
    "ca8cdff84348066d7b1bacb1739fead39426eb127919f3b8d6ebcbd040c0e4ee",
  uid_inventory_sha256 =
    "034c167aeaf6268267b1ce41c86d9f06cb360f319b177faf99850226e7203860",
  row_inventory_sha256 =
    "13048c9804bc2005be1e5aac227c53be1149280d80fdc61b594bab1b74f754fd"
)
INV_RELEASE_DISPLAYED_ZERO_PERCENT <- list(
  sample_id = "BARC.20210210.BENTHICSWEEP.3",
  sample_code = "A00000132218",
  site_id = "BARC",
  taxonomy_rows = 53L,
  taxonomy_uid_inventory_sha256 =
    "330cc65d16637fbc40ea6d88981a8141249333267d1f151e6f6b6763711bc51f",
  taxonomy_row_inventory_sha256 =
    "ea1d31106e5d6b72eee5d474da33123bcb3a232a3523a8182a15d62658178d5a",
  taxonomy_projection_sha256 =
    "538ae4e0362d73332ef0fc782ddf2760b688c42852903ff1abf4288e6d8256a4",
  taxonomy_subsample_percent = 0,
  per_sample_uid = "947304a0-8b67-4c9e-a9b4-9b725c3515ae",
  per_sample_subsample_percent = 0.5,
  laboratory_name = "EcoAnalysts Inc.",
  test_protocol_version =
    "ECOANALYSTS_Macroinvertebrate_Identification_Revision5",
  target_taxa_present = "Y",
  sample_condition = "condition OK",
  estimated_total_count_range = c(min = 213, max = 36693),
  individual_count_range = c(min = 1, max = 172),
  exact_200x_individual_rows = 0L,
  nonexact_200x_individual_rows = 53L,
  displayed_zero_minus_200x_range = c(min = 13, max = 2293)
)
INV_RELEASE_COUNT_METADATA <- data.frame(
  table = rep("inv_taxonomyProcessed", 3L),
  fieldName = c("individualCount", "subsamplePercent", "estimatedTotalCount"),
  description = c(
    "Number of individuals of the same type",
    "Percent of the total sample contained in the subsample",
    paste(
      "Estimated total count of individuals within a sample, of given taxon,",
      "life stage, and size class"
    )
  ),
  dataType = c("unsigned integer", "real", "real"),
  units = c("number", "percent", "number"),
  downloadPkg = rep("basic", 3L),
  pubFormat = rep("integer", 3L),
  primaryKey = rep("N", 3L),
  categoricalCodeName = rep(NA_character_, 3L),
  stringsAsFactors = FALSE
)
INV_RELEASE_COUNT_VALIDATION <- data.frame(
  table = c("inv_persample", rep("inv_pertaxon", 3L)),
  fieldName = c(
    "subsamplePercent", "individualCount", "estimatedTotalCount",
    "subsamplePercent"
  ),
  description = c(
    "Percent of the total sample contained in the subsample",
    "Number of individuals of the same type",
    paste(
      "Estimated total count of individuals within a sample, of given taxon,",
      "life stage, and size class"
    ),
    "Percent of the total sample contained in the subsample"
  ),
  dataType = c("real", "unsigned integer", "real", "real"),
  units = c("percent", "number", "number", "percent"),
  parserToCreate = c(
    NA_character_, NA_character_,
    "[individualCount / (subsamplePercent/100)]", NA_character_
  ),
  entryValidationRulesParser = c(
    paste0(
      "[REQUIRE][GREATER_THAN_OR_EQUAL_TO(0)]",
      "[LESS_THAN_OR_EQUAL_TO(100)][REQUIRE_COLUMN]"
    ),
    "[GREATER_THAN(0)][LESS_THAN_OR_EQUAL_TO(500)][REQUIRE_COLUMN]",
    "[GREATER_THAN_OR_EQUAL_TO(individualCount)]",
    paste0(
      "[IF(targetTaxaPresent='Y'), REQUIRE][GREATER_THAN_OR_EQUAL_TO(0)]",
      "[LESS_THAN_OR_EQUAL_TO(100)][REQUIRE_COLUMN]"
    )
  ),
  entryValidationRulesForm = rep(NA_character_, 4L),
  stringsAsFactors = FALSE
)
INV_RELEASE_COUNT_UNAVAILABLE <- list(
  rows = 306L,
  samples = 237L,
  issue_counts = c(estimated_count_unavailable = 306L),
  unresolved_taxonomy_rows = 31L,
  accepted_taxon_rows = 275L,
  uid_inventory_sha256 =
    "dde71b31f19c1cba1529ffc2a01c499d7e2ef995348c46febd42eec687cc93b1",
  sample_id_inventory_sha256 =
    "0a04df430839a644727a5e43be6154d627c1fc2f4edbf6c6faaf4d7c45ddfa78",
  row_inventory_sha256 =
    "5ef1d25ba91f4de8e435b7e116e8796fb49e407b3b12b317d810074ae7db9945",
  projection_sha256 =
    "d4a5a8732c4261b04cdc42f29b9390aa486f4440408bfe1fa6d151e4840c0575"
)
INV_RELEASE_PROCESSING_COUNT_OUTCOMES <- c(
  processing_unknown = 34L,
  processed_no_taxonomy = 0L,
  taxonomy_count_unavailable = 237L,
  taxonomy_count_available = 6214L
)
INV_RELEASE_BARC_OPPORTUNITY <- list(
  sampleID = "BARC.20210210.BENTHICSWEEP.3",
  taxonomy_rows = 27L,
  total_estimated_count = 68685,
  sample_density_m2 = 68685 / 0.305,
  taxa_observed = 27L,
  ept_taxa_observed = 2L,
  hill_q1 = 5.54384234346,
  hill_q2 = 2.95850114900,
  pct_ept_of_all_estimated_count = 0.9317900561,
  pct_order_classified_estimated_count = 98.44798719
)
INV_RELEASE_EXACT_GRAIN <-
  "site x event x aquaticSiteType x habitatType x samplerType"
INV_RELEASE_COMPARISON_BOUNDARY <- paste(
  "Exact site x event x aquaticSiteType x habitatType x samplerType strata;",
  "no site-health score and no raw-density cross-site rank."
)
INV_RELEASE_SEARCH_BOUNDARY <- paste(
  "Taxa rows retain exact collection strata and support denominators;",
  "the index contains no raw-density cross-site ranking."
)
INV_RELEASE_PROHIBITED_INFERENCE <- c(
  "site health or impairment", "population abundance",
  "raw-density cross-site ranking", "causality"
)
INV_RELEASE_PROHIBITED_CROSS_SITE_FIELDS <- c(
  "density_m2", "mean_sample_density_m2", "richness", "ept_richness",
  "pct_ept", "chao1", "rarefied_richness", "health_score"
)

inv_release_expected_metric_contract <- function() {
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
      rep(paste(INV_RELEASE_EXACT_GRAIN, "x sample"), 8),
      rep(INV_RELEASE_EXACT_GRAIN, 10),
      rep(paste(INV_RELEASE_EXACT_GRAIN, "x taxon"), 4)
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

inv_release_expected_qc_contract <- function() {
  list(
    schema_version = "1.0.0",
    source = "Official DP1.20120.001 RELEASE-2026 vF QC",
    retain_verbatim = TRUE,
    automatic_exclusion = FALSE,
    eligibility_effect = "none",
    table_fields = list(
      inv_fieldData = INV_RELEASE_QC_FIELDS$field,
      inv_persample = INV_RELEASE_QC_FIELDS$per_sample,
      inv_taxonomyProcessed = INV_RELEASE_QC_FIELDS$taxonomy_processed
    ),
    issue_log_fields = INV_RELEASE_ISSUE_FIELDS,
    issue_annotation_fields = INV_RELEASE_ISSUE_ANNOTATIONS
  )
}

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
  # RELEASE-2026 has 1,602 practical opportunities without sampleCode.
  # sampleID is the complete, unique analysis identity; sampleCode remains
  # provenance and is checked for agreement whenever both sides report it.
  inv_release_chr(sample_id)
}

inv_release_normalize_sampler_type <- function(value) {
  value <- trimws(as.character(value))
  value[is.na(value) | !nzchar(value)] <- NA_character_
  tolower(gsub("[[:space:]_-]+", "", value))
}

inv_release_nonstandard_id_hint <- function(sample_id) {
  !inv_release_blank(sample_id) & grepl(
    "(^|[._-])(GRAB|BRYOZOAN|MACROALGAE[0-9]*)([._-]|$)",
    as.character(sample_id), ignore.case = TRUE
  )
}

inv_release_stratum_key <- function(site_id, event_id, water_type,
                                    habitat_type, sampler_type) {
  paste(
    inv_release_chr(site_id), inv_release_chr(event_id),
    inv_release_chr(water_type), inv_release_chr(habitat_type),
    inv_release_chr(sampler_type), sep = "\u241e"
  )
}

inv_release_hill <- function(counts) {
  counts <- inv_release_num(counts)
  counts <- counts[is.finite(counts) & counts > 0]
  if (!length(counts)) return(c(q1 = NA_real_, q2 = NA_real_))
  proportions <- counts / sum(counts)
  c(
    q1 = exp(-sum(proportions * log(proportions))),
    q2 = 1 / sum(proportions^2)
  )
}

inv_release_date_range <- function(x) {
  dates <- suppressWarnings(as.Date(substr(as.character(x), 1L, 10L)))
  dates <- dates[!is.na(dates)]
  if (!length(dates)) return(c(NA_character_, NA_character_))
  as.character(range(dates))
}

# Publication stamps in the official portable source are NEON compact UTC
# values (for example, 20251204T230818Z). Keep this parser local to the
# independent verifier so the producer and verifier cannot share a parsing
# defect. Unknown representations fail closed to NA.
inv_release_publication_dates <- function(x) {
  if (inherits(x, "Date")) {
    date_value <- as.Date(x)
    raw_days <- unclass(date_value)
    parsed <- rep(as.Date(NA), length(date_value))
    valid <- !is.na(raw_days) & is.finite(raw_days) &
      raw_days == floor(raw_days)
    if (any(valid)) {
      calendar <- format(date_value[valid], "%Y-%m-%d")
      round_trip <- suppressWarnings(as.Date(
        calendar, format = "%Y-%m-%d"
      ))
      exact <- !is.na(round_trip) &
        format(round_trip, "%Y-%m-%d") == calendar &
        unclass(round_trip) == raw_days[valid]
      parsed[which(valid)[exact]] <- round_trip[exact]
    }
    return(parsed)
  }
  if (inherits(x, "POSIXt")) {
    instant <- suppressWarnings(as.POSIXct(x))
    raw_seconds <- unclass(instant)
    parsed <- rep(as.Date(NA), length(instant))
    valid <- !is.na(raw_seconds) & is.finite(raw_seconds)
    if (any(valid)) {
      utc_day <- format(
        instant[valid], "%Y-%m-%d", tz = "UTC", usetz = FALSE
      )
      round_trip <- suppressWarnings(as.Date(
        utc_day, format = "%Y-%m-%d"
      ))
      exact <- !is.na(round_trip) &
        format(round_trip, "%Y-%m-%d") == utc_day
      parsed[which(valid)[exact]] <- round_trip[exact]
    }
    return(parsed)
  }

  raw <- as.character(x)
  parsed <- rep(as.Date(NA), length(raw))
  compact <- !is.na(raw) & grepl("^[0-9]{8}T[0-9]{6}Z$", raw)
  iso_datetime <- !is.na(raw) & grepl(
    "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$",
    raw
  )
  iso_date <- !is.na(raw) & grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", raw)
  if (any(compact)) {
    value <- suppressWarnings(as.POSIXct(
      strptime(raw[compact], format = "%Y%m%dT%H%M%SZ", tz = "UTC")
    ))
    valid <- !is.na(value) &
      format(value, "%Y%m%dT%H%M%SZ", tz = "UTC") == raw[compact]
    parsed[which(compact)[valid]] <- as.Date(value[valid], tz = "UTC")
  }
  if (any(iso_datetime)) {
    value <- suppressWarnings(as.POSIXct(strptime(
      raw[iso_datetime], format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"
    )))
    valid <- !is.na(value) &
      format(value, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC") == raw[iso_datetime]
    parsed[which(iso_datetime)[valid]] <- as.Date(value[valid], tz = "UTC")
  }
  if (any(iso_date)) {
    value <- suppressWarnings(as.Date(raw[iso_date], format = "%Y-%m-%d"))
    valid <- !is.na(value) & format(value, "%Y-%m-%d") == raw[iso_date]
    parsed[which(iso_date)[valid]] <- value[valid]
  }
  parsed
}

inv_release_publication_stamp <- function(source) {
  table_names <- c(
    "inv_fieldData", "inv_persample", "inv_taxonomyProcessed"
  )
  parsed_tables <- lapply(table_names, function(table_name) {
    raw <- source[[table_name]]$publicationDate
    parsed <- inv_release_publication_dates(raw)
    inv_release_assert(
      length(parsed) == length(raw) && !anyNA(parsed),
      "Raw source has an unparseable publicationDate in %s",
      table_name
    )
    parsed
  })
  parsed <- as.Date(
    unlist(parsed_tables, use.names = FALSE), origin = "1970-01-01"
  )
  inv_release_assert(length(parsed) > 0L,
                     "Raw source has no usable publicationDate stamp")
  format(max(parsed), "%Y-%m-%d")
}

inv_release_issue_annotations <- function(issue_log, site, collect_dates) {
  out <- issue_log[, INV_RELEASE_ISSUE_FIELDS, drop = FALSE]
  site_dates <- suppressWarnings(as.Date(substr(
    as.character(collect_dates), 1L, 10L
  )))
  site_dates <- site_dates[!is.na(site_dates)]
  inv_release_assert(length(site_dates) > 0L,
                     "Raw site %s has no usable issue-applicability dates", site)
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
  start_date <- suppressWarnings(as.Date(substr(start_raw, 1L, 10L)))
  end_date <- suppressWarnings(as.Date(substr(end_raw, 1L, 10L)))
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
  out[, c(INV_RELEASE_ISSUE_FIELDS, INV_RELEASE_ISSUE_ANNOTATIONS), drop = FALSE]
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

inv_release_processing_status_count <- function(opportunities, status) {
  value <- as.character(opportunities$processing_count_status)
  as.integer(sum(!is.na(value) & value == status))
}

inv_release_sha256 <- function(path) {
  inv_release_assert(requireNamespace("digest", quietly = TRUE),
                     "digest is required for release verification")
  inv_release_assert(file.exists(path), "Missing release file: %s", path)
  unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
}

inv_release_sha256_text <- function(value) {
  inv_release_assert(requireNamespace("digest", quietly = TRUE),
                     "digest is required for release verification")
  unname(digest::digest(value, algo = "sha256", serialize = FALSE))
}

inv_release_value_equal <- function(actual, expected, tolerance = 0) {
  if (is.data.frame(actual) || is.data.frame(expected)) {
    return(inv_release_frame_equal(actual, expected, tolerance))
  }
  if (is.list(actual) || is.list(expected)) {
    if (!is.list(actual) || !is.list(expected) ||
        length(actual) != length(expected) ||
        !identical(names(actual), names(expected))) return(FALSE)
    return(all(vapply(seq_along(expected), function(index) {
      inv_release_value_equal(actual[[index]], expected[[index]], tolerance)
    }, logical(1))))
  }
  if (!identical(names(actual), names(expected))) return(FALSE)
  inv_release_vector_equal(actual, expected, tolerance)
}

inv_release_assert_value_equal <- function(actual, expected, label,
                                           tolerance = 0) {
  inv_release_assert(
    inv_release_value_equal(actual, expected, tolerance),
    "%s differs from its receipt-derived authority", label
  )
  invisible(actual)
}

inv_release_valid_sha256 <- function(value) {
  length(value) == 1L && !is.na(value) &&
    grepl("^[0-9a-f]{64}$", as.character(value))
}

inv_release_valid_utc_second <- function(value) {
  if (length(value) != 1L || is.na(value) ||
      !grepl(
        "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$",
        as.character(value)
      )) return(FALSE)
  parsed <- suppressWarnings(as.POSIXct(strptime(
    as.character(value), format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"
  )))
  !is.na(parsed) &&
    identical(format(parsed, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
              as.character(value))
}

inv_release_assert_receipt_object_summary <- function(summary, label) {
  inv_release_assert(
    is.list(summary) &&
      identical(names(summary), c(
        "class", "row_count", "columns", "column_classes"
      )) &&
      length(summary$class) == 1L && !is.na(summary$class) &&
      grepl(
        "(^|/)data[.]frame($|/)", as.character(summary$class), perl = TRUE
      ) &&
      length(summary$row_count) == 1L &&
      is.finite(as.numeric(summary$row_count)) &&
      as.numeric(summary$row_count) >= 0 &&
      as.numeric(summary$row_count) == as.integer(summary$row_count) &&
      is.character(summary$columns) && length(summary$columns) > 0L &&
      !anyNA(summary$columns) && all(nzchar(summary$columns)) &&
      !anyDuplicated(summary$columns) && is.list(summary$column_classes) &&
      identical(names(summary$column_classes), summary$columns) &&
      all(vapply(summary$column_classes, function(value) {
        length(value) == 1L && !is.na(value) && nzchar(as.character(value))
      }, logical(1))),
    "Receipt %s schema inventory is invalid", label
  )
  invisible(summary)
}

inv_release_validate_receipt <- function(receipt, receipt_path) {
  synthetic_fixture <- exists(
    "INV_SYNTHETIC_FIXTURE_MODE", inherits = TRUE
  ) && isTRUE(get("INV_SYNTHETIC_FIXTURE_MODE", inherits = TRUE))
  inv_release_assert(
    is.list(receipt) && identical(names(receipt), INV_RELEASE_RECEIPT_MEMBERS),
    "Published source receipt member set is not exact"
  )
  inv_release_assert(
    identical(as.character(receipt$receipt_schema_version),
              INV_RELEASE_RECEIPT_SCHEMA_VERSION) &&
      inv_release_valid_utc_second(receipt$fetched_at_utc),
    "Published source receipt schema or fetched time is invalid"
  )
  request <- receipt$source_request
  inv_release_assert(
    is.list(request) &&
      identical(names(request), INV_RELEASE_SOURCE_REQUEST_MEMBERS) &&
      identical(as.character(request$dpid), INV_RELEASE_DPID) &&
      identical(as.character(request$site), "all") &&
      identical(as.character(request$startdate), "all") &&
      identical(as.character(request$enddate), "all") &&
      identical(as.character(request$package), INV_RELEASE_PACKAGE) &&
      identical(as.character(request$table), "all") &&
      identical(as.character(request$time_index), "all") &&
      identical(request$cloud_mode, FALSE) &&
      identical(as.character(request$release), INV_RELEASE_TAG) &&
      identical(request$include_provisional, FALSE),
    "Published source receipt request is not the exact basic RELEASE-2026 request"
  )
  inv_release_assert(
    is.list(receipt$release) &&
      identical(names(receipt$release),
                c("tag", "product_url", "doi", "doi_url")) &&
      identical(as.character(receipt$release$tag), INV_RELEASE_TAG) &&
      identical(as.character(receipt$release$product_url),
                INV_RELEASE_PRODUCT_URL) &&
      identical(as.character(receipt$release$doi), INV_RELEASE_DOI) &&
      identical(as.character(receipt$release$doi_url), INV_RELEASE_DOI_URL),
    "Published source receipt release identity is not exact"
  )
  producer <- receipt$producer
  inv_release_assert(
    is.list(producer) && identical(names(producer), c(
      "git_sha", "r_version", "neonUtilities_version",
      "neonUtilities_source"
    )) && inv_release_valid_git_sha(producer$git_sha) &&
      identical(as.character(producer$r_version),
                INV_RELEASE_PRODUCER_R_VERSION) &&
      identical(as.character(producer$neonUtilities_version),
                INV_RELEASE_NEON_UTILITIES_VERSION) &&
      identical(as.character(producer$neonUtilities_source),
                INV_RELEASE_NEON_UTILITIES_SOURCE),
    "Published source receipt producer runtime is not exact"
  )
  citation <- receipt$citation
  inv_release_assert(
    is.list(citation) &&
      identical(names(citation), c("object", "text", "sha256")) &&
      identical(as.character(citation$object), INV_RELEASE_CITATION_OBJECT) &&
      length(citation$text) == 1L && !is.na(citation$text) &&
      nzchar(as.character(citation$text)) &&
      grepl(INV_RELEASE_DPID, as.character(citation$text), fixed = TRUE) &&
      grepl(INV_RELEASE_TAG, as.character(citation$text), fixed = TRUE) &&
      grepl(INV_RELEASE_DOI, as.character(citation$text), fixed = TRUE) &&
      grepl(INV_RELEASE_PRODUCT_URL, as.character(citation$text), fixed = TRUE) &&
      inv_release_valid_sha256(citation$sha256) &&
      identical(inv_release_sha256_text(as.character(citation$text)),
                as.character(citation$sha256)),
    "Published source receipt citation identity or text hash is invalid"
  )
  artifact <- receipt$artifact
  artifact_file <- as.character(artifact$file)
  artifact_file_ok <- if (synthetic_fixture) {
    length(artifact_file) == 1L && !is.na(artifact_file) &&
      nzchar(artifact_file) &&
      identical(basename(artifact_file), artifact_file) &&
      grepl("[.]rds$", artifact_file)
  } else {
    identical(artifact_file, INV_RELEASE_ARTIFACT_FILE)
  }
  artifact_bytes <- suppressWarnings(as.numeric(artifact$bytes))
  inv_release_assert(
    is.list(artifact) &&
      identical(names(artifact), c("file", "bytes", "sha256")) &&
      artifact_file_ok &&
      length(artifact_bytes) == 1L && is.finite(artifact_bytes) &&
      artifact_bytes > 0 && artifact_bytes == floor(artifact_bytes) &&
      inv_release_valid_sha256(artifact$sha256),
    "Published source receipt artifact identity is invalid"
  )
  expected_object_names <- if (synthetic_fixture) {
    INV_RELEASE_SYNTHETIC_OBJECT_NAMES
  } else INV_RELEASE_OBJECT_NAMES
  inv_release_assert(
    identical(as.character(receipt$object_names), expected_object_names) &&
      is.list(receipt$required_tables) &&
      identical(names(receipt$required_tables), INV_RELEASE_REQUIRED_TABLES) &&
      is.list(receipt$required_metadata) &&
      identical(names(receipt$required_metadata),
                INV_RELEASE_REQUIRED_METADATA) &&
      is.list(receipt$all_objects) &&
      identical(names(receipt$all_objects), expected_object_names),
    "Published source receipt object inventory is not exact"
  )
  for (object_name in setdiff(
      expected_object_names, INV_RELEASE_CITATION_OBJECT)) {
    inv_release_assert_receipt_object_summary(
      receipt$all_objects[[object_name]], paste("all_objects", object_name)
    )
  }
  citation_summary <- receipt$all_objects[[INV_RELEASE_CITATION_OBJECT]]
  inv_release_assert(
    is.list(citation_summary) &&
      identical(names(citation_summary), c("class", "length")) &&
      identical(as.character(citation_summary$class), "character") &&
      as.integer(citation_summary$length) >= 1L,
    "Receipt citation object schema inventory is invalid"
  )
  for (table_name in INV_RELEASE_REQUIRED_TABLES) {
    inv_release_assert_value_equal(
      receipt$required_tables[[table_name]],
      receipt$all_objects[[table_name]],
      paste("receipt required-table inventory", table_name)
    )
  }
  for (metadata_name in INV_RELEASE_REQUIRED_METADATA) {
    inv_release_assert_value_equal(
      receipt$required_metadata[[metadata_name]],
      receipt$all_objects[[metadata_name]],
      paste("receipt required-metadata inventory", metadata_name)
    )
  }
  inv_release_assert(
    is.list(receipt$segregation) &&
      identical(names(receipt$segregation), INV_RELEASE_SEGREGATION_MEMBERS) &&
      is.list(receipt$relations) &&
      identical(names(receipt$relations), names(INV_RELEASE_SAMPLE_IDENTITY)) &&
      identical(as.character(receipt$site_ids), INV_RELEASE_EXPECTED_SITES),
    "Published source receipt scientific inventory member set is not exact"
  )
  if (!synthetic_fixture) {
    inv_release_assert_audit(
      receipt$relations, INV_RELEASE_SAMPLE_IDENTITY,
      "published receipt sampleID-primary relation"
    )
  }
  inv_release_assert(file.exists(receipt_path),
                     "Published source receipt file is missing")
  invisible(receipt)
}

inv_release_named_receipt_vector <- function(value, field_names, mode) {
  value <- unlist(value, recursive = FALSE, use.names = FALSE)
  if (!length(value)) {
    empty <- switch(mode, integer = integer(), numeric = numeric(),
                    character = character())
    return(stats::setNames(empty, field_names))
  }
  inv_release_assert(
    length(value) == length(field_names),
    "Receipt named-vector inventory length is invalid"
  )
  value <- switch(
    mode,
    integer = as.integer(value),
    numeric = as.numeric(value),
    character = as.character(value)
  )
  stats::setNames(value, field_names)
}

inv_release_contract_segregation <- function(segregation) {
  out <- segregation
  taxonomy <- out$taxonomy_key_reconciliation
  taxonomy$metadata <- inv_release_receipt_rows(
    taxonomy$metadata, names(INV_RELEASE_TAXONOMY_OMISSION_METADATA)
  )
  group_names <- if (length(taxonomy$group_size_counts)) {
    names(INV_RELEASE_TAXONOMY_COLLISIONS$group_size_counts)
  } else character()
  laboratory_names <- if (length(taxonomy$laboratory_group_counts)) {
    names(INV_RELEASE_TAXONOMY_COLLISIONS$laboratory_group_counts)
  } else character()
  taxonomy$group_size_counts <- inv_release_named_receipt_vector(
    taxonomy$group_size_counts, group_names, "integer"
  )
  taxonomy$laboratory_group_counts <- inv_release_named_receipt_vector(
    taxonomy$laboratory_group_counts, laboratory_names, "integer"
  )
  out$taxonomy_key_reconciliation <- taxonomy

  dna <- out$dna_family_quarantine
  dna_table_names <- c(
    "inv_fieldData", "inv_persample", "inv_taxonomyProcessed"
  )
  dna$rows <- inv_release_named_receipt_vector(
    dna$rows, dna_table_names, "integer"
  )
  dna$taxonomy_rows_by_sample <- inv_release_named_receipt_vector(
    dna$taxonomy_rows_by_sample, as.character(dna$sample_ids), "integer"
  )
  dna$uid_inventory_sha256 <- inv_release_named_receipt_vector(
    dna$uid_inventory_sha256, dna_table_names, "character"
  )
  dna$row_inventory_sha256 <- inv_release_named_receipt_vector(
    dna$row_inventory_sha256, dna_table_names, "character"
  )
  out$dna_family_quarantine <- dna

  displayed <- out$displayed_zero_percent
  for (field in c(
      "estimated_total_count_range", "individual_count_range",
      "displayed_zero_minus_200x_range")) {
    if (!is.null(displayed[[field]])) {
      displayed[[field]] <- inv_release_named_receipt_vector(
        displayed[[field]], c("min", "max"), "numeric"
      )
    }
  }
  out$displayed_zero_percent <- displayed

  count_unavailable <- out$count_unavailable
  count_issue_names <- if (length(count_unavailable$issue_counts)) {
    names(INV_RELEASE_COUNT_UNAVAILABLE$issue_counts)
  } else character()
  count_unavailable$issue_counts <- inv_release_named_receipt_vector(
    count_unavailable$issue_counts, count_issue_names, "integer"
  )
  out$count_unavailable <- count_unavailable

  unresolved <- out$unresolved_taxonomy
  unresolved_fields <- list(
    target_taxa_present_counts = names(
      INV_RELEASE_UNRESOLVED_TAXONOMY$target_taxa_present_counts
    ),
    identification_remark_counts = names(
      INV_RELEASE_UNRESOLVED_TAXONOMY$identification_remark_counts
    ),
    sample_condition_counts = names(
      INV_RELEASE_UNRESOLVED_TAXONOMY$sample_condition_counts
    )
  )
  for (field in names(unresolved_fields)) {
    field_names <- if (length(unresolved[[field]])) {
      unresolved_fields[[field]]
    } else character()
    unresolved[[field]] <- inv_release_named_receipt_vector(
      unresolved[[field]], field_names, "integer"
    )
  }
  out$unresolved_taxonomy <- unresolved
  out
}

inv_release_expected_source_from_receipt <- function(
    receipt, receipt_path, publication_date_max) {
  inv_release_validate_receipt(receipt, receipt_path)
  table_rows <- vapply(INV_RELEASE_REQUIRED_TABLES, function(table_name) {
    as.integer(receipt$required_tables[[table_name]]$row_count)
  }, integer(1))
  metadata_rows <- vapply(INV_RELEASE_REQUIRED_METADATA, function(table_name) {
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
    publication_date_max = as.character(publication_date_max),
    artifact_file = as.character(receipt$artifact$file),
    artifact_bytes = as.numeric(receipt$artifact$bytes),
    artifact_sha256 = as.character(receipt$artifact$sha256),
    receipt_schema_version = as.character(receipt$receipt_schema_version),
    receipt_sha256 = inv_release_sha256(receipt_path),
    citation_object = as.character(receipt$citation$object),
    citation_sha256 = as.character(receipt$citation$sha256),
    table_rows = table_rows,
    metadata_rows = metadata_rows,
    segregation = inv_release_contract_segregation(receipt$segregation),
    producer_git_sha = as.character(receipt$producer$git_sha),
    producer_r_version = as.character(receipt$producer$r_version),
    neonUtilities_version = as.character(receipt$producer$neonUtilities_version),
    neonUtilities_source = as.character(receipt$producer$neonUtilities_source)
  )
}

inv_release_object_summary <- function(value) {
  if (is.data.frame(value)) {
    return(list(
      class = paste(class(value), collapse = "/"),
      row_count = nrow(value),
      columns = names(value),
      column_classes = as.list(vapply(value, function(column) {
        paste(class(column), collapse = "/")
      }, character(1)))
    ))
  }
  list(class = paste(class(value), collapse = "/"), length = length(value))
}

inv_release_inventory_order <- function(frame, fields) {
  values <- lapply(frame[fields], function(value) {
    value <- as.character(value)
    value[is.na(value)] <- "<NA>"
    enc2utf8(value)
  })
  do.call(order, c(values, list(na.last = TRUE, method = "radix")))
}

inv_release_inventory_sha256 <- function(frame, order_fields) {
  inv_release_require_columns(frame, "inventory frame", order_fields)
  if (nrow(frame)) {
    frame <- frame[inv_release_inventory_order(frame, order_fields), , drop = FALSE]
  }
  frame <- frame[, sort(names(frame)), drop = FALSE]
  rownames(frame) <- NULL
  inv_release_assert(requireNamespace("jsonlite", quietly = TRUE),
                     "jsonlite is required for release verification")
  payload <- jsonlite::toJSON(
    frame, dataframe = "rows", auto_unbox = TRUE, null = "null", na = "null",
    digits = NA, POSIXt = "ISO8601", Date = "ISO8601"
  )
  inv_release_sha256_text(payload)
}

inv_release_uid_inventory_sha256 <- function(frame) {
  inv_release_sha256_text(paste(
    sort(as.character(frame$uid), method = "radix"), collapse = "\n"
  ))
}

inv_release_adjacent_equal <- function(frame, fields) {
  if (nrow(frame) < 2L) return(logical())
  Reduce(`&`, lapply(frame[fields], function(value) {
    left <- value[-length(value)]
    right <- value[-1L]
    (is.na(left) & is.na(right)) |
      (!is.na(left) & !is.na(right) & as.character(left) == as.character(right))
  }))
}

inv_release_taxonomy_collision_audit <- function(taxonomy) {
  inv_release_require_columns(
    taxonomy, "raw taxonomy collision audit",
    c(INV_RELEASE_TAXONOMY_BASE_KEYS, "uid", "laboratoryName",
      "individualCount", "estimatedTotalCount", "subsamplePercent")
  )
  duplicate <- duplicated(taxonomy[INV_RELEASE_TAXONOMY_BASE_KEYS]) |
    duplicated(taxonomy[INV_RELEASE_TAXONOMY_BASE_KEYS], fromLast = TRUE)
  collision <- taxonomy[duplicate, , drop = FALSE]
  collision <- collision[inv_release_inventory_order(
    collision, c(INV_RELEASE_TAXONOMY_BASE_KEYS, "uid")
  ), , drop = FALSE]
  same_previous <- inv_release_adjacent_equal(
    collision, INV_RELEASE_TAXONOMY_BASE_KEYS
  )
  group_id <- if (nrow(collision)) cumsum(c(TRUE, !same_previous)) else integer()
  groups <- split(seq_len(nrow(collision)), group_id, drop = TRUE)
  group_sizes <- if (length(group_id)) tabulate(group_id) else integer()
  sizes <- sort(unique(group_sizes))
  size_counts <- stats::setNames(vapply(
    sizes, function(size) sum(group_sizes == size), integer(1)
  ), as.character(sizes))
  labs <- vapply(groups, function(index) {
    value <- unique(as.character(collision$laboratoryName[index]))
    inv_release_assert(length(value) == 1L && !inv_release_blank(value),
                       "Raw taxonomy collision crosses laboratory identities")
    value[[1L]]
  }, character(1))
  lab_counts <- table(labs)
  lab_counts <- stats::setNames(as.integer(lab_counts), names(lab_counts))
  variants <- function(field) sum(vapply(groups, function(index) {
    length(unique(collision[[field]][index])) > 1L
  }, logical(1)))
  list(
    groups = length(groups), rows = nrow(collision),
    group_size_counts = size_counts,
    laboratory_group_counts = lab_counts,
    individual_count_variant_groups = variants("individualCount"),
    estimated_total_count_variant_groups = variants("estimatedTotalCount"),
    subsample_percent_variant_groups = variants("subsamplePercent"),
    inventory_sha256 = inv_release_inventory_sha256(
      collision, c(INV_RELEASE_TAXONOMY_BASE_KEYS, "uid")
    )
  )
}

inv_release_dna_family_audit <- function(source) {
  table_names <- c("inv_fieldData", "inv_persample", "inv_taxonomyProcessed")
  subsets <- stats::setNames(lapply(table_names, function(table_name) {
    table <- source[[table_name]]
    sample_id <- as.character(table$sampleID)
    any_case <- !inv_release_blank(sample_id) &
      grepl("^.+[.]DNA$", sample_id, ignore.case = TRUE)
    canonical <- !inv_release_blank(sample_id) & grepl("^.+[.]DNA$", sample_id)
    inv_release_assert(!any(any_case & !canonical),
                       "Raw %s has a noncanonical .DNA suffix", table_name)
    out <- table[canonical, , drop = FALSE]
    inv_release_assert(nrow(out) && all(inv_release_blank(out$sampleCode)) &&
                         !any(inv_release_blank(out$uid)) &&
                         !anyDuplicated(as.character(out$uid)),
                       "Raw %s .DNA identity is invalid", table_name)
    out
  }), table_names)
  sample_ids <- sort(unique(as.character(subsets[[1L]]$sampleID)), method = "radix")
  site_ids <- sort(unique(as.character(subsets[[1L]]$siteID)), method = "radix")
  inv_release_assert(all(vapply(subsets[-1L], function(table) {
    identical(sort(unique(as.character(table$sampleID)), method = "radix"),
              sample_ids) &&
      identical(sort(unique(as.character(table$siteID)), method = "radix"),
                site_ids)
  }, logical(1))), "Raw .DNA family differs across source tables")
  taxonomy_counts <- table(factor(
    as.character(subsets$inv_taxonomyProcessed$sampleID), levels = sample_ids
  ))
  taxonomy_counts <- stats::setNames(as.integer(taxonomy_counts),
                                     names(taxonomy_counts))
  list(
    audit = list(
      sample_ids = sample_ids, site_ids = site_ids,
      rows = vapply(subsets, nrow, integer(1)),
      taxonomy_rows_by_sample = taxonomy_counts,
      uid_inventory_sha256 = vapply(
        subsets, inv_release_uid_inventory_sha256, character(1)
      ),
      row_inventory_sha256 = vapply(subsets, function(table) {
        inv_release_inventory_sha256(table, c("sampleID", "uid"))
      }, character(1))
    ),
    subsets = subsets
  )
}

inv_release_value_counts <- function(value) {
  value <- as.character(value)
  value[inv_release_blank(value)] <- "<blank>"
  levels <- sort(unique(value), method = "radix")
  stats::setNames(vapply(levels, function(level) {
    sum(value == level)
  }, integer(1)), levels)
}

inv_release_unresolved_audit <- function(taxonomy) {
  placeholder <- taxonomy[inv_release_blank(taxonomy$acceptedTaxonID), , drop = FALSE]
  inv_release_assert(
    all(is.na(inv_release_num(placeholder$individualCount))) &&
      all(is.na(inv_release_num(placeholder$estimatedTotalCount))),
    "Raw unresolved taxonomy placeholder reports an individual or estimated count"
  )
  sample_ids <- sort(as.character(placeholder$sampleID), method = "radix")
  unique_ids <- unique(sample_ids)
  has_other <- vapply(unique_ids, function(sample_id) {
    rows <- as.character(taxonomy$sampleID) == sample_id &
      !inv_release_blank(taxonomy$acceptedTaxonID) &
      is.finite(inv_release_num(taxonomy$estimatedTotalCount))
    any(rows)
  }, logical(1))
  list(
    rows = nrow(placeholder), samples = length(unique_ids),
    target_taxa_present_counts = inv_release_value_counts(
      placeholder$targetTaxaPresent
    ),
    identification_remark_counts = inv_release_value_counts(
      placeholder$identificationRemarks
    ),
    sample_condition_counts = inv_release_value_counts(
      placeholder$sampleCondition
    ),
    samples_with_other_count_valid_taxa = sum(has_other),
    placeholder_only_samples = sum(!has_other),
    sample_id_inventory_sha256 = inv_release_sha256_text(paste(
      sample_ids, collapse = "\n"
    )),
    projection_sha256 = inv_release_inventory_sha256(
      placeholder[, c("uid", "siteID", "sampleID", "sampleCode"), drop = FALSE],
      c("sampleID", "uid")
    ),
    uid_inventory_sha256 = inv_release_uid_inventory_sha256(placeholder),
    row_inventory_sha256 = inv_release_inventory_sha256(
      placeholder, c("sampleID", "uid")
    )
  )
}

inv_release_displayed_zero_percent_audit <- function(source) {
  taxonomy <- source$inv_taxonomyProcessed
  per_sample <- source$inv_persample
  inv_release_require_columns(
    taxonomy, "raw displayed-zero-percent taxonomy audit",
    c(
      "uid", "siteID", "sampleID", "sampleCode", "targetTaxaPresent",
      "sampleCondition", "laboratoryName", "individualCount",
      "subsamplePercent", "estimatedTotalCount", "dataQF"
    )
  )
  percent <- inv_release_num(taxonomy$subsamplePercent)
  displayed_zero <- is.finite(percent) & percent == 0
  rows <- taxonomy[displayed_zero, , drop = FALSE]
  if (!nrow(rows)) return(NULL)

  individual <- inv_release_num(rows$individualCount)
  estimated <- inv_release_num(rows$estimatedTotalCount)
  inv_release_assert(
    all(is.finite(individual) & individual > 0) &&
      all(is.finite(estimated) & estimated >= individual) &&
      all(as.character(rows$targetTaxaPresent) == "Y") &&
      all(as.character(rows$sampleCondition) == "condition OK") &&
      all(as.character(rows$laboratoryName) == "EcoAnalysts Inc.") &&
      all(inv_release_blank(rows$dataQF)),
    paste0(
      "Raw displayed-zero subsample rows do not retain authoritative finite ",
      "published estimates"
    )
  )
  sample_ids <- unique(as.character(rows$sampleID))
  sample_codes <- unique(as.character(rows$sampleCode))
  site_ids <- unique(as.character(rows$siteID))
  inv_release_assert(
    length(sample_ids) == 1L && length(sample_codes) == 1L &&
      length(site_ids) == 1L,
    "Raw displayed-zero subsample rows span multiple sample identities"
  )
  per <- per_sample[
    as.character(per_sample$sampleID) == sample_ids[[1L]] &
      as.character(per_sample$sampleCode) == sample_codes[[1L]],
    , drop = FALSE
  ]
  inv_release_require_columns(
    per, "raw displayed-zero-percent per-sample audit",
    c("uid", "subsamplePercent", "laboratoryName", "testProtocolVersion", "dataQF")
  )
  per_percent <- inv_release_num(per$subsamplePercent)
  inv_release_assert(
    nrow(per) == 1L && is.finite(per_percent) && per_percent > 0 &&
      per_percent <= 100 && inv_release_blank(per$dataQF),
    "Raw displayed-zero taxonomy lacks one valid per-sample subsample link"
  )

  variables <- source$variables_20120
  metadata_fields <- names(INV_RELEASE_COUNT_METADATA)
  inv_release_require_columns(
    variables, "raw displayed-zero variables metadata",
    c("table", metadata_fields)
  )
  expected_key <- paste(
    INV_RELEASE_COUNT_METADATA$table,
    INV_RELEASE_COUNT_METADATA$fieldName, sep = "\u241f"
  )
  variable_key <- paste(
    as.character(variables$table), as.character(variables$fieldName),
    sep = "\u241f"
  )
  metadata <- variables[match(expected_key, variable_key), metadata_fields,
                        drop = FALSE]
  metadata <- data.frame(lapply(metadata, as.character), check.names = FALSE,
                         stringsAsFactors = FALSE)
  inv_release_assert_frame_equal(
    metadata, INV_RELEASE_COUNT_METADATA,
    "raw displayed-zero count metadata"
  )

  validation <- source$validation_20120
  validation_fields <- names(INV_RELEASE_COUNT_VALIDATION)
  inv_release_require_columns(
    validation, "raw displayed-zero validation metadata",
    c("table", validation_fields)
  )
  expected_validation_key <- paste(
    INV_RELEASE_COUNT_VALIDATION$table,
    INV_RELEASE_COUNT_VALIDATION$fieldName, sep = "\u241f"
  )
  validation_key <- paste(
    as.character(validation$table), as.character(validation$fieldName),
    sep = "\u241f"
  )
  validation_rows <- validation[
    match(expected_validation_key, validation_key), validation_fields,
    drop = FALSE
  ]
  validation_rows <- data.frame(
    lapply(validation_rows, as.character), check.names = FALSE,
    stringsAsFactors = FALSE
  )
  inv_release_assert_frame_equal(
    validation_rows, INV_RELEASE_COUNT_VALIDATION,
    "raw displayed-zero validation rules"
  )

  difference <- estimated - 200 * individual
  list(
    sample_id = sample_ids[[1L]], sample_code = sample_codes[[1L]],
    site_id = site_ids[[1L]], taxonomy_rows = nrow(rows),
    taxonomy_uid_inventory_sha256 = inv_release_uid_inventory_sha256(rows),
    taxonomy_row_inventory_sha256 = inv_release_inventory_sha256(
      rows, c("sampleID", "uid")
    ),
    taxonomy_projection_sha256 = inv_release_inventory_sha256(
      rows[, c(
        "uid", "siteID", "sampleID", "sampleCode", "individualCount",
        "subsamplePercent", "estimatedTotalCount"
      ), drop = FALSE], c("sampleID", "uid")
    ),
    taxonomy_subsample_percent = unique(percent[displayed_zero])[[1L]],
    per_sample_uid = as.character(per$uid),
    per_sample_subsample_percent = per_percent,
    laboratory_name = unique(as.character(rows$laboratoryName))[[1L]],
    test_protocol_version = as.character(per$testProtocolVersion),
    target_taxa_present = unique(as.character(rows$targetTaxaPresent))[[1L]],
    sample_condition = unique(as.character(rows$sampleCondition))[[1L]],
    estimated_total_count_range = stats::setNames(
      range(estimated), c("min", "max")
    ),
    individual_count_range = stats::setNames(
      range(individual), c("min", "max")
    ),
    exact_200x_individual_rows = sum(difference == 0),
    nonexact_200x_individual_rows = sum(difference != 0),
    displayed_zero_minus_200x_range = stats::setNames(
      range(difference), c("min", "max")
    )
  )
}

inv_release_count_unavailable_audit <- function(taxonomy) {
  issue <- inv_release_raw_count_values(taxonomy)$issue
  unavailable <- taxonomy[!is.na(issue), , drop = FALSE]
  unavailable_issue <- issue[!is.na(issue)]
  projection <- c(
    "uid", "siteID", "sampleID", "sampleCode", "acceptedTaxonID",
    "individualCount", "subsamplePercent", "estimatedTotalCount",
    "targetTaxaPresent", "sampleCondition", "dataQF"
  )
  inv_release_require_columns(
    unavailable, "raw count-unavailable taxonomy inventory", projection
  )
  sample_ids <- sort(unique(as.character(unavailable$sampleID)),
                     method = "radix")
  list(
    rows = nrow(unavailable), samples = length(sample_ids),
    issue_counts = inv_release_value_counts(unavailable_issue),
    unresolved_taxonomy_rows = sum(
      inv_release_blank(unavailable$acceptedTaxonID)
    ),
    accepted_taxon_rows = sum(
      !inv_release_blank(unavailable$acceptedTaxonID)
    ),
    uid_inventory_sha256 = inv_release_uid_inventory_sha256(unavailable),
    sample_id_inventory_sha256 = inv_release_sha256_text(paste(
      sample_ids, collapse = "\n"
    )),
    row_inventory_sha256 = inv_release_inventory_sha256(
      unavailable, c("sampleID", "uid")
    ),
    projection_sha256 = inv_release_inventory_sha256(
      unavailable[, projection, drop = FALSE], c("sampleID", "uid")
    )
  )
}

inv_release_sample_identity_audit <- function(field, per_sample, taxonomy) {
  flag <- trimws(as.character(field$samplingImpractical))
  practical <- is.na(flag) | !nzchar(flag) | toupper(flag) == "OK"
  practical_field <- field[practical, , drop = FALSE]
  impractical_field <- field[!practical, , drop = FALSE]
  practical_ids <- as.character(practical_field$sampleID)
  impractical_ids <- as.character(
    impractical_field$sampleID[!inv_release_blank(impractical_field$sampleID)]
  )
  per_ids <- as.character(per_sample$sampleID)
  taxonomy_ids <- unique(as.character(taxonomy$sampleID))
  inv_release_assert(!any(inv_release_blank(practical_ids)) &&
                       !any(inv_release_blank(per_ids)) &&
                       !any(inv_release_blank(taxonomy$sampleID)) &&
                       !anyDuplicated(practical_ids) && !anyDuplicated(per_ids),
                     "Raw sampleID-primary analysis identity is missing or ambiguous")
  inv_release_assert(!length(setdiff(per_ids, practical_ids)) &&
                       !length(setdiff(taxonomy_ids, practical_ids)) &&
                       !length(intersect(impractical_ids,
                                         c(per_ids, taxonomy_ids))),
                     "Raw child relation has no practical field parent")
  assert_codes <- function(child, label) {
    field_code <- practical_field$sampleCode[
      match(as.character(child$sampleID), practical_ids)
    ]
    valid <- (inv_release_blank(child$sampleCode) &
                inv_release_blank(field_code)) |
      (!inv_release_blank(child$sampleCode) & !inv_release_blank(field_code) &
         as.character(child$sampleCode) == as.character(field_code))
    inv_release_assert(all(valid),
                       "Raw %s sampleCode disagrees with field provenance", label)
  }
  assert_codes(per_sample, "per-sample")
  assert_codes(taxonomy, "taxonomy")
  identity_fields <- c("uid", "siteID", "sampleID", "sampleCode")
  project <- function(table, keep) {
    table[keep, identity_fields, drop = FALSE]
  }
  field_without_per <- project(practical_field, !practical_ids %in% per_ids)
  taxonomy_without_per <- project(
    taxonomy, !as.character(taxonomy$sampleID) %in% per_ids
  )
  sets <- list(
    practical_blank_code = project(
      practical_field, inv_release_blank(practical_field$sampleCode)
    ),
    per_blank_code = project(
      per_sample, inv_release_blank(per_sample$sampleCode)
    ),
    taxonomy_blank_code = project(
      taxonomy, inv_release_blank(taxonomy$sampleCode)
    ),
    field_without_per = field_without_per,
    taxonomy_without_per = taxonomy_without_per
  )
  inv_release_assert(all(vapply(list(practical_field, per_sample, taxonomy),
    function(table) !any(inv_release_blank(table$uid)) &&
      !anyDuplicated(as.character(table$uid)), logical(1))),
    "Raw analysis UID inventory is missing or duplicated")
  list(
    practical_field_rows = nrow(practical_field),
    impractical_field_rows = nrow(impractical_field),
    per_sample_rows = nrow(per_sample), taxonomy_rows = nrow(taxonomy),
    processed_without_taxonomy = sum(!per_ids %in% taxonomy_ids),
    blank_sample_code_rows = c(
      inv_fieldData = nrow(sets$practical_blank_code),
      inv_persample = nrow(sets$per_blank_code),
      inv_taxonomyProcessed = nrow(sets$taxonomy_blank_code)
    ),
    practical_without_per_sample = nrow(field_without_per),
    taxonomy_without_per_sample_ids = sort(unique(
      as.character(taxonomy_without_per$sampleID)
    ), method = "radix"),
    taxonomy_without_per_sample_rows = nrow(taxonomy_without_per),
    projection_sha256 = vapply(sets, function(table) {
      inv_release_inventory_sha256(
        table,
        c("sampleID", "uid")
      )
    }, character(1)),
    uid_inventory_sha256 = vapply(
      sets, inv_release_uid_inventory_sha256, character(1)
    )
  )
}

inv_release_receipt_rows <- function(rows, columns) {
  inv_release_assert(is.list(rows), "Receipt row collection is not a list")
  data.frame(stats::setNames(lapply(columns, function(column) {
    vapply(rows, function(row) {
      value <- row[[column]]
      if (is.null(value) || !length(value)) NA_character_ else
        as.character(value[[1L]])
    }, character(1))
  }), columns), check.names = FALSE, stringsAsFactors = FALSE)
}

inv_release_assert_audit <- function(actual, expected, label) {
  inv_release_assert(identical(names(actual), names(expected)),
                     "%s members differ from the exact release audit", label)
  for (field in names(expected)) {
    if (is.list(expected[[field]]) && !is.data.frame(expected[[field]])) {
      inv_release_assert_audit(actual[[field]], expected[[field]],
                               paste(label, field))
    } else {
      actual_value <- actual[[field]]
      expected_value <- expected[[field]]
      if (is.list(actual_value) && !is.list(expected_value)) {
        actual_value <- unlist(actual_value, recursive = FALSE, use.names = TRUE)
      }
      if (length(expected_value) && !is.null(names(expected_value)) &&
          !is.null(names(actual_value))) {
        inv_release_assert(
          identical(names(actual_value), names(expected_value)),
          "%s field %s names differ from the exact release audit", label, field
        )
      }
      inv_release_assert(
        inv_release_vector_equal(actual_value, expected_value),
        "%s field %s differs from the exact release audit", label, field
      )
    }
  }
  invisible(actual)
}

inv_release_assert_source_reconciliation <- function(
    source, receipt, production_exact = TRUE) {
  field <- source$inv_fieldData
  per_sample <- source$inv_persample
  taxonomy <- source$inv_taxonomyProcessed
  variables <- source$variables_20120

  # The basic download must omit exactly the documented expanded-only fields;
  # source UID, not fabricated slide columns, is the lossless discriminator.
  metadata_columns <- names(INV_RELEASE_TAXONOMY_OMISSION_METADATA)
  inv_release_require_columns(
    variables, "raw taxonomy omission metadata", c("table", metadata_columns)
  )
  taxonomy_metadata <- variables[
    as.character(variables$table) == "inv_taxonomyProcessed", , drop = FALSE
  ]
  documented_missing <- as.character(taxonomy_metadata$fieldName[
    !as.character(taxonomy_metadata$fieldName) %in% names(taxonomy)
  ])
  inv_release_assert(
    identical(sort(documented_missing),
              sort(INV_RELEASE_TAXONOMY_OMITTED_FIELDS)) &&
      !length(intersect(INV_RELEASE_TAXONOMY_OMITTED_FIELDS,
                        names(taxonomy))),
    "Raw basic taxonomy omission set is not the exact RELEASE-2026 set"
  )
  metadata <- taxonomy_metadata[
    match(INV_RELEASE_TAXONOMY_OMITTED_FIELDS,
          as.character(taxonomy_metadata$fieldName)),
    metadata_columns, drop = FALSE
  ]
  metadata <- data.frame(lapply(metadata, as.character), check.names = FALSE,
                         stringsAsFactors = FALSE)
  inv_release_assert_frame_equal(
    metadata, INV_RELEASE_TAXONOMY_OMISSION_METADATA,
    "raw taxonomy omission metadata"
  )
  inv_release_assert(!any(inv_release_blank(taxonomy$uid)) &&
                       !anyDuplicated(as.character(taxonomy$uid)),
                     "Raw taxonomy UID surrogate is missing or duplicated")
  collision <- inv_release_taxonomy_collision_audit(taxonomy)
  if (isTRUE(production_exact)) {
    inv_release_assert_audit(
      collision, INV_RELEASE_TAXONOMY_COLLISIONS,
      "raw taxonomy UID-surrogate collision inventory"
    )
  }

  tax_receipt <- receipt$segregation$taxonomy_key_reconciliation
  inv_release_assert(
    identical(as.character(tax_receipt$status),
              "uid_surrogate_for_omitted_slide_identity") &&
      identical(as.character(tax_receipt$source_package), "basic") &&
      identical(as.character(tax_receipt$metadata_package), "expanded") &&
      identical(as.character(tax_receipt$omitted_fields),
                INV_RELEASE_TAXONOMY_OMITTED_FIELDS) &&
      identical(as.character(tax_receipt$omitted_primary_key_fields),
                c("slideID", "slideCode")) &&
      identical(as.character(tax_receipt$surrogate_field), "uid") &&
      identical(as.integer(tax_receipt$taxonomy_rows_preserved),
                nrow(taxonomy)) &&
      identical(as.integer(tax_receipt$uid_nonblank_rows), nrow(taxonomy)) &&
      identical(as.integer(tax_receipt$uid_unique_rows), nrow(taxonomy)) &&
      identical(as.integer(tax_receipt$rows_excluded_from_science), 0L),
    "Published receipt does not attest the exact taxonomy UID reconciliation"
  )
  receipt_metadata <- inv_release_receipt_rows(
    tax_receipt$metadata, metadata_columns
  )
  inv_release_assert_frame_equal(
    receipt_metadata, INV_RELEASE_TAXONOMY_OMISSION_METADATA,
    "receipt taxonomy omission metadata"
  )
  receipt_collision <- tax_receipt[names(INV_RELEASE_TAXONOMY_COLLISIONS)]
  inv_release_assert_audit(
    receipt_collision, collision, "receipt taxonomy collision inventory"
  )

  # One photo-identification laboratory record repeats the canonical FLNT
  # per-sample key. Only this exact UID pair is allowed, and all 12 taxonomy
  # children belong to the canonical morphology laboratory row.
  duplicated_key <- duplicated(per_sample[c("sampleID", "sampleCode")]) |
    duplicated(per_sample[c("sampleID", "sampleCode")], fromLast = TRUE)
  duplicate_rows <- per_sample[duplicated_key, , drop = FALSE]
  expected_aux_uid <- "25e768bb-cb13-4bb9-aa39-504aaefb4b0f"
  expected_canonical_uid <- "545d3d1b-4da6-49bc-94c3-d6ed3e9b9351"
  aux_receipt <- receipt$segregation$per_sample_quarantine
  if (!nrow(duplicate_rows)) {
    inv_release_assert(
      !isTRUE(production_exact) &&
        identical(as.character(aux_receipt$status), "not_present") &&
        identical(as.integer(aux_receipt$raw_rows_retained), 0L) &&
        identical(as.integer(aux_receipt$excluded_from_science_rows), 0L) &&
        identical(as.integer(aux_receipt$taxonomy_children), 0L),
      "Raw release is missing the exact audited FLNT auxiliary pair"
    )
    auxiliary <- per_sample[FALSE, , drop = FALSE]
  } else {
    inv_release_assert(
      nrow(duplicate_rows) == 2L &&
      identical(sort(as.character(duplicate_rows$uid)),
                sort(c(expected_aux_uid, expected_canonical_uid))) &&
      all(as.character(duplicate_rows$sampleID) ==
            "FLNT.20230315.PONAR.3") &&
      all(as.character(duplicate_rows$sampleCode) == "A00000175299"),
      "Raw per-sample duplicate is not the exact audited FLNT laboratory pair"
    )
    auxiliary <- per_sample[as.character(per_sample$uid) == expected_aux_uid,
                            , drop = FALSE]
    canonical <- per_sample[
      as.character(per_sample$uid) == expected_canonical_uid, , drop = FALSE
    ]
    inv_release_assert(
      nrow(auxiliary) == 1L && nrow(canonical) == 1L &&
      identical(as.character(auxiliary$testProtocolVersion),
                "photo_identification") &&
      identical(as.character(auxiliary$laboratoryName),
                "Jones Center At Ichauway") &&
      identical(as.character(canonical$testProtocolVersion),
                "RHITHRON_Macroinvertebrate_Identification_Revision2") &&
      identical(as.character(canonical$laboratoryName),
                "Rhithron Associates, Inc."),
      "Raw FLNT duplicate laboratory identities differ from the audited release"
    )
    flnt_children <- as.character(taxonomy$sampleID) ==
      "FLNT.20230315.PONAR.3" &
      as.character(taxonomy$sampleCode) == "A00000175299"
    inv_release_assert(sum(flnt_children) == 12L &&
                       all(as.character(taxonomy$laboratoryName[flnt_children]) ==
                             "Rhithron Associates, Inc."),
                       "Raw FLNT duplicate has an inexact taxonomy child family")
    inv_release_assert(
      identical(as.character(aux_receipt$status), "quarantined_from_science") &&
      identical(as.integer(aux_receipt$raw_rows_retained), 1L) &&
      identical(as.integer(aux_receipt$excluded_from_science_rows), 1L) &&
      identical(as.character(aux_receipt$auxiliary_uid), expected_aux_uid) &&
      identical(as.character(aux_receipt$canonical_uid), expected_canonical_uid) &&
      identical(as.character(aux_receipt$sample_id),
                "FLNT.20230315.PONAR.3") &&
      identical(as.character(aux_receipt$sample_code), "A00000175299") &&
      identical(as.integer(aux_receipt$taxonomy_children), 12L),
      "Published receipt does not attest the exact auxiliary-row quarantine"
    )
  }

  dna <- inv_release_dna_family_audit(source)
  if (isTRUE(production_exact)) {
    inv_release_assert_audit(dna$audit, INV_RELEASE_DNA_FAMILY,
                             "raw .DNA family")
  }
  dna_receipt <- receipt$segregation$dna_family_quarantine
  inv_release_assert(
    identical(as.character(dna_receipt$status),
              "quarantined_from_collection_estimand") &&
      identical(as.integer(dna_receipt$raw_rows_retained),
                sum(dna$audit$rows)) &&
      identical(as.integer(dna_receipt$excluded_from_science_rows),
                sum(dna$audit$rows)),
    "Published receipt does not attest the exact .DNA quarantine"
  )
  inv_release_assert_audit(
    dna_receipt[names(dna$audit)], dna$audit,
    "receipt .DNA family"
  )

  field_analysis <- field[!grepl("[.]DNA$", as.character(field$sampleID)),
                          , drop = FALSE]
  per_analysis <- per_sample[
    !grepl("[.]DNA$", as.character(per_sample$sampleID)) &
      !as.character(per_sample$uid) %in% as.character(auxiliary$uid),
    , drop = FALSE
  ]
  taxonomy_analysis <- taxonomy[
    !grepl("[.]DNA$", as.character(taxonomy$sampleID)), , drop = FALSE
  ]
  identity <- inv_release_sample_identity_audit(
    field_analysis, per_analysis, taxonomy_analysis
  )
  if (isTRUE(production_exact)) {
    inv_release_assert_audit(identity, INV_RELEASE_SAMPLE_IDENTITY,
                             "raw sampleID-primary relation")
  }
  inv_release_assert_audit(receipt$relations, identity,
                           "receipt sampleID-primary relation")

  unresolved <- inv_release_unresolved_audit(taxonomy_analysis)
  if (isTRUE(production_exact)) {
    inv_release_assert_audit(unresolved, INV_RELEASE_UNRESOLVED_TAXONOMY,
                             "raw unresolved taxonomy")
  }
  unresolved_receipt <- receipt$segregation$unresolved_taxonomy
  inv_release_assert(
    identical(as.character(unresolved_receipt$status),
              "retained_count_unavailable_placeholders") &&
      identical(as.integer(unresolved_receipt$rows_excluded_from_science), 0L),
    "Published receipt does not retain unresolved taxonomy as count-unavailable"
  )
  inv_release_assert_audit(
    unresolved_receipt[names(unresolved)], unresolved,
    "receipt unresolved taxonomy"
  )

  displayed_zero <- inv_release_displayed_zero_percent_audit(source)
  displayed_receipt <- receipt$segregation$displayed_zero_percent
  if (is.null(displayed_zero)) {
    inv_release_assert(
      !isTRUE(production_exact) &&
        identical(as.character(displayed_receipt$status), "not_present") &&
        identical(as.integer(displayed_receipt$raw_rows_retained), 0L) &&
        identical(
          as.integer(displayed_receipt$authoritative_estimate_rows), 0L
        ),
      paste0(
        "Raw release is missing the exact audited BARC displayed-zero ",
        "subsample family"
      )
    )
  } else {
    if (isTRUE(production_exact)) {
      inv_release_assert_audit(
        displayed_zero, INV_RELEASE_DISPLAYED_ZERO_PERCENT,
        "raw BARC displayed-zero subsample family"
      )
    }
    inv_release_assert(
      identical(
        as.character(displayed_receipt$status),
        "displayed_zero_percent_authoritative_estimate"
      ) &&
        identical(
          as.character(displayed_receipt$count_basis),
          "published_estimatedTotalCount"
        ) &&
        identical(
          as.integer(displayed_receipt$raw_rows_retained),
          displayed_zero$taxonomy_rows
        ) &&
        identical(
          as.integer(displayed_receipt$authoritative_estimate_rows),
          displayed_zero$taxonomy_rows
        ),
      paste0(
        "Published receipt does not attest the authoritative BARC ",
        "displayed-zero subsample family"
      )
    )
    inv_release_assert_audit(
      displayed_receipt[names(displayed_zero)], displayed_zero,
      "receipt BARC displayed-zero subsample family"
    )
  }

  count_unavailable <- inv_release_count_unavailable_audit(taxonomy_analysis)
  if (isTRUE(production_exact)) {
    inv_release_assert_audit(
      count_unavailable, INV_RELEASE_COUNT_UNAVAILABLE,
      "raw count-unavailable denominator"
    )
  }
  count_receipt <- receipt$segregation$count_unavailable
  inv_release_assert(
    identical(as.character(count_receipt$status),
              "retained_count_unavailable") &&
      identical(as.integer(count_receipt$rows_excluded_from_science), 0L),
    "Published receipt does not retain the count-unavailable denominator"
  )
  inv_release_assert_audit(
    count_receipt[names(count_unavailable)], count_unavailable,
    "receipt count-unavailable denominator"
  )

  expected_collection_rows <- nrow(field) - dna$audit$rows[["inv_fieldData"]]
  inv_release_assert(
    identical(as.integer(receipt$segregation$collection_field_rows),
              expected_collection_rows) &&
      identical(as.integer(receipt$segregation$metabarcode_field_rows),
                dna$audit$rows[["inv_fieldData"]]) &&
      identical(as.character(receipt$segregation$metabarcode_sample_ids),
                dna$audit$sample_ids) &&
      identical(as.character(receipt$segregation$metabarcode_site_ids),
                dna$audit$site_ids) &&
      (!isTRUE(production_exact) ||
         (identical(expected_collection_rows, 7198L) &&
            identical(dna$audit, INV_RELEASE_DNA_FAMILY))),
    "Published receipt collection/.DNA segregation is not exact"
  )

  list(
    field = field_analysis, per_sample = per_analysis,
    taxonomy = taxonomy_analysis, raw_dna = dna$subsets,
    relation = identity, unresolved = unresolved,
    displayed_zero_percent = displayed_zero,
    count_unavailable = count_unavailable
  )
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

inv_release_assert_opportunity_derivations <- function(opportunities, site) {
  required <- c(
    "sampleID", "siteID", "eventID", "aquaticSiteType", "habitatType",
    "samplerType", "samplingImpractical", "has_per_sample",
    "sampling_practical", "sampler_type_normalized", "nonstandard_id_hint",
    "grain_complete", "unstratifiable", "nonstandard_collection",
    "primary_stratum", "processing_unknown", "taxonomy_count_unavailable",
    "processing_count_status", "taxonomy_rows", "count_issue",
    "density_issue", "benthicArea_m2", "total_estimated_count",
    "count_eligible", "density_eligible", "reported_zero_count",
    "sample_density_m2", "record_status"
  )
  inv_release_require_columns(
    opportunities, paste(site, "opportunity derivation"), required
  )
  inv_release_assert(
    !anyNA(opportunities$has_per_sample) &&
      !anyNA(opportunities$taxonomy_rows) &&
      all(is.finite(inv_release_num(opportunities$taxonomy_rows))) &&
      all(inv_release_num(opportunities$taxonomy_rows) >= 0) &&
      all(inv_release_num(opportunities$taxonomy_rows) ==
            as.integer(inv_release_num(opportunities$taxonomy_rows))) &&
      all(is.na(opportunities$count_issue) |
            nzchar(as.character(opportunities$count_issue))),
    "%s opportunity primitive fields are invalid", site
  )

  practical_flag <- trimws(as.character(opportunities$samplingImpractical))
  practical <- is.na(practical_flag) | !nzchar(practical_flag) |
    toupper(practical_flag) == "OK"
  sampler_input <- as.character(opportunities$samplerType)
  sampler_input[sampler_input == "(not recorded)"] <- NA_character_
  sampler_normalized <- inv_release_normalize_sampler_type(sampler_input)
  unknown_sampler <- !is.na(sampler_normalized) &
    !sampler_normalized %in% INV_RELEASE_REVIEWED_SAMPLERS
  inv_release_assert(
    !any(unknown_sampler),
    "%s opportunity ledger contains an unreviewed samplerType", site
  )
  nonstandard_hint <- inv_release_nonstandard_id_hint(opportunities$sampleID)
  id_sampler_mismatch <- nonstandard_hint & !is.na(sampler_normalized) &
    sampler_normalized != INV_RELEASE_NONSTANDARD_SAMPLER
  inv_release_assert(
    !any(id_sampler_mismatch),
    "%s opportunity identity conflicts with its samplerType", site
  )
  grain_fields <- c(
    "siteID", "eventID", "aquaticSiteType", "habitatType", "samplerType"
  )
  grain_complete <- Reduce(`&`, lapply(
    opportunities[grain_fields], function(value) {
      !inv_release_blank(value) & as.character(value) != "(not recorded)"
    }
  ))
  unstratifiable <- !grain_complete
  nonstandard <- sampler_normalized %in% INV_RELEASE_NONSTANDARD_SAMPLER
  primary <- !nonstandard & !unstratifiable
  taxonomy_rows <- as.integer(opportunities$taxonomy_rows)
  has_per_sample <- as.logical(opportunities$has_per_sample)
  count_issue <- as.character(opportunities$count_issue)

  processing_unknown <- practical & !has_per_sample & taxonomy_rows == 0L
  taxonomy_count_unavailable <- practical & taxonomy_rows > 0L &
    !is.na(count_issue)
  processing_count_status <- rep(NA_character_, nrow(opportunities))
  processing_count_status[processing_unknown] <- "processing_unknown"
  processing_count_status[
    practical & has_per_sample & taxonomy_rows == 0L
  ] <- "processed_no_taxonomy"
  processing_count_status[taxonomy_count_unavailable] <-
    "taxonomy_count_unavailable"
  processing_count_status[
    practical & taxonomy_rows > 0L & is.na(count_issue)
  ] <- "taxonomy_count_available"

  area <- inv_release_num(opportunities$benthicArea_m2)
  total <- inv_release_num(opportunities$total_estimated_count)
  valid_area <- is.finite(area) & area > 0
  analysis_practical <- practical & primary
  count_eligible <- analysis_practical & taxonomy_rows > 0L &
    is.na(count_issue)
  density_candidates <- count_eligible & valid_area
  candidate_density <- rep(NA_real_, nrow(opportunities))
  candidate_density[density_candidates] <-
    total[density_candidates] / area[density_candidates]
  nonfinite_density <- density_candidates & !is.finite(candidate_density)
  density_issue <- rep(NA_character_, nrow(opportunities))
  density_issue[nonfinite_density] <- "nonfinite_sample_density"
  density_eligible <- density_candidates & !nonfinite_density
  sample_density <- candidate_density
  sample_density[!density_eligible] <- NA_real_
  reported_zero <- count_eligible & is.finite(total) & total == 0

  record_status <- rep(NA_character_, nrow(opportunities))
  record_status[unstratifiable] <- "unstratifiable"
  record_status[is.na(record_status) & !practical] <- "sampling_impractical"
  record_status[is.na(record_status) & nonstandard] <-
    "nonstandard_collection"
  record_status[analysis_practical & processing_unknown] <-
    "processing_unknown"
  record_status[
    analysis_practical & has_per_sample & taxonomy_rows == 0L
  ] <- "processed_no_taxonomy"
  record_status[analysis_practical & taxonomy_count_unavailable] <-
    "count_unavailable"
  record_status[
    analysis_practical & taxonomy_rows > 0L & is.na(count_issue) & !valid_area
  ] <- "area_unavailable"
  record_status[nonfinite_density] <- "density_unavailable"
  record_status[density_eligible & total > 0] <- "quantified_community"
  record_status[density_eligible & reported_zero] <- "reported_zero_count"

  expected <- list(
    sampling_practical = practical,
    sampler_type_normalized = sampler_normalized,
    nonstandard_id_hint = nonstandard_hint,
    grain_complete = grain_complete,
    unstratifiable = unstratifiable,
    nonstandard_collection = nonstandard,
    primary_stratum = primary,
    processing_unknown = processing_unknown,
    taxonomy_count_unavailable = taxonomy_count_unavailable,
    processing_count_status = processing_count_status,
    count_eligible = count_eligible,
    density_issue = density_issue,
    density_eligible = density_eligible,
    reported_zero_count = reported_zero,
    sample_density_m2 = sample_density,
    record_status = record_status
  )
  for (field in names(expected)) {
    inv_release_assert(
      inv_release_vector_equal(opportunities[[field]], expected[[field]]),
      "%s opportunity field %s differs from primitive-field derivation",
      site, field
    )
  }
  invisible(expected)
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
      n_processing_unknown = sum(part$processing_unknown),
      n_processed_no_taxonomy = inv_release_processing_status_count(
        part, "processed_no_taxonomy"
      ),
      n_taxonomy_count_unavailable = sum(
        part$taxonomy_count_unavailable
      ),
      n_displayed_zero_percent_authoritative_estimate = sum(
        part$displayed_zero_percent_authoritative_estimate
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
    n_processing_unknown = sum(opportunities$processing_unknown),
    n_processed_no_taxonomy = inv_release_processing_status_count(
      opportunities, "processed_no_taxonomy"
    ),
    n_taxonomy_count_unavailable = sum(
      opportunities$taxonomy_count_unavailable
    ),
    n_displayed_zero_percent_authoritative_estimate = sum(
      opportunities$displayed_zero_percent_authoritative_estimate
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
      levels = INV_RELEASE_PROCESSING_COUNT_STATUS_LEVELS
    )),
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
    n_processing_unknown = expected_summary$n_processing_unknown,
    n_taxonomy_count_unavailable =
      expected_summary$n_taxonomy_count_unavailable,
    n_displayed_zero_percent_authoritative_estimate =
      expected_summary$n_displayed_zero_percent_authoritative_estimate,
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
  inv_release_assert_frame_equal(
    bundle$metric_contract, inv_release_expected_metric_contract(),
    paste(site, "independent metric contract")
  )
  inv_release_assert(identical(as.character(bundle$meta$site), site),
                     "%s bundle carries meta$site=%s", site,
                     as.character(bundle$meta$site))
  inv_release_assert(identical(as.character(bundle$provenance$science_version),
                               as.character(contract$science_version)),
                     "%s science version differs from release contract", site)
  inv_release_assert(isTRUE(bundle$provenance$field_first),
                     "%s does not attest a field-first opportunity population", site)
  inv_release_assert(
    identical(as.character(bundle$meta$comparison_boundary),
              INV_RELEASE_COMPARISON_BOUNDARY) &&
      identical(as.character(bundle$provenance$exact_grain),
                INV_RELEASE_EXACT_GRAIN) &&
      identical(as.character(bundle$provenance$prohibited_inference),
                INV_RELEASE_PROHIBITED_INFERENCE),
    "%s scientific honesty/provenance boundary differs from the exact contract",
    site
  )
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
    "reported_zero_count", "processing_unknown",
    "taxonomy_count_unavailable",
    "displayed_zero_percent_authoritative_estimate",
    "processing_count_status", "has_per_sample",
    "total_estimated_count", "taxonomy_rows"
  ))
  inv_release_assert_opportunity_derivations(opportunities, site)
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
  inv_release_assert(
    all(opportunities$processing_unknown ==
          (opportunities$sampling_practical & !opportunities$has_per_sample &
             opportunities$taxonomy_rows == 0L)) &&
      all(opportunities$taxonomy_count_unavailable ==
            (opportunities$sampling_practical &
               opportunities$taxonomy_rows > 0L &
               !is.na(opportunities$count_issue))),
    "%s outcome-support booleans do not match the opportunity ledger", site
  )
  practical_processing_status <- as.character(
    opportunities$processing_count_status[opportunities$sampling_practical]
  )
  inv_release_assert(
    !anyNA(practical_processing_status) &&
      all(practical_processing_status %in%
            INV_RELEASE_PROCESSING_COUNT_STATUS_LEVELS) &&
      all(is.na(opportunities$processing_count_status[
        !opportunities$sampling_practical
      ])) &&
      length(practical_processing_status) ==
        sum(opportunities$sampling_practical),
    paste0(
      "%s practical opportunities do not have one mutually exclusive ",
      "processing/count status"
    ), site
  )

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
  inv_release_assert(
    identical(as.integer(qc$reconciliation$processing_unknown),
              sum(opportunities$processing_unknown)) &&
      identical(as.integer(qc$reconciliation$taxonomy_count_unavailable),
                sum(opportunities$taxonomy_count_unavailable)),
    "%s QC outcome-support counts do not reconcile", site
  )
  expected_processing_counts <- table(factor(
    practical_processing_status,
    levels = INV_RELEASE_PROCESSING_COUNT_STATUS_LEVELS
  ))
  inv_release_assert(
    identical(
      as.character(names(qc$reconciliation$processing_count_status_counts)),
      as.character(names(expected_processing_counts))
    ) &&
      inv_release_vector_equal(
        qc$reconciliation$processing_count_status_counts,
        expected_processing_counts
      ) &&
      identical(
        as.integer(qc$reconciliation$practical_processing_count_opportunities),
        length(practical_processing_status)
      ) &&
      identical(
        as.integer(
          qc$reconciliation$displayed_zero_percent_authoritative_estimate
        ),
        sum(opportunities$displayed_zero_percent_authoritative_estimate)
      ),
    "%s processing/count conservation ledger does not reconcile", site
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
  inv_release_assert(
    identical(
      sum(events$n_displayed_zero_percent_authoritative_estimate),
      sum(primary$displayed_zero_percent_authoritative_estimate)
    ),
    "%s event displayed-zero authoritative estimates do not reconcile", site
  )

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
    "n_unstratifiable", "n_processing_unknown",
    "n_taxonomy_count_unavailable",
    "n_displayed_zero_percent_authoritative_estimate",
    "n_taxa_recorded", "taxonomic_ranks"
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
  inv_release_assert(
    identical(as.integer(bundle$meta$n_processing_unknown),
              sum(opportunities$processing_unknown)) &&
      identical(as.integer(summary$n_processing_unknown),
                as.integer(bundle$meta$n_processing_unknown)) &&
      identical(as.integer(bundle$meta$n_taxonomy_count_unavailable),
                sum(opportunities$taxonomy_count_unavailable)) &&
      identical(as.integer(summary$n_taxonomy_count_unavailable),
                as.integer(bundle$meta$n_taxonomy_count_unavailable)),
    "%s outcome-support counts do not reconcile", site
  )
  inv_release_assert(
    identical(
      as.integer(bundle$meta$n_displayed_zero_percent_authoritative_estimate),
      sum(opportunities$displayed_zero_percent_authoritative_estimate)
    ) &&
      identical(
        as.integer(
          summary$n_displayed_zero_percent_authoritative_estimate
        ),
        as.integer(
          bundle$meta$n_displayed_zero_percent_authoritative_estimate
        )
      ),
    "%s displayed-zero authoritative estimates do not reconcile", site
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
      n_processing_unknown = as.integer(meta$n_processing_unknown),
      n_taxonomy_count_unavailable = as.integer(
        meta$n_taxonomy_count_unavailable
      ),
      n_displayed_zero_percent_authoritative_estimate = as.integer(
        meta$n_displayed_zero_percent_authoritative_estimate
      ),
      n_taxa_recorded = as.integer(meta$n_taxa_recorded),
      n_sampling_impractical = sum(!opportunities$sampling_practical),
      n_nonstandard_collection = sum(opportunities$nonstandard_collection),
      n_processed_no_taxonomy = inv_release_processing_status_count(
        opportunities, "processed_no_taxonomy"
      ),
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
      as.integer(table(factor(
        opportunities$processing_count_status[opportunities$sampling_practical],
        levels = INV_RELEASE_PROCESSING_COUNT_STATUS_LEVELS
      ))), INV_RELEASE_PROCESSING_COUNT_STATUS_LEVELS
    ),
    unresolved_taxonomy_placeholder_rows = as.integer(
      bundles[[1L]]$provenance$source$segregation$unresolved_taxonomy$rows
    ),
    unresolved_taxonomy_placeholder_samples = as.integer(
      bundles[[1L]]$provenance$source$segregation$unresolved_taxonomy$samples
    ),
    placeholder_samples_with_other_counted_taxa = as.integer(
      bundles[[1L]]$provenance$source$segregation$unresolved_taxonomy$
        samples_with_other_count_valid_taxa
    ),
    placeholder_only_samples = as.integer(
      bundles[[1L]]$provenance$source$segregation$unresolved_taxonomy$
        placeholder_only_samples
    ),
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
  inv_release_assert(
    identical(as.character(contract$producer_schema_version),
              INV_RELEASE_PRODUCER_SCHEMA_VERSION) &&
      identical(as.character(contract$bundle_schema_version),
                INV_RELEASE_BUNDLE_SCHEMA_VERSION) &&
      identical(as.character(contract$science_version),
                INV_RELEASE_SCIENCE_VERSION),
    "Release contract schema/science family is not the exact 2.1.0 family"
  )
  inv_release_assert_frame_equal(
    contract$metric_contract, inv_release_expected_metric_contract(),
    "release metric contract"
  )
  inv_release_assert(identical(as.character(contract$site_ids),
                               INV_RELEASE_EXPECTED_SITES),
                     "Release contract site roster is not canonical")
  inv_release_assert(isTRUE(contract$support_index_only),
                     "Release contract does not require a support-only index")
  inv_release_assert(
    identical(as.character(contract$prohibited_cross_site_fields),
              INV_RELEASE_PROHIBITED_CROSS_SITE_FIELDS),
    "Release contract prohibited cross-site field roster is not exact"
  )
  inv_release_assert(
    identical(contract$qc_contract, inv_release_expected_qc_contract()),
    "Release contract official QC policy is not exact"
  )
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
                         contract$qc_contract$issue_annotation_fields
                       ), INV_RELEASE_ISSUE_ANNOTATIONS) &&
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
  inv_release_validate_receipt(receipt, receipt_path)
  inv_release_assert(
    is.list(contract$source) &&
      identical(names(contract$source), INV_RELEASE_SOURCE_MEMBERS),
    "Release source-provenance member set is not exact"
  )
  publication_date_max <- as.character(contract$source$publication_date_max)
  publication_date <- inv_release_publication_dates(publication_date_max)
  synthetic_fixture <- exists(
    "INV_SYNTHETIC_FIXTURE_MODE", inherits = TRUE
  ) && isTRUE(get("INV_SYNTHETIC_FIXTURE_MODE", inherits = TRUE))
  inv_release_assert(
    length(publication_date_max) == 1L &&
      identical(as.character(publication_date), publication_date_max) &&
      (synthetic_fixture ||
         identical(publication_date_max,
                   INV_RELEASE_PUBLICATION_DATE_MAX)),
    "Release publication-date authority is invalid"
  )
  expected_source <- inv_release_expected_source_from_receipt(
    receipt, receipt_path, publication_date_max
  )
  inv_release_assert_value_equal(
    contract$source, expected_source, "Release source provenance"
  )
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
  if (!synthetic_fixture) {
    processing_status <- unlist(lapply(bundles, function(bundle) {
      as.character(bundle$opportunities$processing_count_status[
        bundle$opportunities$sampling_practical
      ])
    }), use.names = FALSE)
    processing_counts <- table(factor(
      processing_status, levels = INV_RELEASE_PROCESSING_COUNT_STATUS_LEVELS
    ))
    inv_release_assert(
      identical(
        stats::setNames(as.integer(processing_counts), names(processing_counts)),
        INV_RELEASE_PROCESSING_COUNT_OUTCOMES
      ),
      "Bundle processing/count outcomes differ from the exact RELEASE-2026 anchor"
    )
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
  inv_release_assert(identical(as.character(search$boundary),
                               INV_RELEASE_SEARCH_BOUNDARY),
                     "Search scientific boundary differs from the exact contract")
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
  has_sample <- !inv_release_blank(field$sampleID)
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
          (is.finite(subsample) & (subsample < 0 | subsample > 100))] <-
    "invalid_subsample_percent"
  issue[is.finite(estimated) & estimated < 0] <- "negative_estimated_count"
  issue[is.finite(individual) & individual < 0] <- "negative_individual_count"
  contradiction <- is.finite(estimated) & is.finite(individual) &
    estimated + sqrt(.Machine$double.eps) < individual
  issue[contradiction] <- "estimated_below_individual_count"
  issue[!is.finite(value) & is.na(issue)] <- "estimated_count_unavailable"
  value[!is.na(issue)] <- NA_real_
  list(
    value = value, issue = issue,
    displayed_zero_percent_authoritative_estimate =
      is.finite(subsample) & subsample == 0 & is.na(issue)
  )
}

inv_release_raw_collapsed_taxonomy <- function(taxonomy) {
  if (!nrow(taxonomy)) {
    return(data.frame(
      sample_key = character(), taxon_key = character(),
      acceptedTaxonID = character(), scientificName = character(),
      taxonRank = character(), order = character(), family = character(),
      class = character(), subclass = character(), estimated_count = numeric(),
      count_valid = logical(), count_issue = character(),
      displayed_zero_percent_authoritative_estimate = logical(),
      order_classified = logical(), is_ept = logical(),
      stringsAsFactors = FALSE
    ))
  }
  count <- inv_release_raw_count_values(taxonomy)
  sample_key <- inv_release_pair_key(taxonomy$sampleID, taxonomy$sampleCode)
  taxon_key <- trimws(as.character(taxonomy$acceptedTaxonID))
  unresolved <- inv_release_blank(taxon_key)
  inv_release_assert(
    !any(unresolved &
           (!is.na(inv_release_num(taxonomy$individualCount)) |
              !is.na(inv_release_num(taxonomy$estimatedTotalCount)))) &&
      !any(unresolved & inv_release_blank(taxonomy$uid)),
    paste0(
      "Raw unresolved taxonomy must have a nonblank UID and no individual ",
      "or estimated count"
    )
  )
  taxon_key[unresolved] <- paste0(
    "unresolved-source-record:", as.character(taxonomy$uid[unresolved])
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
    inv_release_assert(
      !any(conflict), "Raw source has conflicting %s values: %s", label,
      if (any(conflict)) {
        paste(unique(present_value[conflict]), collapse = ", ")
      } else ""
    )
    result
  }

  count_input <- count$value
  count_input[!is.finite(count_input)] <- 0
  estimated_count <- as.numeric(rowsum(
    count_input, group = group_id, reorder = TRUE
  ))
  invalid_groups <- unique(group_id[!is.na(count$issue)])
  count_valid <- !seq_len(n_groups) %in% invalid_groups
  count_issue <- rep(NA_character_, n_groups)
  invalid_row <- !is.na(count$issue)
  if (any(invalid_row)) {
    issue_groups <- split(count$issue[invalid_row], group_id[invalid_row])
    issue_id <- as.integer(names(issue_groups))
    count_issue[issue_id] <- vapply(
      issue_groups,
      function(issue) paste(sort(unique(issue)), collapse = ";"),
      character(1)
    )
  }
  overflow <- count_valid & !is.finite(estimated_count)
  count_valid[overflow] <- FALSE
  count_issue[overflow] <- "nonfinite_collapsed_count"
  estimated_count[!count_valid] <- NA_real_
  order_value <- strict_group_values(taxonomy$order, "order")
  out <- data.frame(
    sample_key = sample_key[first_index],
    taxon_key = taxon_key[first_index],
    acceptedTaxonID = strict_group_values(
      taxonomy$acceptedTaxonID, "acceptedTaxonID"
    ),
    scientificName = strict_group_values(
      taxonomy$scientificName, "scientificName"
    ),
    taxonRank = strict_group_values(taxonomy$taxonRank, "taxonRank"),
    order = order_value,
    family = strict_group_values(taxonomy$family, "family"),
    class = strict_group_values(taxonomy$class, "class"),
    subclass = strict_group_values(taxonomy$subclass, "subclass"),
    estimated_count = estimated_count,
    count_valid = count_valid,
    count_issue = count_issue,
    displayed_zero_percent_authoritative_estimate = as.numeric(rowsum(
      as.integer(count$displayed_zero_percent_authoritative_estimate),
      group = group_id, reorder = TRUE
    )) > 0,
    order_classified = !is.na(order_value),
    is_ept = !is.na(order_value) & tolower(order_value) %in%
      tolower(c("Ephemeroptera", "Plecoptera", "Trichoptera")),
    stringsAsFactors = FALSE
  )
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
    opportunities$primary_stratum & opportunities$count_eligible,
    c(
      "sample_key", "stratum_key", "siteID", "eventID",
      "aquaticSiteType", "habitatType", "samplerType", "density_eligible",
      "benthicArea_m2"
    ), drop = FALSE
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
  sample_index <- match(collapsed$sample_key, count_opportunities$sample_key)
  keep <- !is.na(sample_index) & collapsed$count_valid &
    is.finite(collapsed$estimated_count)
  if (!any(keep)) {
    return(inv_release_expected_raw_taxa(collapsed[FALSE, , drop = FALSE],
                                         opportunities[FALSE, , drop = FALSE]))
  }
  sample_index <- sample_index[keep]
  joined_taxon_key <- collapsed$taxon_key[keep]
  joined_count <- collapsed$estimated_count[keep]
  joined_stratum_key <- count_opportunities$stratum_key[sample_index]

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
  inv_release_assert(
    all(is.finite(taxon_total)),
    "Raw taxon total is nonfinite for an exact taxon stratum"
  )
  retained_id <- which(taxon_total > 0)
  if (!length(retained_id)) {
    return(inv_release_expected_raw_taxa(collapsed[FALSE, , drop = FALSE],
                                         opportunities[FALSE, , drop = FALSE]))
  }

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

  retained_stratum_id <- group_stratum_id[retained_id]
  stratum_row <- match(group_stratum[retained_id],
                       count_opportunities$stratum_key)
  metadata_row <- match(group_taxon[retained_id], metadata$taxon_key)
  inv_release_assert(
    !anyNA(metadata_row),
    "Raw canonical metadata is unavailable for a retained taxon stratum"
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
    acceptedTaxonID = metadata$acceptedTaxonID[metadata_row],
    scientificName = metadata$scientificName[metadata_row],
    taxonRank = metadata$taxonRank[metadata_row],
    order = metadata$order[metadata_row],
    family = metadata$family[metadata_row],
    class = metadata$class[metadata_row],
    subclass = metadata$subclass[metadata_row],
    is_ept = metadata$is_ept[metadata_row],
    order_classified = metadata$order_classified[metadata_row],
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

inv_release_raw_expected_opportunities <- function(field, per_sample,
                                                     collapsed) {
  out <- inv_release_raw_opportunity_projection(field)
  practical_flag <- trimws(as.character(field$samplingImpractical))
  practical <- is.na(practical_flag) | !nzchar(practical_flag) |
    toupper(practical_flag) == "OK"
  sampler_normalized <- inv_release_normalize_sampler_type(field$samplerType)
  unknown_sampler <- !is.na(sampler_normalized) &
    !sampler_normalized %in% INV_RELEASE_REVIEWED_SAMPLERS
  inv_release_assert(
    !any(unknown_sampler),
    "Raw field source contains an unreviewed samplerType: %s",
    if (any(unknown_sampler)) {
      as.character(field$samplerType[which(unknown_sampler)[[1L]]])
    } else ""
  )
  nonstandard_hint <- inv_release_nonstandard_id_hint(field$sampleID)
  id_sampler_mismatch <- nonstandard_hint & !is.na(sampler_normalized) &
    sampler_normalized != INV_RELEASE_NONSTANDARD_SAMPLER
  inv_release_assert(
    !any(id_sampler_mismatch),
    "Raw nonstandard sample identity conflicts with samplerType for %s",
    if (any(id_sampler_mismatch)) {
      as.character(field$sampleID[which(id_sampler_mismatch)[[1L]]])
    } else ""
  )
  grain_fields <- c(
    "siteID", "eventID", "aquaticSiteType", "habitatType", "samplerType"
  )
  grain_complete <- Reduce(
    `&`, lapply(field[grain_fields], function(value) !inv_release_blank(value))
  )
  unstratifiable <- !grain_complete
  nonstandard <- sampler_normalized %in% INV_RELEASE_NONSTANDARD_SAMPLER
  primary <- !nonstandard & !unstratifiable
  sample_key <- out$sample_key
  per_ids <- as.character(per_sample$sampleID)

  out$stratum_key <- inv_release_stratum_key(
    field$siteID, field$eventID, field$aquaticSiteType, field$habitatType,
    sampler_normalized
  )
  out$has_per_sample <- as.character(field$sampleID) %in% per_ids
  out$sampling_practical <- practical
  out$sampler_type_normalized <- sampler_normalized
  out$nonstandard_id_hint <- nonstandard_hint
  out$grain_complete <- grain_complete
  out$unstratifiable <- unstratifiable
  out$nonstandard_collection <- nonstandard
  out$primary_stratum <- primary
  out$processing_unknown <- FALSE
  out$taxonomy_count_unavailable <- FALSE
  out$displayed_zero_percent_authoritative_estimate <- FALSE
  out$processing_count_status <- rep(NA_character_, nrow(out))
  out$taxonomy_rows <- integer(nrow(out))
  out$count_issue <- rep(NA_character_, nrow(out))
  out$density_issue <- rep(NA_character_, nrow(out))
  out$total_estimated_count <- rep(NA_real_, nrow(out))
  out$count_eligible <- FALSE
  out$density_eligible <- FALSE
  out$reported_zero_count <- FALSE
  out$sample_density_m2 <- rep(NA_real_, nrow(out))
  out$taxa_observed <- rep(NA_integer_, nrow(out))
  out$ept_taxa_observed <- rep(NA_integer_, nrow(out))
  out$hill_q1 <- rep(NA_real_, nrow(out))
  out$hill_q2 <- rep(NA_real_, nrow(out))
  out$pct_ept_of_all_estimated_count <- rep(NA_real_, nrow(out))
  out$pct_order_classified_estimated_count <- rep(NA_real_, nrow(out))

  collapsed_groups <- split(
    seq_len(nrow(collapsed)), collapsed$sample_key, drop = TRUE
  )
  for (index in which(practical)) {
    part_index <- collapsed_groups[[sample_key[[index]]]]
    if (is.null(part_index)) next
    part <- collapsed[part_index, , drop = FALSE]
    out$taxonomy_rows[[index]] <- nrow(part)
    out$displayed_zero_percent_authoritative_estimate[[index]] <- any(
      part$displayed_zero_percent_authoritative_estimate
    )
    group_issues <- unique(part$count_issue[!part$count_valid])
    if (length(group_issues)) {
      out$count_issue[[index]] <- paste(
        sort(group_issues), collapse = ";"
      )
      next
    }
    sample_total <- sum(part$estimated_count)
    if (!is.finite(sample_total)) {
      out$count_issue[[index]] <- "nonfinite_sample_total"
      next
    }
    out$total_estimated_count[[index]] <- sample_total
  }

  out$processing_unknown <- practical & !out$has_per_sample &
    out$taxonomy_rows == 0L
  out$taxonomy_count_unavailable <- practical & out$taxonomy_rows > 0L &
    !is.na(out$count_issue)
  out$processing_count_status[out$processing_unknown] <- "processing_unknown"
  out$processing_count_status[
    practical & out$has_per_sample & out$taxonomy_rows == 0L
  ] <- "processed_no_taxonomy"
  out$processing_count_status[out$taxonomy_count_unavailable] <-
    "taxonomy_count_unavailable"
  out$processing_count_status[
    practical & out$taxonomy_rows > 0L & is.na(out$count_issue)
  ] <- "taxonomy_count_available"
  inv_release_assert(
    !anyNA(out$processing_count_status[practical]) &&
      all(is.na(out$processing_count_status[!practical])),
    "Raw practical processing/count outcome partition is incomplete"
  )

  valid_area <- is.finite(out$benthicArea_m2) & out$benthicArea_m2 > 0
  analysis_practical <- practical & primary
  out$count_eligible <- analysis_practical & out$taxonomy_rows > 0L &
    is.na(out$count_issue)
  density_candidates <- out$count_eligible & valid_area
  candidate_density <- rep(NA_real_, nrow(out))
  candidate_density[density_candidates] <-
    out$total_estimated_count[density_candidates] /
    out$benthicArea_m2[density_candidates]
  nonfinite_density <- density_candidates & !is.finite(candidate_density)
  out$density_issue[nonfinite_density] <- "nonfinite_sample_density"
  out$density_eligible <- density_candidates & !nonfinite_density
  out$sample_density_m2[out$density_eligible] <-
    candidate_density[out$density_eligible]
  out$reported_zero_count <- out$count_eligible &
    is.finite(out$total_estimated_count) & out$total_estimated_count == 0

  for (index in which(out$count_eligible)) {
    part_index <- collapsed_groups[[sample_key[[index]]]]
    part <- collapsed[part_index, , drop = FALSE]
    positive <- part$count_valid & is.finite(part$estimated_count) &
      part$estimated_count > 0
    counts <- part$estimated_count[positive]
    out$taxa_observed[[index]] <- sum(positive)
    out$ept_taxa_observed[[index]] <- sum(positive & part$is_ept)
    hill <- inv_release_hill(counts)
    out$hill_q1[[index]] <- hill[["q1"]]
    out$hill_q2[[index]] <- hill[["q2"]]
    total <- sum(counts)
    if (is.finite(total) && total > 0) {
      out$pct_ept_of_all_estimated_count[[index]] <-
        100 * sum(part$estimated_count[positive & part$is_ept]) / total
      out$pct_order_classified_estimated_count[[index]] <-
        100 * sum(
          part$estimated_count[positive & part$order_classified]
        ) / total
    }
  }

  out$record_status <- rep(NA_character_, nrow(out))
  out$record_status[unstratifiable] <- "unstratifiable"
  out$record_status[is.na(out$record_status) & !practical] <-
    "sampling_impractical"
  out$record_status[is.na(out$record_status) & nonstandard] <-
    "nonstandard_collection"
  out$record_status[analysis_practical & out$processing_unknown] <-
    "processing_unknown"
  out$record_status[
    analysis_practical & out$has_per_sample & out$taxonomy_rows == 0L
  ] <- "processed_no_taxonomy"
  out$record_status[
    analysis_practical & out$taxonomy_count_unavailable
  ] <- "count_unavailable"
  out$record_status[
    analysis_practical & out$taxonomy_rows > 0L & is.na(out$count_issue) &
      !valid_area
  ] <- "area_unavailable"
  out$record_status[nonfinite_density] <- "density_unavailable"
  out$record_status[
    out$density_eligible & out$total_estimated_count > 0
  ] <- "quantified_community"
  out$record_status[out$density_eligible & out$reported_zero_count] <-
    "reported_zero_count"
  inv_release_assert(!anyNA(out$record_status),
                     "Raw opportunity status projection is incomplete")
  out[, INV_RELEASE_OPPORTUNITY_COLUMNS, drop = FALSE]
}

inv_release_stream_raw_bundle_authority <- function(
    root, collection, raw_field, raw_per_sample, raw_taxonomy, issue_log,
    per_sites, tax_sites) {
  opportunity_parts <- vector("list", length(INV_RELEASE_EXPECTED_SITES))
  taxon_parts <- vector("list", length(INV_RELEASE_EXPECTED_SITES))
  names(opportunity_parts) <- INV_RELEASE_EXPECTED_SITES
  names(taxon_parts) <- INV_RELEASE_EXPECTED_SITES
  largest_full_bundle_bytes <- 0

  for (site in INV_RELEASE_EXPECTED_SITES) {
    bundle <- readRDS(file.path(root, "data", "sites", paste0(site, ".rds")))
    largest_full_bundle_bytes <- max(
      largest_full_bundle_bytes, as.numeric(utils::object.size(bundle))
    )
    source_rows <- bundle$qc$source_rows
    dna <- grepl("[.]DNA$", as.character(raw_field$sampleID))
    raw_counts <- c(
      collection_field_rows = sum(as.character(collection$siteID) == site),
      metabarcode_field_rows = sum(as.character(raw_field$siteID[dna]) == site),
      per_sample_rows = sum(per_sites == site),
      taxonomy_processed_rows = sum(tax_sites == site),
      field_qc_rows = sum(as.character(raw_field$siteID) == site),
      per_sample_qc_rows = sum(per_sites == site),
      taxonomy_qc_rows = sum(tax_sites == site),
      issue_log_rows = nrow(issue_log)
    )
    inv_release_assert(
      inv_release_vector_equal(unlist(source_rows[names(raw_counts)],
                                      use.names = FALSE), unname(raw_counts)),
      "%s source-row ledger differs from the raw artifact", site
    )
    expected_field_qc <- raw_field[as.character(raw_field$siteID) == site,
      c(INV_RELEASE_FIELD_QC_IDENTITY, INV_RELEASE_QC_FIELDS$field), drop = FALSE]
    expected_per_qc <- raw_per_sample[per_sites == site,
      c("sampleID", "sampleCode", INV_RELEASE_QC_FIELDS$per_sample), drop = FALSE]
    expected_per_qc <- data.frame(siteID = rep(site, nrow(expected_per_qc)),
                                  expected_per_qc, check.names = FALSE,
                                  stringsAsFactors = FALSE)
    tax_identity_without_site <- setdiff(INV_RELEASE_TAXONOMY_QC_IDENTITY,
                                         "siteID")
    expected_tax_qc <- raw_taxonomy[tax_sites == site,
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
    site_field <- collection[as.character(collection$siteID) == site,
                             , drop = FALSE]
    expected_issue_log <- inv_release_issue_annotations(
      issue_log, site, site_field$collectDate
    )
    inv_release_assert_frame_equal(
      bundle$qc$issue_log[
        c(INV_RELEASE_ISSUE_FIELDS, INV_RELEASE_ISSUE_ANNOTATIONS)
      ],
      expected_issue_log,
      paste(site, "raw issue log and applicability annotations")
    )
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

    # Retain only the two compact scientific projections needed by later raw
    # comparisons. Every full QC-bearing bundle is released before the next
    # site is deserialized.
    opportunity_parts[[site]] <- bundle$opportunities
    taxon_parts[[site]] <- bundle$taxon_strata
    rm(
      bundle, source_rows, raw_counts, expected_field_qc, expected_per_qc,
      expected_tax_qc, site_field, expected_issue_log, dates, water_types,
      dna
    )
    invisible(gc())
  }

  opportunities <- do.call(rbind, opportunity_parts)
  taxon_strata <- do.call(rbind, taxon_parts)
  rownames(opportunities) <- NULL
  rownames(taxon_strata) <- NULL
  rm(opportunity_parts, taxon_parts)
  invisible(gc())
  list(
    opportunities = opportunities,
    taxon_strata = taxon_strata,
    diagnostics = list(
      streamed_sites = length(INV_RELEASE_EXPECTED_SITES),
      max_full_bundles_retained = 1L,
      largest_full_bundle_bytes = largest_full_bundle_bytes
    )
  )
}

inv_verify_release_against_source <- function(root, artifact_path,
                                              source_receipt_path,
                                              production_exact = TRUE) {
  inv_verify_release_data(root)
  # The bundle-only gate intentionally materializes the complete 34-site QC
  # family. Release those objects before loading the independent raw artifact;
  # retaining both generations at once provides no additional authority.
  invisible(gc())
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
  inv_release_validate_receipt(receipt, source_receipt_path)
  artifact_info <- file.info(artifact_path)
  inv_release_assert(
    identical(basename(artifact_path), as.character(receipt$artifact$file)) &&
      nrow(artifact_info) == 1L && !is.na(artifact_info$size) &&
      identical(as.numeric(artifact_info$size),
                as.numeric(receipt$artifact$bytes)),
    "Raw artifact filename or byte size differs from the source receipt"
  )
  source <- readRDS(artifact_path)
  required <- c("inv_fieldData", "inv_persample", "inv_taxonomyProcessed",
                "issueLog_20120", "variables_20120", "validation_20120")
  inv_release_assert(is.list(source) && all(required %in% names(source)),
                     "Raw source lacks a required RELEASE-2026 table")
  synthetic_fixture <- exists(
    "INV_SYNTHETIC_FIXTURE_MODE", inherits = TRUE
  ) && isTRUE(get("INV_SYNTHETIC_FIXTURE_MODE", inherits = TRUE))
  expected_object_names <- if (synthetic_fixture) {
    INV_RELEASE_SYNTHETIC_OBJECT_NAMES
  } else INV_RELEASE_OBJECT_NAMES
  inv_release_assert(
    identical(names(source), as.character(receipt$object_names)) &&
      identical(names(source), expected_object_names),
    "Raw source object inventory differs from the source receipt"
  )
  actual_object_summaries <- lapply(source, inv_release_object_summary)
  inv_release_assert_value_equal(
    receipt$all_objects, actual_object_summaries,
    "Raw source object/schema inventory"
  )
  inv_release_assert_value_equal(
    receipt$required_tables,
    actual_object_summaries[INV_RELEASE_REQUIRED_TABLES],
    "Raw required-table schema inventory"
  )
  inv_release_assert_value_equal(
    receipt$required_metadata,
    actual_object_summaries[INV_RELEASE_REQUIRED_METADATA],
    "Raw required-metadata schema inventory"
  )
  citation_text <- paste(
    as.character(source[[INV_RELEASE_CITATION_OBJECT]]), collapse = "\n"
  )
  inv_release_assert(
    identical(citation_text, as.character(receipt$citation$text)) &&
      identical(inv_release_sha256_text(citation_text),
                as.character(receipt$citation$sha256)),
    "Raw citation object differs from the receipt citation identity"
  )
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

  publication_stamp <- inv_release_publication_stamp(source)
  expected_raw_source <- inv_release_expected_source_from_receipt(
    receipt, source_receipt_path, publication_stamp
  )
  inv_release_assert_value_equal(
    contract$source, expected_raw_source,
    "Raw receipt/artifact release source provenance"
  )

  reconciled_source <- inv_release_assert_source_reconciliation(
    source, receipt, production_exact = production_exact
  )
  field <- source$inv_fieldData
  dna <- grepl("[.]DNA$", as.character(field$sampleID))
  collection <- reconciled_source$field
  inv_release_assert(identical(sort(unique(as.character(collection$siteID))),
                               INV_RELEASE_EXPECTED_SITES),
                     "Raw collection field roster is not the canonical 34 sites")
  raw_per_sample <- source$inv_persample
  raw_taxonomy <- source$inv_taxonomyProcessed
  issue_log <- source$issueLog_20120
  analysis_per_sample <- reconciled_source$per_sample
  analysis_taxonomy <- reconciled_source$taxonomy
  pair_to_site <- stats::setNames(
    as.character(field$siteID),
    inv_release_pair_key(field$sampleID, field$sampleCode)
  )
  per_sites <- unname(pair_to_site[inv_release_pair_key(
    raw_per_sample$sampleID, raw_per_sample$sampleCode
  )])
  tax_sites <- unname(pair_to_site[inv_release_pair_key(
    raw_taxonomy$sampleID, raw_taxonomy$sampleCode
  )])
  inv_release_assert(!anyNA(per_sites) && !anyNA(tax_sites),
                     "Raw child row lacks a collection-field site mapping")

  # All receipt/schema/citation assertions above are complete. Keep only the
  # raw tables still needed for QC and the reconciled analysis tables; release
  # metadata, citation, and audit wrappers before site bundles are streamed.
  rm(
    source, reconciled_source, receipt, actual_object_summaries, variables,
    variable_key, measurement_key, index, measurement, citation_text,
    expected_raw_source, artifact_info, pair_to_site, dna
  )
  invisible(gc())

  streamed <- inv_release_stream_raw_bundle_authority(
    root, collection, field, raw_per_sample, raw_taxonomy, issue_log,
    per_sites, tax_sites
  )
  opportunities <- streamed$opportunities
  actual_taxa <- streamed$taxon_strata
  streaming_diagnostics <- streamed$diagnostics
  rm(streamed, field, raw_per_sample, raw_taxonomy, issue_log,
     per_sites, tax_sites)
  invisible(gc())

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

  collapsed <- inv_release_raw_collapsed_taxonomy(
    analysis_taxonomy
  )
  expected_raw_opportunities <- inv_release_raw_expected_opportunities(
    collection, analysis_per_sample, collapsed
  )
  rm(analysis_taxonomy, analysis_per_sample)
  invisible(gc())
  expected_raw_opportunities <- inv_release_sort_frame(
    expected_raw_opportunities, "opportunity_id"
  )
  actual_raw_opportunities <- inv_release_sort_frame(
    opportunities[, INV_RELEASE_OPPORTUNITY_COLUMNS, drop = FALSE],
    "opportunity_id"
  )
  inv_release_assert_frame_equal(
    actual_raw_opportunities, expected_raw_opportunities,
    "raw-to-bundle complete opportunity projection"
  )

  if (isTRUE(production_exact)) {
    practical <- actual_raw_opportunities$sampling_practical
    processing_counts <- table(factor(
      actual_raw_opportunities$processing_count_status[practical],
      levels = INV_RELEASE_PROCESSING_COUNT_STATUS_LEVELS
    ))
    inv_release_assert(
      identical(
        stats::setNames(as.integer(processing_counts), names(processing_counts)),
        INV_RELEASE_PROCESSING_COUNT_OUTCOMES
      ) &&
        sum(practical) == sum(INV_RELEASE_PROCESSING_COUNT_OUTCOMES) &&
        sum(actual_raw_opportunities$count_eligible) == 6213L &&
        sum(actual_raw_opportunities$density_eligible) == 6213L &&
        sum(actual_raw_opportunities$
          displayed_zero_percent_authoritative_estimate) == 1L &&
        sum(actual_raw_opportunities$reported_zero_count) == 0L,
      paste0(
        "Raw opportunity processing/count conservation differs from the ",
        "exact RELEASE-2026 denominator"
      )
    )
    barc <- actual_raw_opportunities[
      actual_raw_opportunities$sampleID %in%
        INV_RELEASE_BARC_OPPORTUNITY$sampleID,
      , drop = FALSE
    ]
    inv_release_assert(
      nrow(barc) == 1L &&
        identical(as.character(barc$record_status), "quantified_community") &&
        isTRUE(barc$displayed_zero_percent_authoritative_estimate) &&
        isTRUE(barc$count_eligible) && isTRUE(barc$density_eligible) &&
        !isTRUE(barc$reported_zero_count) &&
        all(vapply(
          setdiff(names(INV_RELEASE_BARC_OPPORTUNITY), "sampleID"),
          function(field) inv_release_vector_equal(
            barc[[field]], INV_RELEASE_BARC_OPPORTUNITY[[field]]
          ), logical(1)
        )),
      paste0(
        "BARC displayed-zero subsample opportunity differs from its exact ",
        "positive-count scientific projection"
      )
    )
  }
  expected_taxa <- inv_release_expected_raw_taxa(collapsed, opportunities)
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

  inv_release_assert(identical(
    publication_stamp,
    as.character(contract$source$publication_date_max)
  ),
                     "Raw publication stamp differs from the release contract")
  result <- list(
    artifact_sha256 = raw_sha, opportunities = nrow(opportunities),
    collapsed_taxa = nrow(collapsed), taxon_strata = nrow(actual_taxa)
  )
  attr(result, "streaming_diagnostics") <- streaming_diagnostics
  invisible(result)
}
