#!/usr/bin/env Rscript

# Pure RELEASE-2026 acquisition contract for DP1.20120.001. This file is
# intentionally independent of neonUtilities so its fixture tests can run
# without a network request or a NEON token.

INV_DPID <- "DP1.20120.001"
INV_RELEASE <- "RELEASE-2026"
INV_DOI <- "10.48443/hp56-s582"
INV_DOI_URL <- paste0("https://doi.org/", INV_DOI)
INV_RELEASE_URL <- paste0(
  "https://data.neonscience.org/data-products/", INV_DPID, "/", INV_RELEASE
)
INV_QUERY_PACKAGE <- "basic"
INV_INCLUDE_PROVISIONAL <- FALSE
INV_PRODUCER_R_VERSION <- "4.5.2"
INV_NEON_UTILITIES_VERSION <- "4.0.1"
INV_NEON_UTILITIES_SOURCE <- paste0(
  "https://packagemanager.posit.co/cran/2026-07-15/src/contrib/",
  "neonUtilities_4.0.1.tar.gz"
)
INV_RECEIPT_SCHEMA_VERSION <- "1.2.0"
INV_FETCH_EVIDENCE_SCHEMA_VERSION <- "1.0.0"
INV_SOURCE_ARTIFACT_FILE <- "DP1.20120.001_all.rds"
INV_SOURCE_RECEIPT_FILE <- "DP1.20120.001_source_receipt.json"
INV_FETCH_EVIDENCE_FILE <- "DP1.20120.001_fetch_evidence.json"
# Fixture suites set this explicitly after first asserting every production
# constant. Production acquisition, verification, and workflows leave it FALSE.
INV_SYNTHETIC_FIXTURE_MODE <- FALSE

# RELEASE-2026 contains one auxiliary photo-identification laboratory record
# whose published sampleID/sampleCode repeats the canonical benthic-sort row.
# It remains in the immutable raw source and QC evidence, but is not a second
# processed collection sample. Every discriminator below is release-exact so a
# new or changed duplicate remains a hard contract failure.
INV_AUDITED_AUXILIARY_PER_SAMPLE <- list(
  uid = "25e768bb-cb13-4bb9-aa39-504aaefb4b0f",
  siteID = "FLNT",
  collectDate = "2023-03-15 12:47:00",
  sampleID = "FLNT.20230315.PONAR.3",
  sampleCode = "A00000175299",
  testProtocolVersion = "photo_identification",
  primaryMatrix = NA_character_,
  laboratoryName = "Jones Center At Ichauway",
  sortDate = "2023-04-18",
  qcSortDate = NA_character_,
  publicationDate = "20251206T143059Z",
  release = INV_RELEASE
)
INV_AUDITED_CANONICAL_PER_SAMPLE <- list(
  uid = "545d3d1b-4da6-49bc-94c3-d6ed3e9b9351",
  siteID = "FLNT",
  collectDate = "2023-03-15 12:47:00",
  sampleID = "FLNT.20230315.PONAR.3",
  sampleCode = "A00000175299",
  testProtocolVersion =
    "RHITHRON_Macroinvertebrate_Identification_Revision2",
  primaryMatrix = "fine organic",
  laboratoryName = "Rhithron Associates, Inc.",
  sortDate = "2023-11-22",
  qcSortDate = "2023-11-27",
  publicationDate = "20251206T143059Z",
  release = INV_RELEASE
)
INV_AUDITED_PER_SAMPLE_TAXONOMY_CHILDREN <- 12L

