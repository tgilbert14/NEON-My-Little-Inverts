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
INV_RECEIPT_SCHEMA_VERSION <- "1.1.0"
INV_FETCH_EVIDENCE_SCHEMA_VERSION <- "1.0.0"
INV_SOURCE_ARTIFACT_FILE <- "DP1.20120.001_all.rds"
INV_SOURCE_RECEIPT_FILE <- "DP1.20120.001_source_receipt.json"
INV_FETCH_EVIDENCE_FILE <- "DP1.20120.001_fetch_evidence.json"

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
    "siteID", "collectDate", "decimalLatitude", "decimalLongitude",
    "elevation", "aquaticSiteType", "benthicArea", "sampleCondition",
    "samplingImpractical", INV_VF_QC_COLUMNS$inv_fieldData,
    "publicationDate", "release"
  )),
  inv_persample = unique(c(
    INV_PRIMARY_KEYS$inv_persample, INV_VF_QC_COLUMNS$inv_persample,
    "publicationDate", "release"
  )),
  inv_taxonomyProcessed = unique(c(
    INV_PRIMARY_KEYS$inv_taxonomyProcessed,
    "acceptedTaxonID", "taxonRank", "order", "family", "class", "subclass",
    "individualCount", "estimatedTotalCount", "subsamplePercent",
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

inv_is_blank <- function(x) {
  is.na(x) | !nzchar(trimws(as.character(x)))
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
  inv_assert(!any(inv_is_blank(x$publicationDate)),
             "%s has missing publicationDate provenance", table_name)
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

inv_validate_relations <- function(field, per_sample, taxonomy) {
  sampling_flag <- trimws(as.character(field$samplingImpractical))
  practical <- is.na(sampling_flag) | !nzchar(sampling_flag) |
    toupper(sampling_flag) == "OK"

  practical_rows <- field[practical, , drop = FALSE]
  impractical_rows <- field[!practical, , drop = FALSE]
  inv_assert_nonblank_pair(practical_rows, "practical inv_fieldData")
  inv_assert_nonblank_pair(per_sample, "inv_persample")
  inv_assert_nonblank_pair(taxonomy, "inv_taxonomyProcessed")

  field_ids <- as.character(field$sampleID[!inv_is_blank(field$sampleID)])
  practical_ids <- as.character(practical_rows$sampleID)
  impractical_ids <- as.character(
    impractical_rows$sampleID[!inv_is_blank(impractical_rows$sampleID)]
  )
  per_sample_ids <- as.character(per_sample$sampleID)
  taxonomy_ids <- unique(as.character(taxonomy$sampleID))
  inv_assert(!anyDuplicated(field_ids),
             "inv_fieldData has an ambiguous repeated nonblank sampleID")
  inv_assert(!anyDuplicated(per_sample_ids),
             "inv_persample has multiple rows for one sampleID")

  missing_per_ids <- setdiff(practical_ids, per_sample_ids)
  inv_assert(!length(missing_per_ids),
             "practical inv_fieldData sample %s has no inv_persample child",
             if (length(missing_per_ids)) missing_per_ids[[1]] else "")
  orphan_per_ids <- setdiff(per_sample_ids, practical_ids)
  inv_assert(!length(orphan_per_ids),
             "inv_persample sample %s has no practical inv_fieldData parent",
             if (length(orphan_per_ids)) orphan_per_ids[[1]] else "")
  orphan_taxonomy_ids <- setdiff(taxonomy_ids, per_sample_ids)
  inv_assert(!length(orphan_taxonomy_ids),
             "inv_taxonomyProcessed sample %s has no inv_persample parent",
             if (length(orphan_taxonomy_ids)) orphan_taxonomy_ids[[1]] else "")
  impractical_children <- intersect(impractical_ids, c(per_sample_ids, taxonomy_ids))
  inv_assert(!length(impractical_children),
             "impractical inv_fieldData sample %s has a child record",
             if (length(impractical_children)) impractical_children[[1]] else "")

  practical_pairs <- practical_rows[c("sampleID", "sampleCode")]
  inv_assert(!anyDuplicated(practical_pairs),
             "practical inv_fieldData has an ambiguous repeated sampleID/sampleCode pair")

  practical_to_per <- inv_pair_join(practical_pairs, per_sample)
  missing_per <- practical_to_per[is.na(practical_to_per$.right_row), , drop = FALSE]
  inv_assert(!nrow(missing_per),
             "practical inv_fieldData sample %s/%s has no inv_persample child",
             if (nrow(missing_per)) missing_per$sampleID[[1]] else "",
             if (nrow(missing_per)) missing_per$sampleCode[[1]] else "")

  per_to_practical <- inv_pair_join(per_sample, practical_pairs)
  orphan_per <- per_to_practical[is.na(per_to_practical$.right_row), , drop = FALSE]
  inv_assert(!nrow(orphan_per),
             "inv_persample sample %s/%s has no practical inv_fieldData parent",
             if (nrow(orphan_per)) orphan_per$sampleID[[1]] else "",
             if (nrow(orphan_per)) orphan_per$sampleCode[[1]] else "")

  tax_to_per <- inv_pair_join(taxonomy, per_sample)
  orphan_tax <- tax_to_per[is.na(tax_to_per$.right_row), , drop = FALSE]
  inv_assert(!nrow(orphan_tax),
             "inv_taxonomyProcessed sample %s/%s has no inv_persample parent",
             if (nrow(orphan_tax)) orphan_tax$sampleID[[1]] else "",
             if (nrow(orphan_tax)) orphan_tax$sampleCode[[1]] else "")

  # Impractical records are valid opportunities, but must not acquire lab or
  # taxonomy children. Ignore blank identifiers because they cannot join.
  impractical_pairs <- impractical_rows[
    !inv_is_blank(impractical_rows$sampleID) &
      !inv_is_blank(impractical_rows$sampleCode),
    c("sampleID", "sampleCode"), drop = FALSE
  ]
  if (nrow(impractical_pairs)) {
    bad_per <- inv_pair_join(impractical_pairs, per_sample)
    bad_per <- bad_per[!is.na(bad_per$.right_row), , drop = FALSE]
    inv_assert(!nrow(bad_per),
               "impractical inv_fieldData sample %s/%s has an inv_persample child",
               if (nrow(bad_per)) bad_per$sampleID[[1]] else "",
               if (nrow(bad_per)) bad_per$sampleCode[[1]] else "")

    bad_tax <- inv_pair_join(impractical_pairs, taxonomy)
    bad_tax <- bad_tax[!is.na(bad_tax$.right_row), , drop = FALSE]
    inv_assert(!nrow(bad_tax),
               "impractical inv_fieldData sample %s/%s has a taxonomy child",
               if (nrow(bad_tax)) bad_tax$sampleID[[1]] else "",
               if (nrow(bad_tax)) bad_tax$sampleCode[[1]] else "")
  }

  tax_pairs <- unique(taxonomy[c("sampleID", "sampleCode")])
  per_to_tax <- inv_pair_join(per_sample, tax_pairs)
  invisible(list(
    practical_field_rows = nrow(practical_rows),
    impractical_field_rows = nrow(impractical_rows),
    processed_without_taxonomy = sum(is.na(per_to_tax$.right_row))
  ))
}

inv_validate_variables <- function(source) {
  variables <- source$variables_20120
  inv_assert_named_data_frame(variables, "variables_20120")
  inv_assert_required_columns(
    variables, "variables_20120",
    c("table", "fieldName", "description", "dataType", "units",
      "primaryKey", "categoricalCodeName")
  )
  inv_assert(!any(inv_is_blank(variables$table)) &&
               !any(inv_is_blank(variables$fieldName)),
             "variables_20120 has a missing table/fieldName identity")
  metadata_key <- variables[c("table", "fieldName")]
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
    inv_assert_required_columns(table, table_name, INV_REQUIRED_COLUMNS[[table_name]])
    inv_assert_release_rows(table, table_name)
    inv_assert_primary_key(table, table_name, INV_PRIMARY_KEYS[[table_name]])
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
  field_dna <- inv_metabarcode_mask(source$inv_fieldData$sampleID, "inv_fieldData")
  per_sample_dna <- inv_metabarcode_mask(source$inv_persample$sampleID, "inv_persample")
  taxonomy_dna <- inv_metabarcode_mask(
    source$inv_taxonomyProcessed$sampleID, "inv_taxonomyProcessed"
  )
  inv_assert(!any(per_sample_dna),
             "inv_persample contains .DNA rows from the separate metabarcoding product")
  inv_assert(!any(taxonomy_dna),
             "inv_taxonomyProcessed contains .DNA rows from the separate metabarcoding product")

  collection_field <- source$inv_fieldData[!field_dna, , drop = FALSE]
  metabarcode_field <- source$inv_fieldData[field_dna, , drop = FALSE]
  inv_assert(nrow(collection_field) > 0L,
             "inv_fieldData has no non-.DNA collection opportunities")
  relation_summary <- inv_validate_relations(
    collection_field, source$inv_persample, source$inv_taxonomyProcessed
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
    metabarcode_site_ids = metabarcode_site_ids
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
  receipt <- inv_build_source_receipt(
    source, artifact_tmp, fetched_at_utc, producer_git_sha,
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