# The basic package omits exactly eight expanded-only taxonomy columns even
# though variables_20120 documents them. Two are official primary-key fields.
# They must not be fabricated as NA identifiers: RELEASE-2026 has legitimate
# repeated non-slide identities whose distinct source records are preserved by
# globally unique NEON UIDs. The metadata, omission set, collision inventory,
# and full affected-row digest below make that reconciliation fail closed.
INV_BASIC_TAXONOMY_OMISSION_METADATA <- data.frame(
  fieldName = c(
    "vialID", "vialCode", "slideID", "slideCode", "referenceCollection",
    "referenceCount", "referenceID", "referenceCode"
  ),
  description = c(
    "Vial identifier",
    "Barcode of a vial",
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
  pubFormat = c("asIs", "asIs", "asIs", "asIs", "LOV", "integer",
                "asIs", "asIs"),
  primaryKey = c("N", "N", "Y", "Y", "N", "N", "N", "N"),
  categoricalCodeName = c(NA, NA, NA, NA, "Yes or No choice", NA, NA, NA),
  stringsAsFactors = FALSE
)
INV_OMITTED_TAXONOMY_PRIMARY_KEYS <- c("slideID", "slideCode")
INV_TAXONOMY_UID_SURROGATE <- "uid"
INV_TAXONOMY_COLLISION_EXPECTATION <- list(
  groups = 1284L,
  rows = 3683L,
  group_size_counts = c(
    `2` = 826L, `3` = 240L, `4` = 79L, `5` = 40L, `6` = 31L,
    `7` = 15L, `8` = 24L, `9` = 6L, `10` = 9L, `11` = 6L,
    `12` = 4L, `13` = 2L, `14` = 2L
  ),
  laboratory_group_counts = c(
    `EcoAnalysts Inc.` = 16L,
    `GEI Consultants Inc.` = 3L,
    `Rhithron Associates, Inc.` = 1265L
  ),
  individual_count_variant_groups = 1080L,
  estimated_total_count_variant_groups = 1083L,
  subsample_percent_variant_groups = 3L,
  inventory_sha256 =
    "b3cabe1d9ec5435c9e10f05ef49ff9b299fcab719cc03fa46fc480acd3024fb5"
)
INV_DNA_FAMILY_EXPECTATION <- list(
  sample_ids = c(
    "HOPB.20170412.SURBER.3.DNA",
    "HOPB.20170412.SURBER.4.DNA",
    "HOPB.20170412.SURBER.5.DNA"
  ),
  site_ids = "HOPB",
  rows = c(
    inv_fieldData = 3L,
    inv_persample = 3L,
    inv_taxonomyProcessed = 172L
  ),
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
INV_SAMPLE_IDENTITY_EXPECTATION <- list(
  practical_field_rows = 6485L,
  impractical_field_rows = 713L,
  per_sample_rows = 6442L,
  taxonomy_rows = 320068L,
  processed_without_taxonomy = 0L,
  blank_sample_code_rows = c(
    inv_fieldData = 1602L,
    inv_persample = 1573L,
    inv_taxonomyProcessed = 83303L
  ),
  practical_without_per_sample = 43L,
  taxonomy_without_per_sample_ids = c(
    "PRLA.20180709.BRYOZOAN.P8",
    "PRLA.20180718.BRYOZOAN.R2",
    "PRPO.20150916.SWEEP.1",
    "REDB.20151012.SURBER.4",
    "TOOK.20230726.MACROALGAE1.P7",
    "TOOK.20240726.MACROALGAE1.P10",
    "TOOK.20240726.MACROALGAE2.P2",
    "TOOK.20240726.MACROALGAE2.P4",
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
INV_UNRESOLVED_TAXONOMY_EXPECTATION <- list(
  rows = 31L,
  samples = 31L,
  target_taxa_present_counts = c(N = 31L),
  identification_remark_counts = c(
    `2nd oligochaeta slide created` = 2L,
    `<blank>` = 20L,
    `No BMI specimens present in sample` = 1L,
    `No organisms found` = 1L,
    `Oligochaeta slide created by lab with no taxon information` = 4L,
    `no individuals in sample` = 1L,
    `no organisms found` = 1L,
    `sample arrived broken and not recoverable` = 1L
  ),
  sample_condition_counts = c(
    `<blank>` = 28L,
    `damaged, affecting taxonomy` = 1L,
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
INV_DISPLAYED_ZERO_PERCENT_EXPECTATION <- list(
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
INV_COUNT_METADATA_EXPECTATION <- data.frame(
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
INV_COUNT_VALIDATION_EXPECTATION <- data.frame(
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
INV_COUNT_UNAVAILABLE_EXPECTATION <- list(
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

# Official DP1.20120.001 vF QC fields. They are evidence to retain verbatim,
# not an automatic row-exclusion rule.
INV_VF_QC_COLUMNS <- list(
  inv_fieldData = "dataQF",
  inv_persample = c(
    "dataQF", "qcSortDate", "qcSortingEfficacy", "qcIterationCount",
    "qcPercentSimilarity", "qcSortedBy", "qcEnumerationDifference",
    "qcTaxonomicDifference"
  ),
  inv_taxonomyProcessed = c("qcChecked", "dataQF")
)
INV_ISSUE_LOG_COLUMNS <- c(
  "id", "parentIssueID", "issueDate", "resolvedDate", "dateRangeStart",
  "dateRangeEnd", "locationAffected", "issue", "resolution"
)

INV_REQUIRED_TABLES <- c(
  "inv_fieldData", "inv_persample", "inv_taxonomyProcessed"
)
INV_REQUIRED_METADATA <- c(
  "categoricalCodes_20120", "issueLog_20120", "readme_20120",
  "validation_20120", "variables_20120"
)
INV_CITATION_OBJECT <- "citation_20120_RELEASE-2026"
INV_EXPECTED_SITES <- c(
  "ARIK", "BARC", "BIGC", "BLDE", "BLUE", "BLWA", "CARI", "COMO",
  "CRAM", "CUPE", "FLNT", "GUIL", "HOPB", "KING", "LECO", "LEWI",
  "LIRO", "MART", "MAYF", "MCDI", "MCRA", "OKSR", "POSE", "PRIN",
  "PRLA", "PRPO", "REDB", "SUGG", "SYCA", "TECR", "TOMB", "TOOK",
  "WALK", "WLOU"
)

# These are the RELEASE-2026 primary keys printed from variables_20120 in the
# current official NEON aquatic integration tutorial. The contract also derives
# the keys from the returned metadata and requires the two definitions to agree.
INV_PRIMARY_KEYS <- list(
  inv_fieldData = c(
    "namedLocation", "eventID", "sampleID", "sampleCode", "habitatType",
    "samplerType", "sampleNumber"
  ),
  inv_persample = c("sampleID", "sampleCode"),
  inv_taxonomyProcessed = c(
    "sampleID", "sampleCode", "slideID", "slideCode", "scientificName",
    "morphospeciesID", "invertebrateLifeStage", "sizeClass",
    "sizeCategory", "immatureSpecimen", "indeterminateSpecies",
    "taxonRankQualifier", "sampleCondition", "distinctTaxon",
    "identificationRemarks"
  )
)

# In addition to the official keys, require every field the current builder
# consumes and the provenance columns neonUtilities appends while stacking.
INV_REQUIRED_COLUMNS <- list(
  inv_fieldData = unique(c(
    INV_PRIMARY_KEYS$inv_fieldData,
    "uid", "siteID", "collectDate", "decimalLatitude", "decimalLongitude",
    "elevation", "aquaticSiteType", "benthicArea", "sampleCondition",
    "samplingImpractical", INV_VF_QC_COLUMNS$inv_fieldData,
    "publicationDate", "release"
  )),
  inv_persample = unique(c(
    INV_PRIMARY_KEYS$inv_persample, INV_VF_QC_COLUMNS$inv_persample,
    "uid", "siteID", "collectDate", "testProtocolVersion", "primaryMatrix",
    "laboratoryName", "sortDate",
    "publicationDate", "release"
  )),
  inv_taxonomyProcessed = unique(c(
    INV_PRIMARY_KEYS$inv_taxonomyProcessed,
    INV_TAXONOMY_UID_SURROGATE,
    "siteID",
    "targetTaxaPresent", "acceptedTaxonID", "taxonRank", "order", "family",
    "class", "subclass",
    "individualCount", "estimatedTotalCount", "subsamplePercent",
    "laboratoryName",
    INV_VF_QC_COLUMNS$inv_taxonomyProcessed,
    "publicationDate", "release"
  ))
)

# Release-locked measurement identities consumed by the science transform.
# These exact definitions/units are fail-closed: a future NEON metadata change
# must be reviewed before the app can continue labeling area and density as m2.
INV_MEASUREMENT_METADATA <- data.frame(
  table = c(
    "inv_fieldData", rep("inv_taxonomyProcessed", 3L)
  ),
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

inv_fail <- function(...) stop(sprintf(...), call. = FALSE)

inv_assert <- function(ok, ...) {
  if (!isTRUE(ok)) inv_fail(...)
}

inv_materialize_atomic_column <- function(column) {
  if (!is.atomic(column) || is.null(column)) return(column)
  column_attributes <- attributes(column)
  materialized <- switch(
    typeof(column),
    logical = rep(NA, length(column)),
    integer = rep(NA_integer_, length(column)),
    double = rep(NA_real_, length(column)),
    complex = rep(NA_complex_, length(column)),
    character = rep(NA_character_, length(column)),
    raw = raw(length(column)),
    inv_fail("Unsupported atomic source column type: %s", typeof(column))
  )
  materialized[] <- column
  attributes(materialized) <- column_attributes
  materialized
}

inv_materialize_data_frame <- function(frame) {
  inv_assert(is.data.frame(frame), "Source object must be a data frame")
  frame_attributes <- attributes(frame)
  if (".internal.selfref" %in% names(frame_attributes)) {
    inv_assert(
      inherits(frame, "data.table"),
      "Only data.table source frames may carry .internal.selfref"
    )
    inv_assert(
      identical(typeof(frame_attributes[[".internal.selfref"]]), "externalptr"),
      "data.table .internal.selfref must be an external pointer"
    )
    # data.table uses this live process-local pointer only to manage its
    # by-reference allocation state. R cannot preserve its address through
    # serialization, and it is not source evidence. Canonicalize that one
    # implementation attribute while retaining every scientific value, class,
    # row identity, column attribute, and ordinary frame attribute.
    frame_attributes[[".internal.selfref"]] <- NULL
  }
  columns <- lapply(frame, inv_materialize_atomic_column)
  attributes(columns) <- frame_attributes
  columns
}

inv_materialize_source <- function(source) {
  inv_assert(is.list(source), "NEON source must be a named list")
  materialized <- lapply(source, function(object) {
    if (is.data.frame(object)) {
      inv_materialize_data_frame(object)
    } else if (is.atomic(object)) {
      inv_materialize_atomic_column(object)
    } else {
      object
    }
  })
  attributes(materialized) <- attributes(source)
  materialized
}

inv_frame_columns <- function(frame, fields) {
  inv_assert(is.data.frame(frame), "Column projection source must be a data frame")
  inv_assert(length(fields) > 0L && !anyDuplicated(fields),
             "Column projection fields must be nonempty and unique")
  inv_assert(all(fields %in% names(frame)),
             "Column projection source is missing field(s): %s",
             paste(setdiff(fields, names(frame)), collapse = ", "))

  # Use [[ extraction rather than `[.data.frame` shorthand. The exact pinned
  # neonUtilities fetch returns variables_20120 as data.table/data.frame, whose
  # one-argument and symbolic-j `[` semantics differ from base data.frame. This
  # creates a read-only base view without changing the receipt-bound source class,
  # attributes, columns, values, or canonical serialized bytes.
  columns <- lapply(fields, function(field) frame[[field]])
  names(columns) <- fields
  attributes(columns) <- list(
    names = fields,
    row.names = attr(frame, "row.names"),
    class = "data.frame"
  )
  columns
}

inv_is_blank <- function(x) {
  is.na(x) | !nzchar(trimws(as.character(x)))
}

# Parse the only publication-date representations authorized for the immutable
# RELEASE-2026 source. This implementation intentionally does not share the
# producer parser: the source receipt and producer must fail closed
# independently if either contract drifts.
inv_source_publication_dates <- function(x, table_name) {
  if (inherits(x, "Date")) {
    date_value <- as.Date(x)
    raw_days <- unclass(date_value)
    parsed_dates <- rep(as.Date(NA), length(date_value))
    valid <- !is.na(raw_days) & is.finite(raw_days) & raw_days == floor(raw_days)
    if (any(valid)) {
      calendar <- format(date_value[valid], "%Y-%m-%d")
      round_trip <- suppressWarnings(as.Date(
        calendar, format = "%Y-%m-%d"
      ))
      exact <- !is.na(round_trip) & unclass(round_trip) == raw_days[valid]
      parsed_dates[which(valid)[exact]] <- round_trip[exact]
    }
  } else if (inherits(x, "POSIXt")) {
    instant <- suppressWarnings(as.POSIXct(x))
    calendar <- format(
      instant, format = "%Y-%m-%d", tz = "UTC", usetz = FALSE
    )
    parsed_dates <- suppressWarnings(as.Date(
      calendar, format = "%Y-%m-%d"
    ))
    parsed_dates[is.na(instant) | !is.finite(unclass(instant))] <- as.Date(NA)
  } else {
    parsed_dates <- rep(as.Date(NA), length(x))
    # Numeric values are deliberately unsupported: an integer such as
    # 20251206 is ambiguous with epoch-day encodings and must never authorize a
    # receipt. Factors are permitted because neonUtilities can materialize
    # character provenance as a factor under older R import settings.
    if (is.character(x) || is.factor(x)) {
      value <- as.character(x)
      compact <- !is.na(value) & grepl(
        "^[0-9]{8}T([01][0-9]|2[0-3])[0-5][0-9][0-5][0-9]Z$",
        value
      )
      iso_utc <- !is.na(value) & grepl(
        paste0(
          "^[0-9]{4}-[0-9]{2}-[0-9]{2}T",
          "([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]Z$"
        ),
        value
      )
      iso_date <- !is.na(value) & grepl(
        "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", value
      )

      parse_datetime <- function(mask, format_string) {
        rows <- which(mask)
        if (!length(rows)) return(invisible(NULL))
        instant <- suppressWarnings(strptime(
          value[rows], format = format_string, tz = "UTC"
        ))
        round_trip <- format(
          instant, format = format_string, tz = "UTC", usetz = FALSE
        )
        valid <- !is.na(instant) & !is.na(round_trip) &
          round_trip == value[rows]
        if (any(valid)) {
          calendar <- format(
            instant[valid], format = "%Y-%m-%d", tz = "UTC",
            usetz = FALSE
          )
          parsed_dates[rows[valid]] <<- as.Date(
            calendar, format = "%Y-%m-%d"
          )
        }
        invisible(NULL)
      }

      parse_datetime(compact, "%Y%m%dT%H%M%SZ")
      parse_datetime(iso_utc, "%Y-%m-%dT%H:%M:%SZ")
      date_rows <- which(iso_date)
      if (length(date_rows)) {
        date_value <- suppressWarnings(as.Date(
          value[date_rows], format = "%Y-%m-%d"
        ))
        valid <- !is.na(date_value) &
          format(date_value, "%Y-%m-%d") == value[date_rows]
        parsed_dates[date_rows[valid]] <- date_value[valid]
      }
    }
  }

  malformed <- which(is.na(parsed_dates))
  inv_assert(
    !length(malformed),
    paste0(
      "%s has malformed publicationDate at row %d; expected compact UTC ",
      "YYYYMMDDTHHMMSSZ, canonical ISO UTC YYYY-MM-DDTHH:MM:SSZ, ",
      "an intentional YYYY-MM-DD date, or a Date/POSIX value"
    ),
    table_name, if (length(malformed)) malformed[[1L]] else 0L
  )
  parsed_dates
}

inv_rows_matching_spec <- function(frame, spec, label) {
  fields <- names(spec)
  inv_assert(is.data.frame(frame), "%s source must be a data frame", label)
  inv_assert(length(fields) > 0L && all(fields %in% names(frame)),
             "%s source is missing audited discriminator(s): %s", label,
             paste(setdiff(fields, names(frame)), collapse = ", "))
  matches <- rep(TRUE, nrow(frame))
  for (field in fields) {
    expected <- spec[[field]]
    actual <- frame[[field]]
    field_match <- if (length(expected) == 1L && is.na(expected)) {
      is.na(actual)
    } else {
      !is.na(actual) & as.character(actual) == as.character(expected)
    }
    matches <- matches & field_match
  }
  which(matches)
}

inv_partition_audited_per_sample <- function(
    per_sample, taxonomy,
    synthetic_fixture = INV_SYNTHETIC_FIXTURE_MODE) {
  key_fields <- INV_PRIMARY_KEYS$inv_persample
  duplicate_mask <- duplicated(per_sample[key_fields]) |
    duplicated(per_sample[key_fields], fromLast = TRUE)
  duplicate_rows <- which(duplicate_mask)
  if (!length(duplicate_rows)) {
    inv_assert(
      isTRUE(synthetic_fixture),
      paste0(
        "Audited auxiliary FLNT photo-identification row/pair is missing from ",
        "the production RELEASE-2026 source"
      )
    )
    return(list(
      analysis = per_sample,
      auxiliary = per_sample[FALSE, , drop = FALSE],
      audit = list(
        status = "not_present",
        raw_rows_retained = 0L,
        excluded_from_science_rows = 0L,
        auxiliary_uid = INV_AUDITED_AUXILIARY_PER_SAMPLE$uid,
        canonical_uid = INV_AUDITED_CANONICAL_PER_SAMPLE$uid,
        sample_id = INV_AUDITED_AUXILIARY_PER_SAMPLE$sampleID,
        sample_code = INV_AUDITED_AUXILIARY_PER_SAMPLE$sampleCode,
        taxonomy_children = 0L
      )
    ))
  }

  inv_assert(length(duplicate_rows) == 2L,
             paste0(
               "inv_persample duplicate inventory differs from the single ",
               "audited RELEASE-2026 auxiliary pair: %d rows"
             ), length(duplicate_rows))
  duplicate_identity <- unique(per_sample[duplicate_rows, key_fields,
                                          drop = FALSE])
  inv_assert(
    nrow(duplicate_identity) == 1L &&
      identical(as.character(duplicate_identity$sampleID),
                INV_AUDITED_AUXILIARY_PER_SAMPLE$sampleID) &&
      identical(as.character(duplicate_identity$sampleCode),
                INV_AUDITED_AUXILIARY_PER_SAMPLE$sampleCode),
    paste0(
      "inv_persample duplicate RELEASE-2026 primary key is not the audited ",
      "auxiliary pair"
    )
  )

  auxiliary_row <- inv_rows_matching_spec(
    per_sample, INV_AUDITED_AUXILIARY_PER_SAMPLE,
    "audited auxiliary inv_persample"
  )
  canonical_row <- inv_rows_matching_spec(
    per_sample, INV_AUDITED_CANONICAL_PER_SAMPLE,
    "audited canonical inv_persample"
  )
  inv_assert(length(auxiliary_row) == 1L && auxiliary_row %in% duplicate_rows,
             "Audited auxiliary inv_persample row is missing or not unique")
  inv_assert(length(canonical_row) == 1L && canonical_row %in% duplicate_rows,
             "Audited canonical inv_persample row is missing or not unique")
  inv_assert(
    identical(
      sort(as.character(per_sample$uid[duplicate_rows])),
      sort(c(
        INV_AUDITED_AUXILIARY_PER_SAMPLE$uid,
        INV_AUDITED_CANONICAL_PER_SAMPLE$uid
      ))
    ),
    "inv_persample duplicate UIDs differ from the audited RELEASE-2026 pair"
  )

  taxon_match <- !inv_is_blank(taxonomy$sampleID) &
    !inv_is_blank(taxonomy$sampleCode) &
    as.character(taxonomy$sampleID) ==
      INV_AUDITED_AUXILIARY_PER_SAMPLE$sampleID &
    as.character(taxonomy$sampleCode) ==
      INV_AUDITED_AUXILIARY_PER_SAMPLE$sampleCode
  inv_assert(
    sum(taxon_match) == INV_AUDITED_PER_SAMPLE_TAXONOMY_CHILDREN,
    paste0(
      "Audited FLNT per-sample pair must have exactly %d taxonomy children; ",
      "found %d"
    ),
    INV_AUDITED_PER_SAMPLE_TAXONOMY_CHILDREN, sum(taxon_match)
  )
  taxonomy_labs <- unique(as.character(taxonomy$laboratoryName[taxon_match]))
  inv_assert(
    identical(taxonomy_labs,
              INV_AUDITED_CANONICAL_PER_SAMPLE$laboratoryName),
    "Audited FLNT taxonomy children do not all match the canonical laboratory"
  )

  analysis <- per_sample[-auxiliary_row, , drop = FALSE]
  inv_assert(!anyDuplicated(analysis[key_fields]),
             "inv_persample still has duplicate keys after exact quarantine")
  list(
    analysis = analysis,
    auxiliary = per_sample[auxiliary_row, , drop = FALSE],
    audit = list(
      status = "quarantined_from_science",
      reason = paste(
        "RELEASE-2026 auxiliary photo-identification laboratory record;",
        "raw row and QC evidence retained"
      ),
      raw_rows_retained = 1L,
      excluded_from_science_rows = 1L,
      auxiliary_uid = INV_AUDITED_AUXILIARY_PER_SAMPLE$uid,
      canonical_uid = INV_AUDITED_CANONICAL_PER_SAMPLE$uid,
      sample_id = INV_AUDITED_AUXILIARY_PER_SAMPLE$sampleID,
      sample_code = INV_AUDITED_AUXILIARY_PER_SAMPLE$sampleCode,
      taxonomy_children = INV_AUDITED_PER_SAMPLE_TAXONOMY_CHILDREN
    )
  )
}

inv_taxonomy_nonslide_primary_keys <- function() {
  setdiff(
    INV_PRIMARY_KEYS$inv_taxonomyProcessed,
    INV_OMITTED_TAXONOMY_PRIMARY_KEYS
  )
}

inv_taxonomy_order <- function(frame, fields) {
  order_values <- lapply(frame[fields], function(value) {
    value <- as.character(value)
    value[is.na(value)] <- "<NA>"
    enc2utf8(value)
  })
  do.call(order, c(order_values, list(na.last = TRUE, method = "radix")))
}

inv_frame_inventory_sha256 <- function(frame, order_fields) {
  inv_assert_required_columns(frame, "inventory frame", order_fields)
  if (nrow(frame)) {
    frame <- frame[inv_taxonomy_order(frame, order_fields), , drop = FALSE]
  }
  frame <- frame[, sort(names(frame)), drop = FALSE]
  rownames(frame) <- NULL
  inv_require_receipt_packages()
  payload <- jsonlite::toJSON(
    frame, dataframe = "rows", auto_unbox = TRUE, null = "null",
    na = "null", digits = NA, POSIXt = "ISO8601", Date = "ISO8601"
  )
  inv_sha256_text(payload)
}

inv_adjacent_rows_equal <- function(frame, fields) {
  if (nrow(frame) < 2L) return(logical())
  Reduce(`&`, lapply(frame[fields], function(value) {
    left <- value[-length(value)]
    right <- value[-1L]
    (is.na(left) & is.na(right)) |
      (!is.na(left) & !is.na(right) & as.character(left) == as.character(right))
  }))
}

inv_taxonomy_collision_inventory <- function(taxonomy) {
  base_keys <- inv_taxonomy_nonslide_primary_keys()
  duplicate_mask <- duplicated(taxonomy[base_keys]) |
    duplicated(taxonomy[base_keys], fromLast = TRUE)
  collision_rows <- which(duplicate_mask)
  collision <- taxonomy[collision_rows, , drop = FALSE]
  if (nrow(collision)) {
    collision <- collision[
      inv_taxonomy_order(
        collision, c(base_keys, INV_TAXONOMY_UID_SURROGATE)
      ),
      , drop = FALSE
    ]
    same_previous <- inv_adjacent_rows_equal(collision, base_keys)
    group_id <- cumsum(c(TRUE, !same_previous))
  } else {
    group_id <- integer()
  }

  group_sizes <- if (length(group_id)) tabulate(group_id) else integer()
  size_values <- sort(unique(group_sizes))
  group_size_counts <- stats::setNames(
    vapply(size_values, function(size) sum(group_sizes == size), integer(1)),
    as.character(size_values)
  )
  groups <- split(seq_len(nrow(collision)), group_id, drop = TRUE)
  group_labs <- vapply(groups, function(index) {
    values <- unique(as.character(collision$laboratoryName[index]))
    inv_assert(
      length(values) == 1L && !inv_is_blank(values),
      "Taxonomy non-slide identity spans missing or multiple laboratories"
    )
    values[[1L]]
  }, character(1))
  laboratory_group_counts <- if (length(group_labs)) {
    counts <- table(group_labs)
    stats::setNames(as.integer(counts), names(counts))
  } else {
    stats::setNames(integer(), character())
  }
  variant_groups <- function(field) {
    sum(vapply(groups, function(index) {
      length(unique(collision[[field]][index])) > 1L
    }, logical(1)))
  }

  list(
    groups = length(groups),
    rows = nrow(collision),
    group_size_counts = group_size_counts,
    laboratory_group_counts = laboratory_group_counts,
    individual_count_variant_groups = variant_groups("individualCount"),
    estimated_total_count_variant_groups =
      variant_groups("estimatedTotalCount"),
    subsample_percent_variant_groups = variant_groups("subsamplePercent"),
    inventory_sha256 = inv_frame_inventory_sha256(
      collision, c(base_keys, INV_TAXONOMY_UID_SURROGATE)
    )
  )
}

inv_assert_taxonomy_collision_inventory <- function(audit, expectation) {
  inv_assert(
    identical(audit$groups, expectation$groups) &&
      identical(audit$rows, expectation$rows) &&
      identical(audit$group_size_counts, expectation$group_size_counts) &&
      identical(audit$laboratory_group_counts,
                expectation$laboratory_group_counts) &&
      identical(audit$individual_count_variant_groups,
                expectation$individual_count_variant_groups) &&
      identical(audit$estimated_total_count_variant_groups,
                expectation$estimated_total_count_variant_groups) &&
      identical(audit$subsample_percent_variant_groups,
                expectation$subsample_percent_variant_groups) &&
      identical(audit$inventory_sha256, expectation$inventory_sha256),
    paste0(
      "Basic taxonomy UID-surrogate collision inventory differs from the ",
      "audited RELEASE-2026 source"
    )
  )
  invisible(audit)
}

inv_reconcile_taxonomy_primary_keys <- function(
    taxonomy, variables,
    expectation = INV_TAXONOMY_COLLISION_EXPECTATION) {
  metadata_fields <- names(INV_BASIC_TAXONOMY_OMISSION_METADATA)
  inv_assert_required_columns(
    variables, "variables_20120 taxonomy omission reconciliation",
    c("table", metadata_fields)
  )
  table_metadata <- variables[
    as.character(variables$table) == "inv_taxonomyProcessed",
    , drop = FALSE
  ]
  documented_missing <- as.character(table_metadata$fieldName[
    !as.character(table_metadata$fieldName) %in% names(taxonomy)
  ])
  expected_omitted <- INV_BASIC_TAXONOMY_OMISSION_METADATA$fieldName
  inv_assert(
    identical(sort(documented_missing), sort(expected_omitted)) &&
      !length(intersect(expected_omitted, names(taxonomy))),
    paste0(
      "Basic taxonomy source omission differs from the exact eight audited ",
      "expanded-only fields"
    )
  )
  metadata <- table_metadata[
    match(expected_omitted, as.character(table_metadata$fieldName)),
    , drop = FALSE
  ]
  metadata <- inv_frame_columns(metadata, metadata_fields)
  metadata <- data.frame(
    lapply(metadata, function(value) as.character(value)),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  inv_assert(
    identical(metadata, INV_BASIC_TAXONOMY_OMISSION_METADATA),
    paste0(
      "variables_20120 expanded-only taxonomy omission evidence differs ",
      "from RELEASE-2026"
    )
  )

  uid <- taxonomy[[INV_TAXONOMY_UID_SURROGATE]]
  inv_assert(
    !any(inv_is_blank(uid)) && !anyDuplicated(as.character(uid)),
    paste0(
      "Basic taxonomy UID surrogate must be globally nonblank and unique"
    )
  )
  base_keys <- inv_taxonomy_nonslide_primary_keys()
  all_blank <- Reduce(`&`, lapply(taxonomy[base_keys], inv_is_blank))
  inv_assert(!any(all_blank),
             "inv_taxonomyProcessed has a row with no non-slide key identity")

  collision_audit <- inv_taxonomy_collision_inventory(taxonomy)
  if (!is.null(expectation)) {
    inv_assert_taxonomy_collision_inventory(collision_audit, expectation)
  }
  list(
    analysis = taxonomy,
    audit = c(list(
      status = "uid_surrogate_for_omitted_slide_identity",
      reason = paste(
        "Basic-package source omits expanded-only slide identity; all raw",
        "taxonomy rows are preserved and source UID disambiguates collisions"
      ),
      source_package = INV_QUERY_PACKAGE,
      metadata_package = "expanded",
      omitted_fields = expected_omitted,
      omitted_primary_key_fields = INV_OMITTED_TAXONOMY_PRIMARY_KEYS,
      surrogate_field = INV_TAXONOMY_UID_SURROGATE,
      taxonomy_rows_preserved = nrow(taxonomy),
      uid_nonblank_rows = sum(!inv_is_blank(uid)),
      uid_unique_rows = length(unique(as.character(uid))),
      rows_excluded_from_science = 0L,
      metadata = INV_BASIC_TAXONOMY_OMISSION_METADATA
    ), collision_audit)
  )
}

inv_prepare_analysis_source <- function(
    source, synthetic_fixture = INV_SYNTHETIC_FIXTURE_MODE) {
  dna_family <- inv_audit_dna_family(source)
  taxonomy <- inv_reconcile_taxonomy_primary_keys(
    source$inv_taxonomyProcessed, source$variables_20120
  )
  per_sample <- inv_partition_audited_per_sample(
    source$inv_persample, taxonomy$analysis,
    synthetic_fixture = synthetic_fixture
  )
  analysis <- source
  analysis$inv_fieldData <- source$inv_fieldData[
    !inv_metabarcode_mask(source$inv_fieldData$sampleID, "inv_fieldData"),
    , drop = FALSE
  ]
  analysis$inv_persample <- per_sample$analysis[
    !inv_metabarcode_mask(per_sample$analysis$sampleID, "inv_persample"),
    , drop = FALSE
  ]
  analysis$inv_taxonomyProcessed <- taxonomy$analysis[
    !inv_metabarcode_mask(
      taxonomy$analysis$sampleID, "inv_taxonomyProcessed"
    ),
    , drop = FALSE
  ]
  unresolved_taxonomy <- inv_audit_unresolved_taxonomy(
    analysis$inv_taxonomyProcessed
  )
  displayed_zero_percent <- inv_audit_displayed_zero_percent(
    source, synthetic_fixture = synthetic_fixture
  )
  count_unavailable <- inv_audit_count_unavailable(
    analysis$inv_taxonomyProcessed, synthetic_fixture = synthetic_fixture
  )
  list(
    source = analysis,
    per_sample_quarantine = per_sample$audit,
    taxonomy_key_reconciliation = taxonomy$audit,
    dna_family_quarantine = dna_family$audit,
    displayed_zero_percent = displayed_zero_percent,
    count_unavailable = count_unavailable,
    unresolved_taxonomy = unresolved_taxonomy
  )
}

inv_metabarcode_mask <- function(sample_id, label) {
  sample_id <- as.character(sample_id)
  nonblank <- !inv_is_blank(sample_id)
  trimmed <- trimws(sample_id)
  inv_assert(!any(nonblank & sample_id != trimmed),
             "%s has sampleID values with leading/trailing whitespace", label)
  any_case <- nonblank & grepl("^.+[.]DNA$", sample_id, ignore.case = TRUE)
  canonical <- nonblank & grepl("^.+[.]DNA$", sample_id)
  inv_assert(!any(any_case & !canonical),
             "%s has a noncanonical .DNA sampleID suffix", label)
  canonical
}

inv_dna_family_inventory <- function(source) {
  table_names <- INV_REQUIRED_TABLES
  subsets <- stats::setNames(lapply(table_names, function(table_name) {
    table <- source[[table_name]]
    inv_assert_required_columns(
      table, paste(table_name, ".DNA family"),
      c("uid", "siteID", "sampleID", "sampleCode")
    )
    mask <- inv_metabarcode_mask(table$sampleID, table_name)
    out <- table[mask, , drop = FALSE]
    inv_assert(
      nrow(out) > 0L && all(inv_is_blank(out$sampleCode)),
      "%s .DNA family must exist with blank sampleCode", table_name
    )
    inv_assert(
      !any(inv_is_blank(out$uid)) && !anyDuplicated(as.character(out$uid)),
      "%s .DNA family UID inventory is blank or duplicated", table_name
    )
    out
  }), table_names)

  table_sample_ids <- lapply(subsets, function(table) {
    sort(unique(as.character(table$sampleID)), method = "radix")
  })
  inv_assert(
    all(vapply(table_sample_ids[-1L], identical, logical(1),
               table_sample_ids[[1L]])),
    ".DNA family sample identities differ across raw source tables"
  )
  table_site_ids <- lapply(subsets, function(table) {
    sort(unique(as.character(table$siteID)), method = "radix")
  })
  inv_assert(
    all(vapply(table_site_ids[-1L], identical, logical(1),
               table_site_ids[[1L]])),
    ".DNA family site identities differ across raw source tables"
  )
  sample_ids <- table_sample_ids[[1L]]
  taxonomy_counts <- table(factor(
    as.character(subsets$inv_taxonomyProcessed$sampleID), levels = sample_ids
  ))
  taxonomy_counts <- stats::setNames(
    as.integer(taxonomy_counts), names(taxonomy_counts)
  )
  uid_hashes <- vapply(subsets, function(table) {
    inv_sha256_text(paste(
      sort(as.character(table$uid), method = "radix"), collapse = "\n"
    ))
  }, character(1))
  row_hashes <- vapply(subsets, function(table) {
    inv_frame_inventory_sha256(table, c("sampleID", "uid"))
  }, character(1))
  list(
    audit = list(
      sample_ids = sample_ids,
      site_ids = table_site_ids[[1L]],
      rows = vapply(subsets, nrow, integer(1)),
      taxonomy_rows_by_sample = taxonomy_counts,
      uid_inventory_sha256 = uid_hashes,
      row_inventory_sha256 = row_hashes
    ),
    subsets = subsets
  )
}

inv_assert_dna_family_inventory <- function(audit, expectation) {
  inv_assert(
    identical(audit$sample_ids, expectation$sample_ids) &&
      identical(audit$site_ids, expectation$site_ids) &&
      identical(audit$rows, expectation$rows) &&
      identical(audit$taxonomy_rows_by_sample,
                expectation$taxonomy_rows_by_sample) &&
      identical(audit$uid_inventory_sha256,
                expectation$uid_inventory_sha256) &&
      identical(audit$row_inventory_sha256,
                expectation$row_inventory_sha256),
    ".DNA family inventory differs from the audited RELEASE-2026 source"
  )
  invisible(audit)
}

inv_audit_dna_family <- function(
    source, expectation = INV_DNA_FAMILY_EXPECTATION) {
  inventory <- inv_dna_family_inventory(source)
  if (!is.null(expectation)) {
    inv_assert_dna_family_inventory(inventory$audit, expectation)
  }
  list(
    audit = c(list(
      status = "quarantined_from_collection_estimand",
      reason = paste(
        "Published .DNA-suffixed family is retained in raw source and QC but",
        "is outside this app's morphology-based collection estimand"
      ),
      raw_rows_retained = sum(inventory$audit$rows),
      excluded_from_science_rows = sum(inventory$audit$rows)
    ), inventory$audit),
    subsets = inventory$subsets
  )
}

inv_displayed_zero_percent_inventory <- function(source) {
  taxonomy <- source$inv_taxonomyProcessed
  per_sample <- source$inv_persample
  required <- c(
    "uid", "siteID", "sampleID", "sampleCode", "targetTaxaPresent",
    "sampleCondition", "laboratoryName", "individualCount",
    "subsamplePercent", "estimatedTotalCount", "dataQF"
  )
  inv_assert_required_columns(
    taxonomy, "displayed-zero-percent taxonomy audit", required
  )
  percent <- suppressWarnings(as.numeric(taxonomy$subsamplePercent))
  displayed_zero <- is.finite(percent) & percent == 0
  rows <- taxonomy[displayed_zero, , drop = FALSE]
  if (!nrow(rows)) return(NULL)

  individual <- suppressWarnings(as.numeric(rows$individualCount))
  estimated <- suppressWarnings(as.numeric(rows$estimatedTotalCount))
  inv_assert(
    all(is.finite(individual) & individual > 0) &&
      all(is.finite(estimated) & estimated >= individual) &&
      all(as.character(rows$targetTaxaPresent) == "Y") &&
      all(as.character(rows$sampleCondition) == "condition OK") &&
      all(as.character(rows$laboratoryName) == "EcoAnalysts Inc.") &&
      all(inv_is_blank(rows$dataQF)),
    paste0(
      "Displayed-zero subsample taxonomy rows do not retain authoritative ",
      "finite published estimates under the audited source conditions"
    )
  )
  sample_ids <- unique(as.character(rows$sampleID))
  sample_codes <- unique(as.character(rows$sampleCode))
  site_ids <- unique(as.character(rows$siteID))
  inv_assert(length(sample_ids) == 1L && length(sample_codes) == 1L &&
               length(site_ids) == 1L,
             "Displayed-zero subsample taxonomy spans multiple sample identities")

  per <- per_sample[
    as.character(per_sample$sampleID) == sample_ids[[1L]] &
      as.character(per_sample$sampleCode) == sample_codes[[1L]],
    , drop = FALSE
  ]
  inv_assert_required_columns(
    per, "displayed-zero-percent per-sample audit",
    c("uid", "subsamplePercent", "laboratoryName", "testProtocolVersion", "dataQF")
  )
  per_percent <- suppressWarnings(as.numeric(per$subsamplePercent))
  inv_assert(nrow(per) == 1L && is.finite(per_percent) && per_percent > 0 &&
               per_percent <= 100 && inv_is_blank(per$dataQF),
             "Displayed-zero taxonomy lacks one valid per-sample subsample link")

  metadata_fields <- names(INV_COUNT_METADATA_EXPECTATION)
  variables <- source$variables_20120
  inv_assert_required_columns(
    variables, "displayed-zero-percent variables metadata",
    c("table", metadata_fields)
  )
  metadata_key <- paste(INV_COUNT_METADATA_EXPECTATION$table,
                        INV_COUNT_METADATA_EXPECTATION$fieldName, sep = "\u241f")
  variable_key <- paste(as.character(variables$table),
                        as.character(variables$fieldName), sep = "\u241f")
  metadata <- variables[match(metadata_key, variable_key), , drop = FALSE]
  metadata <- inv_frame_columns(metadata, metadata_fields)
  metadata <- data.frame(lapply(metadata, as.character), check.names = FALSE,
                         stringsAsFactors = FALSE)
  inv_assert(identical(metadata, INV_COUNT_METADATA_EXPECTATION),
             "Displayed-zero count metadata differs from RELEASE-2026")

  validation_fields <- names(INV_COUNT_VALIDATION_EXPECTATION)
  validation <- source$validation_20120
  inv_assert_required_columns(
    validation, "displayed-zero-percent validation metadata",
    c("table", validation_fields)
  )
  expected_validation_key <- paste(
    INV_COUNT_VALIDATION_EXPECTATION$table,
    INV_COUNT_VALIDATION_EXPECTATION$fieldName, sep = "\u241f"
  )
  validation_key <- paste(as.character(validation$table),
                          as.character(validation$fieldName), sep = "\u241f")
  validation_rows <- validation[
    match(expected_validation_key, validation_key), validation_fields,
    drop = FALSE
  ]
  validation_rows <- data.frame(
    lapply(validation_rows, as.character), check.names = FALSE,
    stringsAsFactors = FALSE
  )
  inv_assert(identical(validation_rows, INV_COUNT_VALIDATION_EXPECTATION),
             "Displayed-zero validation rules differ from RELEASE-2026")

  difference <- estimated - 200 * individual
  list(
    sample_id = sample_ids[[1L]], sample_code = sample_codes[[1L]],
    site_id = site_ids[[1L]], taxonomy_rows = nrow(rows),
    taxonomy_uid_inventory_sha256 = inv_uid_inventory_sha256(rows),
    taxonomy_row_inventory_sha256 = inv_frame_inventory_sha256(
      rows, c("sampleID", "uid")
    ),
    taxonomy_projection_sha256 = inv_frame_inventory_sha256(
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

inv_audit_displayed_zero_percent <- function(
    source, expectation = INV_DISPLAYED_ZERO_PERCENT_EXPECTATION,
    synthetic_fixture = INV_SYNTHETIC_FIXTURE_MODE) {
  audit <- inv_displayed_zero_percent_inventory(source)
  if (is.null(audit)) {
    inv_assert(
      isTRUE(synthetic_fixture),
      paste0(
        "Audited BARC displayed-zero subsample family is missing from the ",
        "production RELEASE-2026 source"
      )
    )
    return(list(
      status = "not_present", raw_rows_retained = 0L,
      authoritative_estimate_rows = 0L
    ))
  }
  if (!isTRUE(synthetic_fixture) && !is.null(expectation)) {
    inv_assert(
      identical(audit, expectation),
      paste0(
        "Displayed-zero-percent authoritative-estimate inventory differs ",
        "from the audited RELEASE-2026 source"
      )
    )
  }
  c(list(
    status = "displayed_zero_percent_authoritative_estimate",
    reason = paste(
      "Taxonomy subsamplePercent is published as integer 0 while the linked",
      "per-sample record is 0.5%; finite published estimatedTotalCount is",
      "authoritative and is never back-calculated"
    ),
    count_basis = "published_estimatedTotalCount",
    raw_rows_retained = audit$taxonomy_rows,
    authoritative_estimate_rows = audit$taxonomy_rows
  ), audit)
}

inv_source_count_issue <- function(taxonomy) {
  estimated <- suppressWarnings(as.numeric(taxonomy$estimatedTotalCount))
  individual <- suppressWarnings(as.numeric(taxonomy$individualCount))
  subsample <- suppressWarnings(as.numeric(taxonomy$subsamplePercent))
  issue <- rep(NA_character_, length(estimated))
  issue[is.infinite(estimated) | is.nan(estimated)] <-
    "nonfinite_estimated_count"
  issue[is.infinite(individual) | is.nan(individual)] <-
    "nonfinite_individual_count"
  issue[is.infinite(subsample) | is.nan(subsample) |
          (is.finite(subsample) & (subsample < 0 | subsample > 100))] <-
    "invalid_subsample_percent"
  issue[is.finite(estimated) & estimated < 0] <- "negative_estimated_count"
  issue[is.finite(individual) & individual < 0] <- "negative_individual_count"
  issue[is.finite(estimated) & is.finite(individual) &
          estimated + sqrt(.Machine$double.eps) < individual] <-
    "estimated_below_individual_count"
  issue[!is.finite(estimated) & is.na(issue)] <-
    "estimated_count_unavailable"
  issue
}

inv_count_unavailable_inventory <- function(taxonomy) {
  issue <- inv_source_count_issue(taxonomy)
  unavailable <- taxonomy[!is.na(issue), , drop = FALSE]
  unavailable_issue <- issue[!is.na(issue)]
  projection <- c(
    "uid", "siteID", "sampleID", "sampleCode", "acceptedTaxonID",
    "individualCount", "subsamplePercent", "estimatedTotalCount",
    "targetTaxaPresent", "sampleCondition", "dataQF"
  )
  inv_assert_required_columns(
    unavailable, "count-unavailable taxonomy inventory", projection
  )
  unique_sample_ids <- sort(unique(as.character(unavailable$sampleID)),
                            method = "radix")
  list(
    rows = nrow(unavailable), samples = length(unique_sample_ids),
    issue_counts = inv_inventory_value_counts(unavailable_issue),
    unresolved_taxonomy_rows = sum(inv_is_blank(unavailable$acceptedTaxonID)),
    accepted_taxon_rows = sum(!inv_is_blank(unavailable$acceptedTaxonID)),
    uid_inventory_sha256 = inv_uid_inventory_sha256(unavailable),
    sample_id_inventory_sha256 = inv_sha256_text(paste(
      unique_sample_ids, collapse = "\n"
    )),
    row_inventory_sha256 = inv_frame_inventory_sha256(
      unavailable, c("sampleID", "uid")
    ),
    projection_sha256 = inv_frame_inventory_sha256(
      unavailable[, projection, drop = FALSE], c("sampleID", "uid")
    )
  )
}

inv_audit_count_unavailable <- function(
    taxonomy, expectation = INV_COUNT_UNAVAILABLE_EXPECTATION,
    synthetic_fixture = INV_SYNTHETIC_FIXTURE_MODE) {
  audit <- inv_count_unavailable_inventory(taxonomy)
  if (!isTRUE(synthetic_fixture) && !is.null(expectation)) {
    inv_assert(
      identical(audit, expectation),
      paste0(
        "Count-unavailable taxonomy inventory differs from the audited ",
        "RELEASE-2026 denominator"
      )
    )
  }
  c(list(
    status = "retained_count_unavailable",
    reason = paste(
      "Published estimatedTotalCount is unavailable; rows remain explicit",
      "unknown outcomes and never become zero"
    ),
    rows_excluded_from_science = 0L
  ), audit)
}

inv_assert_named_data_frame <- function(x, label, allow_empty = FALSE) {
  inv_assert(is.data.frame(x), "%s must be a data frame", label)
  inv_assert(allow_empty || nrow(x) > 0L, "%s has no rows", label)
  inv_assert(!is.null(names(x)) && all(nzchar(names(x))),
             "%s has a missing column name", label)
  inv_assert(!anyDuplicated(names(x)), "%s has duplicate column names", label)
  invisible(x)
}

inv_assert_required_columns <- function(x, table_name, fields) {
  missing <- setdiff(fields, names(x))
  inv_assert(!length(missing), "%s is missing required column(s): %s",
             table_name, paste(missing, collapse = ", "))
  invisible(x)
}

inv_assert_release_rows <- function(x, table_name) {
  values <- unique(as.character(x$release))
  inv_assert(!anyNA(values) && length(values) == 1L &&
               identical(values[[1]], INV_RELEASE),
             "%s contains release values other than %s: %s", table_name,
             INV_RELEASE, paste(values, collapse = ", "))
  inv_assert("publicationDate" %in% names(x),
             "%s has no publicationDate provenance column", table_name)
  # Validate every value now, before receipt construction or any downstream
  # producer can derive a maximum publication stamp.
  inv_source_publication_dates(x$publicationDate, table_name)
  invisible(x)
}

inv_assert_primary_key <- function(x, table_name, key_fields) {
  key_frame <- x[key_fields]
  all_blank <- Reduce(`&`, lapply(key_frame, inv_is_blank))
  inv_assert(!any(all_blank), "%s has a row with no primary-key identity", table_name)
  duplicate_rows <- which(duplicated(key_frame))
  inv_assert(!length(duplicate_rows),
             "%s has duplicate RELEASE-2026 primary key(s), first repeated at row %d",
             table_name, if (length(duplicate_rows)) duplicate_rows[[1]] else 0L)
  invisible(x)
}

inv_assert_nonblank_pair <- function(x, table_name) {
  bad <- inv_is_blank(x$sampleID) | inv_is_blank(x$sampleCode)
  inv_assert(!any(bad), "%s has missing sampleID/sampleCode at row %d",
             table_name, if (any(bad)) which(bad)[[1]] else 0L)
  invisible(x)
}

inv_pair_join <- function(left, right, all_left = TRUE) {
  left <- data.frame(
    sampleID = as.character(left$sampleID),
    sampleCode = as.character(left$sampleCode),
    .left_row = seq_len(nrow(left)), stringsAsFactors = FALSE
  )
  right <- data.frame(
    sampleID = as.character(right$sampleID),
    sampleCode = as.character(right$sampleCode),
    .right_row = seq_len(nrow(right)), stringsAsFactors = FALSE
  )
  merge(left, right, by = c("sampleID", "sampleCode"),
        all.x = all_left, all.y = !all_left, sort = FALSE)
}

inv_uid_inventory_sha256 <- function(frame) {
  inv_sha256_text(paste(
    sort(as.character(frame$uid), method = "radix"), collapse = "\n"
  ))
}

inv_sample_identity_inventory <- function(field, per_sample, taxonomy) {
  sampling_flag <- trimws(as.character(field$samplingImpractical))
  practical <- is.na(sampling_flag) | !nzchar(sampling_flag) |
    toupper(sampling_flag) == "OK"
  practical_rows <- field[practical, , drop = FALSE]
  impractical_rows <- field[!practical, , drop = FALSE]
  inv_assert(!any(inv_is_blank(practical_rows$sampleID)),
             "practical inv_fieldData has a missing sampleID")
  inv_assert(!any(inv_is_blank(per_sample$sampleID)),
             "inv_persample has a missing sampleID")
  inv_assert(!any(inv_is_blank(taxonomy$sampleID)),
             "inv_taxonomyProcessed has a missing sampleID")

  practical_ids <- as.character(practical_rows$sampleID)
  impractical_ids <- as.character(
    impractical_rows$sampleID[!inv_is_blank(impractical_rows$sampleID)]
  )
  per_sample_ids <- as.character(per_sample$sampleID)
  taxonomy_ids <- unique(as.character(taxonomy$sampleID))
  inv_assert(!anyDuplicated(practical_ids),
             "practical inv_fieldData has an ambiguous repeated sampleID")
  inv_assert(!anyDuplicated(per_sample_ids),
             "inv_persample has multiple rows for one sampleID")
  orphan_per_ids <- setdiff(per_sample_ids, practical_ids)
  inv_assert(!length(orphan_per_ids),
             "inv_persample sample %s has no practical inv_fieldData parent",
             if (length(orphan_per_ids)) orphan_per_ids[[1]] else "")
  orphan_taxonomy_ids <- setdiff(taxonomy_ids, practical_ids)
  inv_assert(!length(orphan_taxonomy_ids),
             "inv_taxonomyProcessed sample %s has no practical field parent",
             if (length(orphan_taxonomy_ids)) orphan_taxonomy_ids[[1]] else "")
  impractical_children <- intersect(impractical_ids, c(per_sample_ids, taxonomy_ids))
  inv_assert(!length(impractical_children),
             "impractical inv_fieldData sample %s has a child record",
             if (length(impractical_children)) impractical_children[[1]] else "")

  assert_code_alignment <- function(child, label) {
    field_index <- match(as.character(child$sampleID), practical_ids)
    field_code <- practical_rows$sampleCode[field_index]
    both_blank <- inv_is_blank(child$sampleCode) & inv_is_blank(field_code)
    both_present_equal <- !inv_is_blank(child$sampleCode) &
      !inv_is_blank(field_code) &
      as.character(child$sampleCode) == as.character(field_code)
    valid <- both_blank | both_present_equal
    inv_assert(
      all(valid),
      "%s sampleCode disagrees with practical field provenance for sampleID %s",
      label, if (any(!valid)) as.character(child$sampleID[which(!valid)[[1]]])
      else ""
    )
  }
  assert_code_alignment(per_sample, "inv_persample")
  assert_code_alignment(taxonomy, "inv_taxonomyProcessed")

  field_without_per <- practical_rows[
    !practical_ids %in% per_sample_ids, , drop = FALSE
  ]
  taxonomy_without_per <- taxonomy[
    !as.character(taxonomy$sampleID) %in% per_sample_ids, , drop = FALSE
  ]
  identity_projection <- c("uid", "siteID", "sampleID", "sampleCode")
  inventory_sets <- list(
    practical_blank_code = practical_rows[inv_is_blank(
      practical_rows$sampleCode
    ), , drop = FALSE],
    per_blank_code = per_sample[inv_is_blank(
      per_sample$sampleCode
    ), , drop = FALSE],
    taxonomy_blank_code = taxonomy[inv_is_blank(
      taxonomy$sampleCode
    ), , drop = FALSE],
    field_without_per = field_without_per,
    taxonomy_without_per = taxonomy_without_per
  )
  for (table in list(practical_rows, per_sample, taxonomy)) {
    inv_assert(!any(inv_is_blank(table$uid)) &&
                 !anyDuplicated(as.character(table$uid)),
               "Analysis source UID inventory is blank or duplicated")
  }
  list(
    practical_field_rows = nrow(practical_rows),
    impractical_field_rows = nrow(impractical_rows),
    per_sample_rows = nrow(per_sample),
    taxonomy_rows = nrow(taxonomy),
    processed_without_taxonomy = sum(
      !per_sample_ids %in% taxonomy_ids
    ),
    blank_sample_code_rows = c(
      inv_fieldData = nrow(inventory_sets$practical_blank_code),
      inv_persample = nrow(inventory_sets$per_blank_code),
      inv_taxonomyProcessed = nrow(inventory_sets$taxonomy_blank_code)
    ),
    practical_without_per_sample = nrow(field_without_per),
    taxonomy_without_per_sample_ids = sort(unique(
      as.character(taxonomy_without_per$sampleID)
    ), method = "radix"),
    taxonomy_without_per_sample_rows = nrow(taxonomy_without_per),
    projection_sha256 = vapply(inventory_sets, function(table) {
      inv_frame_inventory_sha256(
        table[, identity_projection, drop = FALSE], c("sampleID", "uid")
      )
    }, character(1)),
    uid_inventory_sha256 = vapply(
      inventory_sets, inv_uid_inventory_sha256, character(1)
    )
  )
}

inv_assert_sample_identity_inventory <- function(audit, expectation) {
  expected_fields <- names(expectation)
  mismatched <- expected_fields[!vapply(expected_fields, function(field) {
    field %in% names(audit) && identical(audit[[field]], expectation[[field]])
  }, logical(1))]
  inv_assert(
    !length(mismatched),
    paste0(
      "sampleID-primary relationship inventory differs from the audited ",
      "RELEASE-2026 source: %s"
    ), paste(mismatched, collapse = ", ")
  )
  invisible(audit)
}

inv_validate_relations <- function(
    field, per_sample, taxonomy,
    expectation = INV_SAMPLE_IDENTITY_EXPECTATION) {
  audit <- inv_sample_identity_inventory(field, per_sample, taxonomy)
  if (!is.null(expectation)) {
    inv_assert_sample_identity_inventory(audit, expectation)
  }
  invisible(audit)
}

inv_inventory_value_counts <- function(value) {
  value <- as.character(value)
  value[inv_is_blank(value)] <- "<blank>"
  levels <- sort(unique(value), method = "radix")
  stats::setNames(
    vapply(levels, function(level) sum(value == level), integer(1)), levels
  )
}

inv_unresolved_taxonomy_inventory <- function(taxonomy) {
  placeholder <- taxonomy[inv_is_blank(taxonomy$acceptedTaxonID), , drop = FALSE]
  inv_assert(
    all(is.na(suppressWarnings(as.numeric(placeholder$individualCount)))) &&
      all(is.na(suppressWarnings(as.numeric(
        placeholder$estimatedTotalCount
      )))),
    paste0(
      "Unresolved taxonomy placeholder has a reported individual or estimated count; ",
      "review is required before taxonomy construction"
    )
  )
  sample_ids <- sort(as.character(placeholder$sampleID), method = "radix")
  sample_has_other_count <- vapply(unique(sample_ids), function(sample_id) {
    rows <- as.character(taxonomy$sampleID) == sample_id &
      !inv_is_blank(taxonomy$acceptedTaxonID) &
      is.finite(suppressWarnings(as.numeric(taxonomy$estimatedTotalCount)))
    any(rows)
  }, logical(1))
  projection <- c("uid", "siteID", "sampleID", "sampleCode")
  list(
    rows = nrow(placeholder),
    samples = length(unique(sample_ids)),
    target_taxa_present_counts = inv_inventory_value_counts(
      placeholder$targetTaxaPresent
    ),
    identification_remark_counts = inv_inventory_value_counts(
      placeholder$identificationRemarks
    ),
    sample_condition_counts = inv_inventory_value_counts(
      placeholder$sampleCondition
    ),
    samples_with_other_count_valid_taxa = sum(sample_has_other_count),
    placeholder_only_samples = sum(!sample_has_other_count),
    sample_id_inventory_sha256 = inv_sha256_text(paste(
      sample_ids, collapse = "\n"
    )),
    projection_sha256 = inv_frame_inventory_sha256(
      placeholder[, projection, drop = FALSE], c("sampleID", "uid")
    ),
    uid_inventory_sha256 = inv_uid_inventory_sha256(placeholder),
    row_inventory_sha256 = inv_frame_inventory_sha256(
      placeholder, c("sampleID", "uid")
    )
  )
}

inv_assert_unresolved_taxonomy_inventory <- function(audit, expectation) {
  inv_assert(
    identical(audit, expectation),
    paste0(
      "Unresolved count-unavailable taxonomy placeholder inventory differs ",
      "from the audited RELEASE-2026 source"
    )
  )
  invisible(audit)
}

inv_audit_unresolved_taxonomy <- function(
    taxonomy, expectation = INV_UNRESOLVED_TAXONOMY_EXPECTATION) {
  audit <- inv_unresolved_taxonomy_inventory(taxonomy)
  if (!is.null(expectation)) {
    inv_assert_unresolved_taxonomy_inventory(audit, expectation)
  }
  c(list(
    status = "retained_count_unavailable_placeholders",
    reason = paste(
      "Rows without acceptedTaxonID have no individual or estimated count;",
      "they remain explicit unresolved outcomes, never zero"
    ),
    rows_excluded_from_science = 0L
  ), audit)
}

inv_validate_variables <- function(source) {
  variables <- source$variables_20120
  inv_assert_named_data_frame(variables, "variables_20120")
  inv_assert_required_columns(
    variables, "variables_20120",
    c("table", "fieldName", "description", "dataType", "units",
      "downloadPkg", "pubFormat", "primaryKey", "categoricalCodeName")
  )
  inv_assert(!any(inv_is_blank(variables$table)) &&
               !any(inv_is_blank(variables$fieldName)),
             "variables_20120 has a missing table/fieldName identity")
  metadata_key <- inv_frame_columns(variables, c("table", "fieldName"))
  inv_assert(!anyDuplicated(metadata_key),
             "variables_20120 has duplicate table/fieldName schema rows")

  primary_values <- toupper(trimws(as.character(variables$primaryKey)))
  primary_values[is.na(primary_values)] <- ""
  invalid_primary <- setdiff(unique(primary_values), c("", "Y", "N"))
  inv_assert(!length(invalid_primary),
             "variables_20120 has unrecognized primaryKey value(s): %s",
             paste(invalid_primary, collapse = ", "))

  for (table_name in INV_REQUIRED_TABLES) {
    table_metadata <- variables[as.character(variables$table) == table_name, , drop = FALSE]
    inv_assert(nrow(table_metadata) > 0L,
               "variables_20120 has no schema for %s", table_name)
    actual_fields <- names(source[[table_name]])
    undocumented <- setdiff(actual_fields, as.character(table_metadata$fieldName))
    inv_assert(!length(undocumented),
               "variables_20120 does not document %s column(s): %s",
               table_name, paste(undocumented, collapse = ", "))

    derived_keys <- as.character(table_metadata$fieldName[
      toupper(trimws(as.character(table_metadata$primaryKey))) == "Y"
    ])
    inv_assert(identical(sort(derived_keys), sort(INV_PRIMARY_KEYS[[table_name]])),
               "variables_20120 primary keys for %s differ from the audited RELEASE-2026 contract: %s",
               table_name, paste(derived_keys, collapse = ", "))

    metadata_fields <- as.character(table_metadata$fieldName)
    metadata_qc <- metadata_fields[
      grepl("(^qc)|QF$", metadata_fields)
    ]
    expected_qc <- INV_VF_QC_COLUMNS[[table_name]]
    inv_assert(identical(sort(metadata_qc), sort(expected_qc)),
               paste0(
                 "variables_20120 QC fields for %s differ from the audited ",
                 "RELEASE-2026 vF contract: %s"
               ), table_name, paste(metadata_qc, collapse = ", "))
  }

  expected_key <- paste(INV_MEASUREMENT_METADATA$table,
                        INV_MEASUREMENT_METADATA$fieldName, sep = "\u241f")
  actual_key <- paste(as.character(variables$table),
                      as.character(variables$fieldName), sep = "\u241f")
  index <- match(expected_key, actual_key)
  inv_assert(!anyNA(index),
             "variables_20120 lacks release-locked measurement metadata")
  measurement <- data.frame(
    table = as.character(variables$table[index]),
    fieldName = as.character(variables$fieldName[index]),
    description = as.character(variables$description[index]),
    dataType = as.character(variables$dataType[index]),
    units = as.character(variables$units[index]),
    stringsAsFactors = FALSE
  )
  inv_assert(identical(measurement, INV_MEASUREMENT_METADATA),
             paste0(
               "variables_20120 release-locked measurement descriptions, ",
               "types, or units have changed"
             ))
  invisible(measurement)
}

inv_object_summary <- function(x) {
  if (is.data.frame(x)) {
    return(list(
      class = paste(class(x), collapse = "/"),
      row_count = nrow(x),
      columns = names(x),
      column_classes = as.list(vapply(
        x, function(column) paste(class(column), collapse = "/"), character(1)
      ))
    ))
  }
  list(class = paste(class(x), collapse = "/"), length = length(x))
}

inv_citation_text <- function(source) {
  citation <- source[[INV_CITATION_OBJECT]]
  inv_assert(is.character(citation) && length(citation) > 0L &&
               !all(inv_is_blank(citation)),
             "%s must be non-empty citation text", INV_CITATION_OBJECT)
  citation <- paste(citation, collapse = "\n")
  citation_lower <- tolower(citation)
  inv_assert(grepl(tolower(INV_DOI), citation_lower, fixed = TRUE),
             "%s does not contain DOI %s", INV_CITATION_OBJECT, INV_DOI)
  inv_assert(grepl(INV_DPID, citation, fixed = TRUE),
             "%s does not contain %s", INV_CITATION_OBJECT, INV_DPID)
  inv_assert(grepl(INV_RELEASE, citation, fixed = TRUE),
             "%s does not contain %s", INV_CITATION_OBJECT, INV_RELEASE)
  inv_assert(grepl(INV_RELEASE_URL, citation, fixed = TRUE),
             "%s does not contain the exact release URL", INV_CITATION_OBJECT)
  citation
}

inv_validate_source <- function(source) {
  inv_assert(is.list(source), "NEON source must be a named list")
  source_names <- names(source)
  inv_assert(!is.null(source_names) && length(source_names) == length(source) &&
               all(nzchar(source_names)),
             "NEON source has a missing object name")
  inv_assert(!anyDuplicated(source_names), "NEON source has duplicate object names")

  required_objects <- c(
    INV_REQUIRED_TABLES, INV_REQUIRED_METADATA, INV_CITATION_OBJECT
  )
  missing <- setdiff(required_objects, source_names)
  inv_assert(!length(missing), "NEON source is missing required object(s): %s",
             paste(missing, collapse = ", "))
  citation_objects <- grep("^citation_20120_", source_names, value = TRUE)
  inv_assert(identical(citation_objects, INV_CITATION_OBJECT),
             "NEON source citation inventory is not release-exact: %s",
             paste(citation_objects, collapse = ", "))

  for (object_name in source_names) {
    object <- source[[object_name]]
    if (is.data.frame(object)) {
      inv_assert_named_data_frame(object, object_name, allow_empty = TRUE)
      if ("release" %in% names(object) && nrow(object) > 0L) {
        inv_assert_release_rows(object, object_name)
      }
    }
  }

  for (table_name in INV_REQUIRED_TABLES) {
    table <- source[[table_name]]
    inv_assert_named_data_frame(table, table_name)
    required_columns <- INV_REQUIRED_COLUMNS[[table_name]]
    if (identical(table_name, "inv_taxonomyProcessed")) {
      required_columns <- setdiff(
        required_columns, INV_OMITTED_TAXONOMY_PRIMARY_KEYS
      )
    }
    inv_assert_required_columns(table, table_name, required_columns)
    inv_assert_release_rows(table, table_name)
  }

  # Metadata is evidence, not optional decoration. Empty issue/validation tables
  # are allowed, but the artifacts and their schemas must still exist.
  for (metadata_name in INV_REQUIRED_METADATA) {
    inv_assert_named_data_frame(
      source[[metadata_name]], metadata_name,
      allow_empty = metadata_name %in% c("issueLog_20120", "validation_20120")
    )
  }
  inv_assert_required_columns(
    source$issueLog_20120, "issueLog_20120", INV_ISSUE_LOG_COLUMNS
  )
  measurement_metadata <- inv_validate_variables(source)
  citation <- inv_citation_text(source)
  analysis <- inv_prepare_analysis_source(source)
  for (table_name in INV_REQUIRED_TABLES) {
    key_fields <- INV_PRIMARY_KEYS[[table_name]]
    if (identical(table_name, "inv_taxonomyProcessed")) {
      key_fields <- c(
        inv_taxonomy_nonslide_primary_keys(), INV_TAXONOMY_UID_SURROGATE
      )
    }
    inv_assert_primary_key(
      analysis$source[[table_name]], table_name,
      key_fields
    )
  }
  field_dna <- inv_metabarcode_mask(source$inv_fieldData$sampleID, "inv_fieldData")
  collection_field <- analysis$source$inv_fieldData
  metabarcode_field <- source$inv_fieldData[field_dna, , drop = FALSE]
  inv_assert(nrow(collection_field) > 0L,
             "inv_fieldData has no non-.DNA collection opportunities")
  relation_summary <- inv_validate_relations(
    collection_field, analysis$source$inv_persample,
    analysis$source$inv_taxonomyProcessed
  )
  site_ids <- unique(as.character(collection_field$siteID))
  inv_assert(!any(inv_is_blank(site_ids)) && all(grepl("^[A-Z0-9]{4}$", site_ids)),
             "non-.DNA inv_fieldData contains a missing or malformed siteID")
  observed_sites <- sort(site_ids)
  inv_assert(identical(observed_sites, INV_EXPECTED_SITES),
             "non-.DNA inv_fieldData site roster differs from the canonical 34 sites; missing=[%s] extra=[%s]",
             paste(setdiff(INV_EXPECTED_SITES, observed_sites), collapse = ", "),
             paste(setdiff(observed_sites, INV_EXPECTED_SITES), collapse = ", "))
  metabarcode_site_ids <- sort(unique(as.character(metabarcode_field$siteID)))
  metabarcode_sample_ids <- as.character(metabarcode_field$sampleID)
  if (nrow(metabarcode_field)) {
    inv_assert(!anyDuplicated(metabarcode_sample_ids),
               ".DNA inv_fieldData has an ambiguous repeated sampleID")
    inv_assert(!any(inv_is_blank(metabarcode_site_ids)) &&
                 all(grepl("^[A-Z0-9]{4}$", metabarcode_site_ids)) &&
                 !length(setdiff(metabarcode_site_ids, INV_EXPECTED_SITES)),
               ".DNA inv_fieldData contains a missing, malformed, or non-aquatic siteID")
  }
  segregation_summary <- list(
    collection_field_rows = nrow(collection_field),
    metabarcode_field_rows = nrow(metabarcode_field),
    metabarcode_sample_ids = sort(metabarcode_sample_ids),
    metabarcode_site_ids = metabarcode_site_ids,
    per_sample_quarantine = analysis$per_sample_quarantine,
    taxonomy_key_reconciliation = analysis$taxonomy_key_reconciliation,
    dna_family_quarantine = analysis$dna_family_quarantine,
    displayed_zero_percent = analysis$displayed_zero_percent,
    count_unavailable = analysis$count_unavailable,
    unresolved_taxonomy = analysis$unresolved_taxonomy
  )

  list(
    object_names = source_names,
    citation = citation,
    tables = lapply(source[INV_REQUIRED_TABLES], inv_object_summary),
    metadata = lapply(source[INV_REQUIRED_METADATA], inv_object_summary),
    all_objects = lapply(source, inv_object_summary),
    site_ids = observed_sites,
    segregation = segregation_summary,
    relations = relation_summary,
    measurement_metadata = measurement_metadata
  )
}

inv_require_receipt_packages <- function() {
  inv_assert(requireNamespace("digest", quietly = TRUE),
             "digest is required for SHA-256 source receipts")
  inv_assert(requireNamespace("jsonlite", quietly = TRUE),
             "jsonlite is required for source receipts")
  invisible(TRUE)
}

inv_sha256_file <- function(path) {
  inv_require_receipt_packages()
  inv_assert(file.exists(path) && !dir.exists(path),
             "Cannot hash missing source artifact: %s", path)
  unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
}

inv_sha256_text <- function(text) {
  inv_require_receipt_packages()
  unname(digest::digest(text, algo = "sha256", serialize = FALSE))
}

inv_assert_fetched_at_utc <- function(fetched_at_utc) {
  inv_assert(length(fetched_at_utc) == 1L && !is.na(fetched_at_utc) &&
               grepl(
                 "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$",
                 fetched_at_utc
               ),
             "fetched_at_utc must be an ISO-8601 UTC second")
  invisible(as.character(fetched_at_utc))
}

inv_assert_producer_git_sha <- function(producer_git_sha) {
  inv_assert(
    length(producer_git_sha) == 1L && !is.na(producer_git_sha) &&
      grepl("^[0-9a-f]{40}$", producer_git_sha),
    "producer git SHA must be exactly 40 lowercase hexadecimal characters"
  )
  invisible(as.character(producer_git_sha))
}

inv_exact_source_request <- function() {
  list(
    dpid = INV_DPID,
    site = "all",
    startdate = "all",
    enddate = "all",
    package = INV_QUERY_PACKAGE,
    table = "all",
    time_index = "all",
    cloud_mode = FALSE,
    release = INV_RELEASE,
    include_provisional = INV_INCLUDE_PROVISIONAL
  )
}

inv_exact_fetch_producer <- function(producer_git_sha) {
  inv_assert_producer_git_sha(producer_git_sha)
  list(
    git_sha = as.character(producer_git_sha),
    r_version = INV_PRODUCER_R_VERSION,
    neonUtilities_version = INV_NEON_UTILITIES_VERSION,
    neonUtilities_source = INV_NEON_UTILITIES_SOURCE
  )
}

inv_build_fetch_evidence <- function(artifact_path, fetched_at_utc,
                                     producer_git_sha,
                                     artifact_name = basename(artifact_path)) {
  inv_require_receipt_packages()
  inv_assert_fetched_at_utc(fetched_at_utc)
  info <- file.info(artifact_path)
  inv_assert(file.exists(artifact_path) && !dir.exists(artifact_path) &&
               nrow(info) == 1L && !is.na(info$size) && info$size > 0,
             "Cannot inspect raw fetch evidence artifact: %s", artifact_path)
  list(
    fetch_evidence_schema_version = INV_FETCH_EVIDENCE_SCHEMA_VERSION,
    evidence_kind = "unvalidated_raw_release_fetch",
    fetched_at_utc = as.character(fetched_at_utc),
    source_request = inv_exact_source_request(),
    producer = inv_exact_fetch_producer(producer_git_sha),
    artifact = list(
      file = artifact_name,
      bytes = unname(info$size),
      sha256 = inv_sha256_file(artifact_path)
    ),
    contract_validation = list(
      status = "not_yet_validated",
      authoritative_receipt_file = INV_SOURCE_RECEIPT_FILE,
      publication_authorized = FALSE
    )
  )
}

inv_build_source_receipt <- function(source, artifact_path, fetched_at_utc,
                                     producer_git_sha,
                                     artifact_name = basename(artifact_path)) {
  summary <- inv_validate_source(source)
  inv_assert_fetched_at_utc(fetched_at_utc)
  info <- file.info(artifact_path)
  inv_assert(nrow(info) == 1L && !is.na(info$size),
             "Cannot stat source artifact: %s", artifact_path)

  list(
    receipt_schema_version = INV_RECEIPT_SCHEMA_VERSION,
    fetched_at_utc = fetched_at_utc,
    source_request = inv_exact_source_request(),
    release = list(
      tag = INV_RELEASE,
      product_url = INV_RELEASE_URL,
      doi = INV_DOI,
      doi_url = INV_DOI_URL
    ),
    producer = inv_exact_fetch_producer(producer_git_sha),
    citation = list(
      object = INV_CITATION_OBJECT,
      text = summary$citation,
      sha256 = inv_sha256_text(summary$citation)
    ),
    artifact = list(
      file = artifact_name,
      bytes = unname(info$size),
      sha256 = inv_sha256_file(artifact_path)
    ),
    object_names = summary$object_names,
    required_tables = summary$tables,
    required_metadata = summary$metadata,
    all_objects = summary$all_objects,
    site_ids = summary$site_ids,
    segregation = summary$segregation,
    relations = summary$relations,
    measurement_metadata = summary$measurement_metadata
  )
}

inv_json <- function(x, pretty = FALSE) {
  inv_require_receipt_packages()
  jsonlite::toJSON(
    x, auto_unbox = TRUE, null = "null", na = "null", digits = NA,
    pretty = pretty, dataframe = "rows"
  )
}

inv_persist_fetch_evidence <- function(source, artifact_path, evidence_path,
                                       producer_git_sha,
                                       fetched_at_utc = format(
                                         Sys.time(),
                                         "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"
                                       )) {
  inv_require_receipt_packages()
  inv_assert(!file.exists(artifact_path),
             "Refusing to overwrite raw fetch artifact: %s", artifact_path)
  inv_assert(!file.exists(evidence_path),
             "Refusing to overwrite fetch evidence receipt: %s", evidence_path)
  inv_assert(dir.exists(dirname(artifact_path)),
             "Raw fetch artifact directory does not exist: %s",
             dirname(artifact_path))
  inv_assert(dir.exists(dirname(evidence_path)),
             "Fetch evidence directory does not exist: %s",
             dirname(evidence_path))
  inv_assert_fetched_at_utc(fetched_at_utc)
  inv_assert_producer_git_sha(producer_git_sha)
  source <- inv_materialize_source(source)

  artifact_tmp <- tempfile(
    pattern = paste0(".", basename(artifact_path), "."),
    tmpdir = dirname(artifact_path)
  )
  evidence_tmp <- tempfile(
    pattern = paste0(".", basename(evidence_path), "."),
    tmpdir = dirname(evidence_path)
  )
  on.exit(unlink(c(artifact_tmp, evidence_tmp), force = TRUE), add = TRUE)

  # Deliberately persist before invoking inv_validate_source(). This evidence
  # lane is never authoritative and exists so schema drift remains reviewable.
  saveRDS(source, artifact_tmp, version = 3)
  persisted_source <- readRDS(artifact_tmp)
  inv_assert(identical(persisted_source, source),
             "Portable fetch evidence changed during persisted-byte round trip")
  evidence <- inv_build_fetch_evidence(
    artifact_tmp, fetched_at_utc, producer_git_sha,
    artifact_name = basename(artifact_path)
  )
  jsonlite::write_json(
    evidence, evidence_tmp, auto_unbox = TRUE, null = "null", na = "null",
    digits = NA, pretty = TRUE
  )

  inv_assert(file.rename(artifact_tmp, artifact_path),
             "Could not atomically publish raw fetch artifact: %s",
             artifact_path)
  evidence_published <- file.rename(evidence_tmp, evidence_path)
  if (!isTRUE(evidence_published)) {
    unlink(artifact_path, force = TRUE)
    inv_fail("Could not atomically publish fetch evidence receipt: %s",
             evidence_path)
  }
  invisible(evidence)
}

inv_verify_fetch_evidence <- function(artifact_path, evidence_path) {
  inv_require_receipt_packages()
  inv_assert(file.exists(artifact_path) && !dir.exists(artifact_path),
             "Raw fetch artifact is missing: %s", artifact_path)
  inv_assert(file.exists(evidence_path) && !dir.exists(evidence_path),
             "Fetch evidence receipt is missing: %s", evidence_path)
  evidence <- jsonlite::fromJSON(
    evidence_path, simplifyVector = TRUE, simplifyDataFrame = FALSE,
    simplifyMatrix = FALSE
  )
  inv_assert(identical(as.character(
    evidence$fetch_evidence_schema_version
  ), INV_FETCH_EVIDENCE_SCHEMA_VERSION),
  "Fetch evidence schema version is not %s",
  INV_FETCH_EVIDENCE_SCHEMA_VERSION)
  expected <- inv_build_fetch_evidence(
    artifact_path, as.character(evidence$fetched_at_utc),
    as.character(evidence$producer$git_sha),
    artifact_name = basename(artifact_path)
  )
  inv_assert(identical(inv_json(evidence), inv_json(expected)),
             "Fetch evidence receipt does not match the raw artifact")
  invisible(expected)
}

inv_persist_authoritative_source_receipt <- function(
    source, artifact_path, receipt_path, producer_git_sha,
    fetched_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")) {
  inv_require_receipt_packages()
  inv_assert(file.exists(artifact_path) && !dir.exists(artifact_path),
             "Raw source artifact is missing: %s", artifact_path)
  inv_assert(!file.exists(receipt_path),
             "Refusing to overwrite immutable source receipt: %s", receipt_path)
  inv_assert(dir.exists(dirname(receipt_path)),
             "Source receipt directory does not exist: %s",
             dirname(receipt_path))
  inv_assert_fetched_at_utc(fetched_at_utc)
  inv_assert_producer_git_sha(producer_git_sha)
  inv_assert(identical(readRDS(artifact_path), source),
             "Validated source object differs from persisted raw fetch bytes")

  # inv_build_source_receipt() performs the complete authoritative contract
  # validation. A failure occurs before any receipt path is published.
  receipt <- inv_build_source_receipt(
    source, artifact_path, fetched_at_utc, producer_git_sha,
    artifact_name = basename(artifact_path)
  )
  receipt_tmp <- tempfile(
    pattern = paste0(".", basename(receipt_path), "."),
    tmpdir = dirname(receipt_path)
  )
  on.exit(unlink(receipt_tmp, force = TRUE), add = TRUE)
  jsonlite::write_json(
    receipt, receipt_tmp, auto_unbox = TRUE, null = "null", na = "null",
    digits = NA, pretty = TRUE
  )
  inv_assert(file.rename(receipt_tmp, receipt_path),
             "Could not atomically publish authoritative source receipt: %s",
             receipt_path)
  invisible(receipt)
}

inv_persist_source <- function(source, artifact_path, receipt_path,
                               producer_git_sha,
                               fetched_at_utc = format(
                                 Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"
                               )) {
  inv_require_receipt_packages()
  inv_assert(!file.exists(artifact_path),
             "Refusing to overwrite source artifact: %s", artifact_path)
  inv_assert(!file.exists(receipt_path),
             "Refusing to overwrite immutable source receipt: %s", receipt_path)
  inv_assert(dir.exists(dirname(artifact_path)),
             "Source artifact directory does not exist: %s", dirname(artifact_path))
  inv_assert(dir.exists(dirname(receipt_path)),
             "Source receipt directory does not exist: %s", dirname(receipt_path))
  inv_assert_producer_git_sha(producer_git_sha)
  source <- inv_materialize_source(source)
  inv_validate_source(source)

  artifact_tmp <- tempfile(
    pattern = paste0(".", basename(artifact_path), "."),
    tmpdir = dirname(artifact_path)
  )
  receipt_tmp <- tempfile(
    pattern = paste0(".", basename(receipt_path), "."),
    tmpdir = dirname(receipt_path)
  )
  on.exit(unlink(c(artifact_tmp, receipt_tmp), force = TRUE), add = TRUE)

  saveRDS(source, artifact_tmp, version = 3)
  persisted_source <- readRDS(artifact_tmp)
  inv_assert(identical(persisted_source, source),
             "Portable source changed during the persisted-byte round trip")
  inv_validate_source(persisted_source)
  receipt <- inv_build_source_receipt(
    persisted_source, artifact_tmp, fetched_at_utc, producer_git_sha,
    artifact_name = basename(artifact_path)
  )
  jsonlite::write_json(
    receipt, receipt_tmp, auto_unbox = TRUE, null = "null", na = "null",
    digits = NA, pretty = TRUE
  )

  inv_assert(file.rename(artifact_tmp, artifact_path),
             "Could not atomically publish source artifact: %s", artifact_path)
  inv_assert(file.rename(receipt_tmp, receipt_path),
             "Could not atomically publish source receipt: %s", receipt_path)
  invisible(receipt)
}

inv_verify_source_receipt <- function(artifact_path, receipt_path) {
  inv_require_receipt_packages()
  inv_assert(file.exists(artifact_path), "Source artifact is missing: %s", artifact_path)
  inv_assert(file.exists(receipt_path), "Source receipt is missing: %s", receipt_path)
  receipt <- jsonlite::fromJSON(
    receipt_path, simplifyVector = TRUE, simplifyDataFrame = FALSE,
    simplifyMatrix = FALSE
  )
  inv_assert(identical(as.character(receipt$receipt_schema_version),
                       INV_RECEIPT_SCHEMA_VERSION),
             "Source receipt schema version is not %s", INV_RECEIPT_SCHEMA_VERSION)
  fetched_at <- as.character(receipt$fetched_at_utc)
  source <- readRDS(artifact_path)
  expected <- inv_build_source_receipt(
    source, artifact_path, fetched_at, as.character(receipt$producer$git_sha),
    artifact_name = basename(artifact_path)
  )
  inv_assert(identical(inv_json(receipt), inv_json(expected)),
             "Source receipt does not match the RELEASE-2026 artifact contract")
  invisible(expected)
}

inv_verify_fetch_source_handoff <- function(artifact_path, evidence_path,
                                             receipt_path) {
  evidence <- inv_verify_fetch_evidence(artifact_path, evidence_path)
  receipt <- inv_verify_source_receipt(artifact_path, receipt_path)
  inv_assert(
    identical(as.character(evidence$artifact$sha256),
              as.character(receipt$artifact$sha256)),
    "Fetch evidence and source receipt artifact hashes differ"
  )
  inv_assert(
    identical(as.character(evidence$fetched_at_utc),
              as.character(receipt$fetched_at_utc)),
    "Fetch evidence and source receipt fetch times differ"
  )
  inv_assert(
    identical(inv_json(evidence$source_request),
              inv_json(receipt$source_request)),
    "Fetch evidence and source receipt requests differ"
  )
  inv_assert(
    identical(as.character(evidence$producer$git_sha),
              as.character(receipt$producer$git_sha)),
    "Fetch evidence and source receipt producer git SHAs differ"
  )
  invisible(list(evidence = evidence, receipt = receipt))
}

inv_assert_fetch_runtime <- function() {
  inv_assert(identical(as.character(getRversion()), INV_PRODUCER_R_VERSION),
             "fetch_inv_all.R requires R %s exactly; running %s",
             INV_PRODUCER_R_VERSION, as.character(getRversion()))
  inv_assert(requireNamespace("neonUtilities", quietly = TRUE),
             "neonUtilities %s is required", INV_NEON_UTILITIES_VERSION)
  actual <- as.character(utils::packageVersion("neonUtilities"))
  inv_assert(identical(actual, INV_NEON_UTILITIES_VERSION),
             "fetch_inv_all.R requires neonUtilities %s exactly; running %s",
             INV_NEON_UTILITIES_VERSION, actual)
  invisible(TRUE)
}
