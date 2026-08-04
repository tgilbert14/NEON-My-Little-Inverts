#!/usr/bin/env Rscript

source("scripts/inv_source_contract.R", local = TRUE)

checks <- 0L
FIXTURE_GIT_SHA <- paste(rep("a", 40L), collapse = "")

expect_error <- function(expr, pattern) {
  checks <<- checks + 1L
  message_text <- tryCatch(
    {
      force(expr)
      NA_character_
    },
    error = function(error) conditionMessage(error)
  )
  if (is.na(message_text)) {
    stop(sprintf("Expected an error matching /%s/, but expression passed", pattern),
         call. = FALSE)
  }
  if (!grepl(pattern, message_text, perl = TRUE)) {
    stop(sprintf("Expected /%s/, got: %s", pattern, message_text), call. = FALSE)
  }
  invisible(message_text)
}

expect_true <- function(value, label) {
  checks <<- checks + 1L
  if (!isTRUE(value)) stop(sprintf("Check failed: %s", label), call. = FALSE)
  invisible(value)
}

fixture_source <- function() {
  field <- data.frame(
    uid = c(
      "20000000-0000-4000-8000-000000000001",
      "20000000-0000-4000-8000-000000000002"
    ),
    namedLocation = c("SYCA.AOS.reach", "SYCA.AOS.reach"),
    eventID = c("SYCA.2024.spring", "SYCA.2024.fall"),
    sampleID = c("SYCA.INV.S1", NA_character_),
    sampleCode = c("INV-S1", NA_character_),
    habitatType = c("riffle", "riffle"),
    samplerType = c("Surber", "Surber"),
    sampleNumber = c("1", "2"),
    siteID = c("SYCA", "SYCA"),
    collectDate = c("2024-03-01", "2024-10-01"),
    decimalLatitude = c(33.1, 33.1),
    decimalLongitude = c(-111.5, -111.5),
    elevation = c(500, 500),
    aquaticSiteType = c("wadeable stream", "wadeable stream"),
    benthicArea = c(0.09, NA_real_),
    sampleCondition = c("OK", NA_character_),
    samplingImpractical = c("OK", "location dry"),
    dataQF = c(NA_character_, "field review note"),
    publicationDate = c("2026-01-23T00:00:00Z", "2026-01-23T00:00:00Z"),
    release = c(INV_RELEASE, INV_RELEASE),
    stringsAsFactors = FALSE
  )
  other_sites <- setdiff(INV_EXPECTED_SITES, "SYCA")
  held_rows <- field[rep(2L, length(other_sites)), , drop = FALSE]
  held_rows$namedLocation <- paste0(other_sites, ".AOS.reach")
  held_rows$eventID <- paste0(other_sites, ".2024.held")
  held_rows$sampleNumber <- as.character(seq_along(other_sites) + 2L)
  held_rows$uid <- sprintf(
    "20000000-0000-4000-8000-%012d", seq_along(other_sites) + 2L
  )
  held_rows$siteID <- other_sites
  held_rows$decimalLatitude <- seq(30, 46, length.out = length(other_sites))
  held_rows$decimalLongitude <- seq(-120, -70, length.out = length(other_sites))
  field <- rbind(field, held_rows)
  dna_row <- field[1, , drop = FALSE]
  dna_row$uid <- "20000000-0000-4000-8000-000000000099"
  dna_row$eventID <- "SYCA.2024.metabarcode"
  dna_row$sampleID <- "SYCA.INV.S1.DNA"
  dna_row$sampleCode <- NA_character_
  dna_row$sampleNumber <- "DNA"
  field <- rbind(field, dna_row)

  per_sample <- data.frame(
    uid = "00000000-0000-4000-8000-000000000001",
    siteID = "SYCA",
    collectDate = "2024-03-01 00:00:00",
    sampleID = "SYCA.INV.S1",
    sampleCode = "INV-S1",
    testProtocolVersion = "fixture_macroinvertebrate_identification",
    primaryMatrix = "fine organic",
    laboratoryName = "Fixture Laboratory",
    sortDate = "2024-03-14",
    dataQF = "persample review flag",
    qcSortDate = "2024-03-15",
    qcSortingEfficacy = 98.5,
    qcIterationCount = 2L,
    qcPercentSimilarity = 97,
    qcSortedBy = "fixture technician",
    qcEnumerationDifference = 0.1,
    qcTaxonomicDifference = 0.2,
    publicationDate = "2026-01-23T00:00:00Z",
    release = INV_RELEASE,
    stringsAsFactors = FALSE
  )
  dna_per_sample <- per_sample
  dna_per_sample$uid <- "00000000-0000-4000-8000-000000000099"
  dna_per_sample$sampleID <- "SYCA.INV.S1.DNA"
  dna_per_sample$sampleCode <- NA_character_
  per_sample <- rbind(per_sample, dna_per_sample)

  taxonomy <- data.frame(
    uid = "10000000-0000-4000-8000-000000000001",
    siteID = "SYCA",
    sampleID = "SYCA.INV.S1",
    sampleCode = "INV-S1",
    targetTaxaPresent = "Y",
    scientificName = "Baetis",
    morphospeciesID = NA_character_,
    invertebrateLifeStage = "larva",
    sizeClass = "1",
    sizeCategory = "small",
    immatureSpecimen = "N",
    indeterminateSpecies = "N",
    taxonRankQualifier = NA_character_,
    sampleCondition = "OK",
    distinctTaxon = "Y",
    identificationRemarks = NA_character_,
    acceptedTaxonID = "BAETIS",
    taxonRank = "genus",
    order = "Ephemeroptera",
    family = "Baetidae",
    class = "Insecta",
    subclass = NA_character_,
    individualCount = 2,
    estimatedTotalCount = 2,
    subsamplePercent = 100,
    qcChecked = "Y",
    laboratoryName = "Fixture Laboratory",
    dataQF = "taxonomy review note",
    publicationDate = "2026-01-23T00:00:00Z",
    release = INV_RELEASE,
    stringsAsFactors = FALSE
  )
  dna_taxonomy <- taxonomy
  dna_taxonomy$uid <- "10000000-0000-4000-8000-000000000099"
  dna_taxonomy$sampleID <- "SYCA.INV.S1.DNA"
  dna_taxonomy$sampleCode <- NA_character_
  taxonomy <- rbind(taxonomy, dna_taxonomy)

  table_list <- list(
    inv_fieldData = field,
    inv_persample = per_sample,
    inv_taxonomyProcessed = taxonomy
  )
  variable_rows <- do.call(rbind, lapply(names(table_list), function(table_name) {
    fields <- names(table_list[[table_name]])
    data.frame(
      table = table_name,
      fieldName = fields,
      description = paste("Fixture definition for", fields),
      dataType = ifelse(
        vapply(table_list[[table_name]], is.numeric, logical(1)), "real", "string"
      ),
      units = "",
      downloadPkg = "basic",
      pubFormat = "asIs",
      primaryKey = ifelse(fields %in% INV_PRIMARY_KEYS[[table_name]], "Y", "N"),
      categoricalCodeName = ifelse(
        table_name == "inv_fieldData" & fields == "samplingImpractical",
        "smp.samplingImpractical", ""
      ),
      stringsAsFactors = FALSE
    )
  }))
  omission_rows <- data.frame(
    table = rep("inv_taxonomyProcessed",
                nrow(INV_BASIC_TAXONOMY_OMISSION_METADATA)),
    INV_BASIC_TAXONOMY_OMISSION_METADATA,
    check.names = FALSE, stringsAsFactors = FALSE
  )
  variable_rows <- rbind(variable_rows, omission_rows[names(variable_rows)])
  measurement_key <- paste(INV_MEASUREMENT_METADATA$table,
                           INV_MEASUREMENT_METADATA$fieldName, sep = "\u241f")
  variable_key <- paste(variable_rows$table, variable_rows$fieldName,
                        sep = "\u241f")
  measurement_rows <- match(measurement_key, variable_key)
  variable_rows[measurement_rows, c(
    "description", "dataType", "units"
  )] <- INV_MEASUREMENT_METADATA[c("description", "dataType", "units")]

  c(
    list(
      categoricalCodes_20120 = data.frame(
        categoricalCodeName = "smp.samplingImpractical",
        code = "location dry",
        description = "Sampling location was dry",
        stringsAsFactors = FALSE
      ),
      citation_20120_RELEASE.2026 = paste0(
        "@misc{", INV_DOI_URL, ",\n",
        " doi = {10.48443/HP56-S582},\n",
        " url = {", INV_RELEASE_URL, "},\n",
        " title = {Macroinvertebrate collection (", INV_DPID, ")}\n}"
      ),
      inv_fieldData = field,
      inv_persample = per_sample,
      inv_taxonomyProcessed = taxonomy,
      inv_taxonomyRaw = data.frame(sampleID = "SYCA.INV.S1"),
      issueLog_20120 = data.frame(
        id = "fixture-issue",
        parentIssueID = NA_character_,
        issueDate = "2024-03-05",
        resolvedDate = "2024-04-01",
        dateRangeStart = "2024-01-01",
        dateRangeEnd = "2024-06-30",
        locationAffected = "SYCA",
        issue = "Fixture QC issue; retained for audit",
        resolution = "Fixture resolution",
        stringsAsFactors = FALSE
      ),
      readme_20120 = data.frame(V1 = "Fixture metadata", stringsAsFactors = FALSE),
      validation_20120 = data.frame(
        fieldName = "sampleID", rule = "required", stringsAsFactors = FALSE
      ),
      variables_20120 = variable_rows
    )
  )
}

# R syntactic names replace the citation object's dash; restore the exact NEON
# list name without changing any other fixture member.
valid <- fixture_source()
names(valid)[names(valid) == "citation_20120_RELEASE.2026"] <- INV_CITATION_OBJECT

# Production pins the full RELEASE-2026 collision inventory. Synthetic tests
# use their independently computed inventory while asserting the production
# constants explicitly and exercising the same fail-closed comparator below.
RELEASE_TAXONOMY_COLLISION_EXPECTATION <-
  INV_TAXONOMY_COLLISION_EXPECTATION
RELEASE_DNA_FAMILY_EXPECTATION <- INV_DNA_FAMILY_EXPECTATION
RELEASE_SAMPLE_IDENTITY_EXPECTATION <- INV_SAMPLE_IDENTITY_EXPECTATION
RELEASE_UNRESOLVED_TAXONOMY_EXPECTATION <-
  INV_UNRESOLVED_TAXONOMY_EXPECTATION
expect_true(
  identical(RELEASE_TAXONOMY_COLLISION_EXPECTATION$groups, 1284L) &&
    identical(RELEASE_TAXONOMY_COLLISION_EXPECTATION$rows, 3683L) &&
    identical(
      RELEASE_TAXONOMY_COLLISION_EXPECTATION$inventory_sha256,
      "b3cabe1d9ec5435c9e10f05ef49ff9b299fcab719cc03fa46fc480acd3024fb5"
    ),
  "production taxonomy collision inventory is release-exact"
)
expect_true(
  identical(unname(RELEASE_DNA_FAMILY_EXPECTATION$rows), c(3L, 3L, 172L)) &&
    identical(sum(RELEASE_DNA_FAMILY_EXPECTATION$rows), 178L) &&
    identical(length(RELEASE_DNA_FAMILY_EXPECTATION$sample_ids), 3L),
  "production .DNA family quarantine is release-exact"
)
expect_true(
  identical(RELEASE_SAMPLE_IDENTITY_EXPECTATION$practical_field_rows, 6485L) &&
    identical(RELEASE_SAMPLE_IDENTITY_EXPECTATION$impractical_field_rows, 713L) &&
    identical(RELEASE_SAMPLE_IDENTITY_EXPECTATION$processed_without_taxonomy, 0L) &&
    identical(
      RELEASE_SAMPLE_IDENTITY_EXPECTATION$practical_without_per_sample, 43L
    ) &&
    identical(
      RELEASE_SAMPLE_IDENTITY_EXPECTATION$taxonomy_without_per_sample_rows, 10L
    ) &&
    identical(length(
      RELEASE_SAMPLE_IDENTITY_EXPECTATION$taxonomy_without_per_sample_ids
    ), 9L),
  "production sampleID-primary relationship inventory is release-exact"
)
expect_true(
  identical(RELEASE_UNRESOLVED_TAXONOMY_EXPECTATION$rows, 31L) &&
    identical(RELEASE_UNRESOLVED_TAXONOMY_EXPECTATION$samples, 31L),
  "production unresolved taxonomy placeholder inventory is release-exact"
)
expect_true(
  identical(INV_DISPLAYED_ZERO_PERCENT_EXPECTATION$taxonomy_rows, 53L) &&
    identical(
      INV_DISPLAYED_ZERO_PERCENT_EXPECTATION$nonexact_200x_individual_rows,
      53L
    ) &&
    identical(INV_COUNT_METADATA_EXPECTATION$pubFormat,
              rep("integer", 3L)) &&
    grepl(
      "GREATER_THAN_OR_EQUAL_TO\\(0\\)",
      INV_COUNT_VALIDATION_EXPECTATION$entryValidationRulesParser[[4L]]
    ),
  "production displayed-zero authoritative-estimate contract is release-exact"
)
# All remaining fixtures are deliberately tiny and omit the two exact
# production-only source families; absence is allowed only under this explicit
# synthetic mode.
INV_SYNTHETIC_FIXTURE_MODE <- TRUE
INV_TAXONOMY_COLLISION_EXPECTATION <- inv_taxonomy_collision_inventory(
  valid$inv_taxonomyProcessed
)
INV_DNA_FAMILY_EXPECTATION <- inv_dna_family_inventory(valid)$audit
fixture_field <- valid$inv_fieldData[
  !inv_metabarcode_mask(valid$inv_fieldData$sampleID, "fixture field"),
  , drop = FALSE
]
fixture_per <- valid$inv_persample[
  !inv_metabarcode_mask(valid$inv_persample$sampleID, "fixture per-sample"),
  , drop = FALSE
]
fixture_taxonomy <- valid$inv_taxonomyProcessed[
  !inv_metabarcode_mask(
    valid$inv_taxonomyProcessed$sampleID, "fixture taxonomy"
  ),
  , drop = FALSE
]
INV_UNRESOLVED_TAXONOMY_EXPECTATION <- inv_unresolved_taxonomy_inventory(
  fixture_taxonomy
)
INV_SAMPLE_IDENTITY_EXPECTATION <- inv_sample_identity_inventory(
  fixture_field, fixture_per, fixture_taxonomy
)

expect_true(
  identical(
    inv_source_publication_dates(
      c(
        "20251204T230818Z", "2025-12-05T00:09:25Z", "2025-12-06"
      ),
      "publication fixture"
    ),
    as.Date(c("2025-12-04", "2025-12-05", "2025-12-06"))
  ),
  paste(
    "source authority accepts only exact compact UTC, canonical ISO UTC,",
    "and intentional date-only character forms"
  )
)
expect_true(
  identical(
    inv_source_publication_dates(
      as.Date(c("2025-12-04", "2025-12-05")), "Date fixture"
    ),
    as.Date(c("2025-12-04", "2025-12-05"))
  ) && identical(
    inv_source_publication_dates(
      as.POSIXct(
        c("2025-12-04 23:59:59", "2025-12-05 00:00:01"), tz = "UTC"
      ),
      "POSIX fixture"
    ),
    as.Date(c("2025-12-04", "2025-12-05"))
  ),
  "source authority assigns Date and POSIX publication values explicit UTC dates"
)
non_utc_posixlt <- as.POSIXlt(
  as.POSIXct("2025-12-04 23:30:00", tz = "America/New_York"),
  tz = "America/New_York"
)
expect_true(
  identical(
    inv_source_publication_dates(
      non_utc_posixlt, "non-UTC POSIXlt fixture"
    ),
    as.Date("2025-12-05")
  ),
  paste(
    "source authority preserves a non-UTC POSIXlt instant before UTC",
    "calendar-day projection"
  )
)
invalid_publication_dates <- c(
  "2025-12-04T23:08:18Z trailing",
  "2025-12-04T24:00:00Z",
  "2025-12-04T23:60:00Z",
  "2025-12-04T23:08:60Z",
  "2025-02-29T23:08:18Z",
  "20250229T230818Z",
  "2025-02-29",
  "2025-12-04 23:08:18",
  "2025-12-04T23:08:18+00:00"
)
for (bad_value in invalid_publication_dates) {
  expect_error(
    inv_source_publication_dates(
      c("2025-12-04T23:08:18Z", bad_value), "publication fixture"
    ),
    "publication fixture has malformed publicationDate at row 2"
  )
}
expect_error(
  inv_source_publication_dates(
    c(20251204, 20251205), "numeric publication fixture"
  ),
  "numeric publication fixture has malformed publicationDate at row 1"
)
expect_error(
  inv_source_publication_dates(
    structure(c(Inf, 1.5), class = "Date"), "invalid Date fixture"
  ),
  "invalid Date fixture has malformed publicationDate at row 1"
)
expect_error(
  inv_source_publication_dates(
    structure(Inf, class = c("POSIXct", "POSIXt"), tzone = "UTC"),
    "invalid POSIX fixture"
  ),
  "invalid POSIX fixture has malformed publicationDate at row 1"
)
expect_error(
  inv_source_publication_dates(
    as.POSIXlt(
      structure(
        Inf, class = c("POSIXct", "POSIXt"),
        tzone = "America/New_York"
      ),
      tz = "America/New_York"
    ),
    "invalid POSIXlt fixture"
  ),
  "invalid POSIXlt fixture has malformed publicationDate at row 1"
)

# Each authoritative required table must reject one malformed value among
# otherwise valid rows before a receipt can be issued or a producer can derive
# its maximum publication stamp.
for (table_name in INV_REQUIRED_TABLES) {
  bad_publication_source <- valid
  bad_publication_source[[table_name]]$publicationDate[[2L]] <-
    "2025-12-04T23:08:18Z trailing"
  expect_error(
    inv_validate_source(bad_publication_source),
    sprintf("%s has malformed publicationDate at row 2", table_name)
  )
}
bad_receipt_source <- valid
bad_receipt_source$inv_fieldData$publicationDate[[2L]] <- "2025-12-04T24:00:00Z"
expect_error(
  inv_build_source_receipt(
    bad_receipt_source, tempfile("unpublished-source-"),
    "2026-07-15T12:00:00Z", FIXTURE_GIT_SHA
  ),
  "inv_fieldData has malformed publicationDate at row 2"
)

summary <- inv_validate_source(valid)
expect_true(identical(names(summary$tables), INV_REQUIRED_TABLES),
            "valid fixture carries all required analysis tables")
expect_true(identical(summary$relations$practical_field_rows, 1L),
            "valid fixture counts practical field rows")
expect_true(identical(summary$relations$impractical_field_rows, 34L),
            "valid fixture counts impractical field rows")
expect_true(identical(names(summary$relations), c(
  "practical_field_rows", "impractical_field_rows", "per_sample_rows",
  "taxonomy_rows", "processed_without_taxonomy", "blank_sample_code_rows",
  "practical_without_per_sample", "taxonomy_without_per_sample_ids",
  "taxonomy_without_per_sample_rows", "projection_sha256",
  "uid_inventory_sha256"
)), "source relation receipt uses the sampleID-primary audited schema")
expect_true(identical(summary$relations$processed_without_taxonomy, 0L),
            "valid fixture has no processed sample without taxonomy")
expect_true(identical(summary$segregation$collection_field_rows, 35L),
            "valid fixture counts only non-.DNA collection field rows")
expect_true(identical(summary$segregation$metabarcode_field_rows, 1L),
            "valid fixture segregates its .DNA field row")
expect_true(identical(summary$segregation$metabarcode_sample_ids,
                      "SYCA.INV.S1.DNA"),
            "valid fixture records the segregated .DNA identity")
expect_true(
  identical(
    summary$segregation$taxonomy_key_reconciliation$status,
    "uid_surrogate_for_omitted_slide_identity"
  ) &&
    identical(
      summary$segregation$taxonomy_key_reconciliation$omitted_fields,
      INV_BASIC_TAXONOMY_OMISSION_METADATA$fieldName
    ) &&
    identical(
      summary$segregation$taxonomy_key_reconciliation$rows_excluded_from_science,
      0L
    ),
  "valid fixture records exact omission provenance without dropping taxonomy"
)
expect_true(
  identical(
    summary$segregation$dna_family_quarantine$status,
    "quarantined_from_collection_estimand"
  ) &&
    identical(summary$segregation$dna_family_quarantine$raw_rows_retained, 3L) &&
    identical(
      summary$segregation$dna_family_quarantine$excluded_from_science_rows, 3L
    ),
  "valid fixture quarantines the exact .DNA family while retaining raw evidence"
)
expect_true(
  identical(
    summary$segregation$unresolved_taxonomy$status,
    "retained_count_unavailable_placeholders"
  ) &&
    identical(
      summary$segregation$unresolved_taxonomy$rows_excluded_from_science, 0L
    ),
  "valid fixture keeps unresolved taxonomy placeholders explicit and nonzero"
)
expect_true(
  identical(summary$segregation$per_sample_quarantine$status, "not_present") &&
    identical(summary$segregation$displayed_zero_percent$status, "not_present"),
  "synthetic mode explicitly records absent production-only source families"
)
expect_error(
  inv_partition_audited_per_sample(
    valid$inv_persample, valid$inv_taxonomyProcessed,
    synthetic_fixture = FALSE
  ),
  "Audited auxiliary FLNT photo-identification row/pair is missing"
)
expect_true(all(vapply(names(INV_VF_QC_COLUMNS), function(table_name) {
  all(INV_VF_QC_COLUMNS[[table_name]] %in% names(valid[[table_name]]))
}, logical(1))), "valid fixture carries every official vF QC field")
expect_true(all(INV_ISSUE_LOG_COLUMNS %in% names(valid$issueLog_20120)),
            "valid fixture carries the full official issue-log schema")

registered_calls <- getDLLRegisteredRoutines("stats")[[".Call"]]
expect_true(
  length(registered_calls) > 0L &&
    identical(typeof(registered_calls[[1L]]$address), "externalptr"),
  "portable fixture has a real non-null process-local external pointer"
)
portable_frame <- data.frame(
  integer_altrep = 1:10000,
  character_altrep = as.character(1:10000),
  timestamp = as.POSIXct(
    "2026-01-01 00:00:00", tz = "UTC"
  ) + seq_len(10000),
  stringsAsFactors = FALSE
)
class(portable_frame) <- c("data.table", "data.frame")
attr(portable_frame, "source_marker") <- "ordinary-frame-attribute"
attr(portable_frame, ".internal.selfref") <- registered_calls[[1L]]$address
portable_fixture <- list(frame = portable_frame)
uncanonical_path <- tempfile(fileext = ".rds")
saveRDS(portable_fixture, uncanonical_path, version = 3)
expect_true(
  !identical(readRDS(uncanonical_path), portable_fixture),
  "registered native self-reference reproduces the nonportable exact round trip"
)
unlink(uncanonical_path)
portable_materialized <- inv_materialize_source(portable_fixture)
portable_path <- tempfile(fileext = ".rds")
saveRDS(portable_materialized, portable_path, version = 3)
expect_true(
  identical(readRDS(portable_path), portable_materialized) &&
    identical(class(portable_materialized$frame),
              c("data.table", "data.frame")) &&
    is.null(attr(portable_materialized$frame, ".internal.selfref")) &&
    identical(attr(portable_materialized$frame, "source_marker"),
              "ordinary-frame-attribute") &&
    inherits(portable_materialized$frame$timestamp, "POSIXct") &&
    identical(attr(portable_materialized$frame$timestamp, "tzone"), "UTC"),
  paste(
    "source materialization removes only the process-local data.table",
    "self-reference and preserves exact portable bytes"
  )
)
unlink(portable_path)

non_data_table_selfref <- data.frame(value = 1L)
attr(non_data_table_selfref, ".internal.selfref") <-
  registered_calls[[1L]]$address
expect_error(
  inv_materialize_source(list(frame = non_data_table_selfref)),
  "Only data[.]table source frames may carry [.]internal[.]selfref"
)
non_pointer_selfref <- portable_frame
attr(non_pointer_selfref, ".internal.selfref") <- "not-an-external-pointer"
expect_error(
  inv_materialize_source(list(frame = non_pointer_selfref)),
  "data[.]table [.]internal[.]selfref must be an external pointer"
)

portable_evidence_root <- tempfile("inv-portable-fetch-evidence-")
dir.create(portable_evidence_root)
portable_artifact <- file.path(portable_evidence_root, INV_SOURCE_ARTIFACT_FILE)
portable_evidence <- file.path(portable_evidence_root, INV_FETCH_EVIDENCE_FILE)
inv_persist_fetch_evidence(
  portable_fixture, portable_artifact, portable_evidence, FIXTURE_GIT_SHA,
  "2026-07-22T12:34:56Z"
)
expect_true(
  identical(readRDS(portable_artifact), portable_materialized) &&
    identical(
      inv_verify_fetch_evidence(portable_artifact, portable_evidence)$artifact$sha256,
      inv_sha256_file(portable_artifact)
    ),
  "fetch evidence binds the exact canonical persisted data.table bytes"
)
unlink(portable_evidence_root, recursive = TRUE, force = TRUE)

data_table_valid <- valid
data_table_valid$variables_20120 <-
  data.table::as.data.table(data_table_valid$variables_20120)
data_table_valid <- inv_materialize_source(data_table_valid)
data_table_before <- serialize(data_table_valid, NULL, version = 3)
data_table_summary <- inv_validate_source(data_table_valid)
data_table_after <- serialize(data_table_valid, NULL, version = 3)
expect_true(
  is.list(data_table_summary) &&
    identical(class(data_table_valid$variables_20120),
              c("data.table", "data.frame")) &&
    is.null(attr(data_table_valid$variables_20120, ".internal.selfref")) &&
    identical(data_table_after, data_table_before),
  paste(
    "full source validation accepts canonical data.table metadata without",
    "mutating its class, attributes, values, or serialized bytes"
  )
)

metadata_fields <- names(INV_COUNT_METADATA_EXPECTATION)
metadata_key <- paste(
  INV_COUNT_METADATA_EXPECTATION$table,
  INV_COUNT_METADATA_EXPECTATION$fieldName,
  sep = "\u241f"
)
variable_key <- paste(
  as.character(data_table_valid$variables_20120$table),
  as.character(data_table_valid$variables_20120$fieldName),
  sep = "\u241f"
)
metadata_rows <- match(metadata_key, variable_key)
projected_metadata <- inv_frame_columns(
  data_table_valid$variables_20120[metadata_rows, , drop = FALSE],
  metadata_fields
)
expected_metadata <- valid$variables_20120[
  metadata_rows, metadata_fields, drop = FALSE
]
projected_metadata <- data.frame(
  lapply(projected_metadata, as.character),
  check.names = FALSE, stringsAsFactors = FALSE
)
expected_metadata <- data.frame(
  lapply(expected_metadata, as.character),
  check.names = FALSE, stringsAsFactors = FALSE
)
expect_true(
  identical(projected_metadata, expected_metadata),
  "data.table metadata projection preserves the displayed-zero receipt fields"
)

duplicate_data_table <- data.table::rbindlist(list(
  data_table_valid$variables_20120,
  data_table_valid$variables_20120[1L, , drop = FALSE]
), use.names = TRUE)
duplicate_data_table <- inv_materialize_data_frame(duplicate_data_table)
duplicate_source <- valid
duplicate_source$variables_20120 <- duplicate_data_table
expect_error(
  inv_validate_source(duplicate_source),
  "variables_20120 has duplicate table/fieldName schema rows"
)

placeholder_coexisting <- fixture_taxonomy[1, , drop = FALSE]
placeholder_coexisting$uid <- "10000000-0000-4000-8000-000000000011"
placeholder_coexisting$targetTaxaPresent <- "N"
placeholder_coexisting$acceptedTaxonID <- NA_character_
placeholder_coexisting$scientificName <- NA_character_
placeholder_coexisting$taxonRank <- NA_character_
placeholder_coexisting$individualCount <- NA_real_
placeholder_coexisting$estimatedTotalCount <- NA_real_
placeholder_coexisting$subsamplePercent <- NA_real_
placeholder_coexisting$identificationRemarks <- "no organisms found"
placeholder_coexisting$sampleCondition <- NA_character_
placeholder_only <- placeholder_coexisting
placeholder_only$uid <- "10000000-0000-4000-8000-000000000012"
placeholder_only$sampleID <- "PLACEHOLDER.ONLY"
placeholder_only$sampleCode <- NA_character_
placeholder_fixture <- rbind(
  fixture_taxonomy[1, , drop = FALSE], placeholder_coexisting,
  placeholder_only
)
placeholder_audit <- inv_unresolved_taxonomy_inventory(placeholder_fixture)
expect_true(
  identical(placeholder_audit$rows, 2L) &&
    identical(placeholder_audit$samples_with_other_count_valid_taxa, 1L) &&
    identical(placeholder_audit$placeholder_only_samples, 1L),
  "unresolved placeholders cover both coexisting and placeholder-only samples"
)
bad_placeholder <- placeholder_fixture
bad_placeholder$estimatedTotalCount[[3L]] <- 0
expect_error(
  inv_unresolved_taxonomy_inventory(bad_placeholder),
  "placeholder has a reported individual or estimated count"
)

bad <- valid
bad$inv_taxonomyProcessed$slideID <- NA_character_
expect_error(
  inv_reconcile_taxonomy_primary_keys(
    bad$inv_taxonomyProcessed, bad$variables_20120, expectation = NULL
  ),
  "taxonomy source omission differs from the exact eight"
)

bad <- valid
row <- bad$variables_20120$table == "inv_taxonomyProcessed" &
  bad$variables_20120$fieldName == "slideID"
bad$variables_20120$downloadPkg[row] <- "basic"
expect_error(
  inv_validate_source(bad),
  "taxonomy omission evidence differs from RELEASE-2026"
)

bad <- valid
bad$inv_taxonomyProcessed$uid[[1L]] <- ""
expect_error(inv_validate_source(bad), "UID surrogate must be globally nonblank")

# Exercise an authorized collision without inventing slide values: both source
# records remain, UID differentiates them, and any inventory drift fails.
collision_source <- valid
collision_row <- collision_source$inv_taxonomyProcessed[1, , drop = FALSE]
collision_row$uid <- "10000000-0000-4000-8000-000000000002"
collision_row$individualCount <- 3L
collision_row$estimatedTotalCount <- 3
collision_source$inv_taxonomyProcessed <- rbind(
  collision_source$inv_taxonomyProcessed, collision_row
)
fixture_collision_expectation <- inv_taxonomy_collision_inventory(
  collision_source$inv_taxonomyProcessed
)
INV_TAXONOMY_COLLISION_EXPECTATION <- fixture_collision_expectation
collision_analysis <- inv_prepare_analysis_source(collision_source)$source
INV_SAMPLE_IDENTITY_EXPECTATION <- inv_sample_identity_inventory(
  collision_analysis$inv_fieldData,
  collision_analysis$inv_persample,
  collision_analysis$inv_taxonomyProcessed
)
collision_summary <- inv_validate_source(collision_source)
expect_true(
  identical(
    collision_summary$segregation$taxonomy_key_reconciliation$rows, 2L
  ) &&
    identical(nrow(
      inv_prepare_analysis_source(collision_source)$source$inv_taxonomyProcessed
    ), 2L),
  "audited UID-surrogate collision preserves and sums every taxonomy row"
)

bad <- collision_source
bad$inv_taxonomyProcessed$uid[[nrow(bad$inv_taxonomyProcessed)]] <-
  bad$inv_taxonomyProcessed$uid[[1L]]
expect_error(inv_validate_source(bad), "UID surrogate must be globally nonblank")

bad <- collision_source
bad$inv_taxonomyProcessed$laboratoryName[[nrow(
  bad$inv_taxonomyProcessed
)]] <- "Unexpected Laboratory"
expect_error(inv_validate_source(bad),
             "identity spans missing or multiple laboratories")

drift_expectation <- fixture_collision_expectation
drift_expectation$rows <- drift_expectation$rows + 1L
expect_error(
  inv_assert_taxonomy_collision_inventory(
    fixture_collision_expectation, drift_expectation
  ),
  "collision inventory differs from the audited RELEASE-2026 source"
)
INV_TAXONOMY_COLLISION_EXPECTATION <- inv_taxonomy_collision_inventory(
  valid$inv_taxonomyProcessed
)
INV_SAMPLE_IDENTITY_EXPECTATION <- inv_sample_identity_inventory(
  fixture_field, fixture_per, fixture_taxonomy
)

bad <- valid
bad$issueLog_20120 <- NULL
expect_error(inv_validate_source(bad), "missing required object.*issueLog_20120")

bad <- valid
bad$inv_persample$qcTaxonomicDifference <- NULL
expect_error(inv_validate_source(bad),
             "inv_persample is missing required column.*qcTaxonomicDifference")

bad <- valid
bad$issueLog_20120$resolution <- NULL
expect_error(inv_validate_source(bad),
             "issueLog_20120 is missing required column.*resolution")

bad <- valid
names(bad)[2] <- names(bad)[1]
expect_error(inv_validate_source(bad), "duplicate object names")

bad <- valid
wlo <- as.character(bad$inv_fieldData$siteID) == "WLOU"
bad$inv_fieldData$siteID[wlo] <- "SYCA"
expect_error(inv_validate_source(bad), "non-[.]DNA inv_fieldData site roster differs.*missing=\\[WLOU\\]")

bad <- valid
dna_row_index <- grepl("[.]DNA$", bad$inv_fieldData$sampleID)
bad$inv_fieldData$sampleID[dna_row_index] <- "SYCA.INV.S1.dna"
expect_error(inv_validate_source(bad), "noncanonical [.]DNA sampleID suffix")

bad <- valid
duplicate_dna <- bad$inv_fieldData[
  grepl("[.]DNA$", bad$inv_fieldData$sampleID), , drop = FALSE
]
duplicate_dna$eventID <- "SYCA.2024.metabarcode.duplicate"
duplicate_dna$sampleNumber <- "DNA-DUPLICATE"
bad$inv_fieldData <- rbind(bad$inv_fieldData, duplicate_dna)
expect_error(inv_validate_source(bad), "[.]DNA family UID inventory")

bad <- valid
dna_field <- bad$inv_fieldData[grepl("[.]DNA$", bad$inv_fieldData$sampleID), ]
dna_per_sample <- bad$inv_persample[1, ]
dna_per_sample$sampleID <- dna_field$sampleID
dna_per_sample$sampleCode <- dna_field$sampleCode
bad$inv_persample <- rbind(bad$inv_persample, dna_per_sample)
expect_error(inv_validate_source(bad),
             "[.]DNA family inventory differs from the audited RELEASE-2026")

bad <- valid
dna_field <- bad$inv_fieldData[grepl("[.]DNA$", bad$inv_fieldData$sampleID), ]
dna_taxonomy <- bad$inv_taxonomyProcessed[1, ]
dna_taxonomy$uid <- "10000000-0000-4000-8000-000000000098"
dna_taxonomy$sampleID <- dna_field$sampleID
dna_taxonomy$sampleCode <- dna_field$sampleCode
bad$inv_taxonomyProcessed <- rbind(bad$inv_taxonomyProcessed, dna_taxonomy)
expect_error(inv_validate_source(bad),
             "[.]DNA family inventory differs from the audited RELEASE-2026")

bad <- valid
bad$inv_fieldData$collectDate <- NULL
expect_error(inv_validate_source(bad), "missing required column.*collectDate")

bad <- valid
names(bad$inv_persample)[2] <- names(bad$inv_persample)[1]
expect_error(inv_validate_source(bad), "duplicate column names")

bad <- valid
bad$variables_20120 <- bad$variables_20120[
  !(bad$variables_20120$table == "inv_fieldData" &
      bad$variables_20120$fieldName == "collectDate"), , drop = FALSE
]
expect_error(inv_validate_source(bad), "does not document inv_fieldData column.*collectDate")

bad <- valid
bad$variables_20120 <- rbind(bad$variables_20120, bad$variables_20120[1, ])
expect_error(inv_validate_source(bad), "duplicate table/fieldName schema rows")

bad <- valid
row <- bad$variables_20120$table == "inv_persample" &
  bad$variables_20120$fieldName == "sampleCode"
bad$variables_20120$primaryKey[row] <- "N"
expect_error(inv_validate_source(bad), "primary keys for inv_persample differ")

bad <- valid
row <- bad$variables_20120$table == "inv_fieldData" &
  bad$variables_20120$fieldName == "benthicArea"
bad$variables_20120$units[row] <- "squareCentimeter"
expect_error(inv_validate_source(bad), "measurement descriptions, types, or units")

bad <- valid
row <- bad$variables_20120$table == "inv_taxonomyProcessed" &
  bad$variables_20120$fieldName == "estimatedTotalCount"
bad$variables_20120$description[row] <- "Unreviewed count definition"
expect_error(inv_validate_source(bad), "measurement descriptions, types, or units")

bad <- valid
novel <- bad$variables_20120[
  bad$variables_20120$table == "inv_persample" &
    bad$variables_20120$fieldName == "dataQF", , drop = FALSE
]
novel$fieldName <- "qcNovel"
bad$variables_20120 <- rbind(bad$variables_20120, novel)
expect_error(inv_validate_source(bad), "QC fields for inv_persample differ")

bad <- valid
novel <- bad$variables_20120[
  bad$variables_20120$table == "inv_persample" &
    bad$variables_20120$fieldName == "dataQF", , drop = FALSE
]
novel$fieldName <- "novelDataQF"
bad$variables_20120 <- rbind(bad$variables_20120, novel)
expect_error(inv_validate_source(bad), "QC fields for inv_persample differ")

bad <- valid
bad$inv_fieldData <- rbind(bad$inv_fieldData, bad$inv_fieldData[1, ])
expect_error(inv_validate_source(bad), "duplicate RELEASE-2026 primary key")

bad <- valid
bad$inv_persample <- rbind(bad$inv_persample, bad$inv_persample[1, ])
expect_error(inv_validate_source(bad), "duplicate RELEASE-2026 primary key")

bad <- valid
second_code <- bad$inv_persample[1, ]
second_code$sampleCode <- "INV-S1-SECOND-CODE"
bad$inv_persample <- rbind(bad$inv_persample, second_code)
expect_error(inv_validate_source(bad), "multiple rows for one sampleID")

bad <- valid
bad$inv_taxonomyProcessed <- rbind(
  bad$inv_taxonomyProcessed, bad$inv_taxonomyProcessed[1, ]
)
expect_error(inv_validate_source(bad), "UID surrogate must be globally nonblank")

bad <- valid
bad$inv_persample$sampleCode[[1L]] <- ""
expect_error(inv_validate_source(bad),
             "sampleCode disagrees with practical field provenance")

bad <- valid
bad$inv_persample <- bad$inv_persample[FALSE, , drop = FALSE]
expect_error(inv_validate_source(bad), "inv_persample has no rows")

bad <- valid
bad$inv_persample$sampleID[[1L]] <- "ORPHAN"
expect_error(inv_validate_source(bad),
             "inv_persample sample ORPHAN has no practical inv_fieldData parent")

bad <- valid
bad$inv_taxonomyProcessed$sampleID[[1L]] <- "ORPHAN"
expect_error(inv_validate_source(bad), "has no practical field parent")

bad <- valid
bad$inv_fieldData$samplingImpractical[1] <- "location dry"
expect_error(inv_validate_source(bad), "has no practical inv_fieldData parent")

bad <- valid
bad$inv_fieldData$samplingImpractical[2] <- "OK"
expect_error(inv_validate_source(bad), "practical inv_fieldData has a missing sampleID")

bad <- valid
bad$inv_taxonomyProcessed$release <- "PROVISIONAL"
expect_error(inv_validate_source(bad), "release values other than RELEASE-2026")

bad <- valid
bad[[INV_CITATION_OBJECT]] <- gsub(INV_DOI, "10.0000/not-the-doi",
                                    bad[[INV_CITATION_OBJECT]], fixed = TRUE)
bad[[INV_CITATION_OBJECT]] <- gsub("10.48443/HP56-S582", "10.0000/NOT-THE-DOI",
                                    bad[[INV_CITATION_OBJECT]], fixed = TRUE)
expect_error(inv_validate_source(bad), "does not contain DOI")

# One practical field/per-sample pair with no taxonomy child is retained as a
# candidate; later science-contract work must classify it before publication.
zero_candidate <- valid
zero_candidate$inv_taxonomyProcessed$sampleID[[1L]] <- "SECOND"
zero_candidate$inv_taxonomyProcessed$sampleCode[[1L]] <- "SECOND"
second_field <- zero_candidate$inv_fieldData[1, ]
second_field$uid <- "20000000-0000-4000-8000-000000000098"
second_field$sampleID <- "SECOND"
second_field$sampleCode <- "SECOND"
second_field$sampleNumber <- "3"
second_field$eventID <- "SYCA.2024.second"
zero_candidate$inv_fieldData <- rbind(zero_candidate$inv_fieldData, second_field)
second_per <- zero_candidate$inv_persample[1, ]
second_per$uid <- "00000000-0000-4000-8000-000000000098"
second_per$sampleID <- "SECOND"
second_per$sampleCode <- "SECOND"
zero_candidate$inv_persample <- rbind(zero_candidate$inv_persample, second_per)
zero_analysis <- inv_prepare_analysis_source(zero_candidate)$source
INV_SAMPLE_IDENTITY_EXPECTATION <- inv_sample_identity_inventory(
  zero_analysis$inv_fieldData,
  zero_analysis$inv_persample,
  zero_analysis$inv_taxonomyProcessed
)
zero_summary <- inv_validate_source(zero_candidate)
expect_true(identical(zero_summary$relations$processed_without_taxonomy, 1L),
            "per-sample row without taxonomy is retained as an unknown outcome")
INV_SAMPLE_IDENTITY_EXPECTATION <- inv_sample_identity_inventory(
  fixture_field, fixture_per, fixture_taxonomy
)

evidence_root_a <- tempfile("inv-fetch-evidence-a-")
evidence_root_b <- tempfile("inv-fetch-evidence-b-")
dir.create(evidence_root_a)
dir.create(evidence_root_b)
fixed_time <- "2026-07-22T12:34:56Z"
evidence_artifact_a <- file.path(evidence_root_a, INV_SOURCE_ARTIFACT_FILE)
evidence_receipt_a <- file.path(evidence_root_a, INV_FETCH_EVIDENCE_FILE)
evidence_source_receipt_a <- file.path(
  evidence_root_a, INV_SOURCE_RECEIPT_FILE
)
evidence_artifact_b <- file.path(evidence_root_b, INV_SOURCE_ARTIFACT_FILE)
evidence_receipt_b <- file.path(evidence_root_b, INV_FETCH_EVIDENCE_FILE)
inv_persist_fetch_evidence(
  valid, evidence_artifact_a, evidence_receipt_a, FIXTURE_GIT_SHA, fixed_time
)
inv_persist_fetch_evidence(
  valid, evidence_artifact_b, evidence_receipt_b, FIXTURE_GIT_SHA, fixed_time
)
evidence_verified <- inv_verify_fetch_evidence(
  evidence_artifact_a, evidence_receipt_a
)
expect_true(
  identical(evidence_verified$evidence_kind,
            "unvalidated_raw_release_fetch") &&
    identical(evidence_verified$producer$git_sha, FIXTURE_GIT_SHA) &&
    identical(evidence_verified$contract_validation$status,
              "not_yet_validated") &&
    identical(evidence_verified$contract_validation$publication_authorized,
              FALSE),
  "minimal fetch evidence is explicitly non-authoritative"
)
expect_true(
  identical(inv_sha256_file(evidence_artifact_a),
            inv_sha256_file(evidence_artifact_b)) &&
    identical(inv_sha256_file(evidence_receipt_a),
              inv_sha256_file(evidence_receipt_b)),
  "fixed source and fetch time produce deterministic evidence bytes"
)
expect_error(
  inv_build_fetch_evidence(
    evidence_artifact_a, fixed_time, toupper(FIXTURE_GIT_SHA)
  ),
  "producer git SHA must be exactly 40 lowercase hexadecimal"
)
evidence_json <- jsonlite::fromJSON(
  evidence_receipt_a, simplifyVector = FALSE
)
evidence_json$producer$git_sha <- toupper(FIXTURE_GIT_SHA)
jsonlite::write_json(
  evidence_json, evidence_receipt_a, auto_unbox = TRUE, pretty = TRUE,
  null = "null", na = "null", digits = NA
)
expect_error(
  inv_verify_fetch_evidence(evidence_artifact_a, evidence_receipt_a),
  "producer git SHA must be exactly 40 lowercase hexadecimal"
)
evidence_json$producer$git_sha <- FIXTURE_GIT_SHA
jsonlite::write_json(
  evidence_json, evidence_receipt_a, auto_unbox = TRUE, pretty = TRUE,
  null = "null", na = "null", digits = NA
)
inv_verify_fetch_evidence(evidence_artifact_a, evidence_receipt_a)
expect_error(
  inv_verify_source_receipt(evidence_artifact_a, evidence_receipt_a),
  "Source receipt schema version"
)
inv_persist_authoritative_source_receipt(
  valid, evidence_artifact_a, evidence_source_receipt_a, FIXTURE_GIT_SHA,
  fixed_time
)
expect_true(
  identical(inv_verify_source_receipt(
    evidence_artifact_a, evidence_source_receipt_a
  )$artifact$sha256, evidence_verified$artifact$sha256),
  "authoritative receipt is issued only after validating persisted raw bytes"
)
handoff_verified <- inv_verify_fetch_source_handoff(
  evidence_artifact_a, evidence_receipt_a, evidence_source_receipt_a
)
expect_true(
  identical(handoff_verified$receipt$producer$git_sha, FIXTURE_GIT_SHA),
  "raw handoff semantically reconciles evidence and source authority"
)
handoff_receipt_json <- jsonlite::fromJSON(
  evidence_source_receipt_a, simplifyVector = FALSE
)
handoff_receipt_json$producer$git_sha <- paste(rep("b", 40L), collapse = "")
jsonlite::write_json(
  handoff_receipt_json, evidence_source_receipt_a, auto_unbox = TRUE,
  pretty = TRUE, null = "null", na = "null", digits = NA
)
inv_verify_source_receipt(evidence_artifact_a, evidence_source_receipt_a)
expect_error(
  inv_verify_fetch_source_handoff(
    evidence_artifact_a, evidence_receipt_a, evidence_source_receipt_a
  ),
  "producer git SHAs differ"
)
handoff_receipt_json$producer$git_sha <- FIXTURE_GIT_SHA
handoff_receipt_json$fetched_at_utc <- "2026-07-22T12:34:57Z"
jsonlite::write_json(
  handoff_receipt_json, evidence_source_receipt_a, auto_unbox = TRUE,
  pretty = TRUE, null = "null", na = "null", digits = NA
)
inv_verify_source_receipt(evidence_artifact_a, evidence_source_receipt_a)
expect_error(
  inv_verify_fetch_source_handoff(
    evidence_artifact_a, evidence_receipt_a, evidence_source_receipt_a
  ),
  "fetch times differ"
)
handoff_receipt_json$fetched_at_utc <- fixed_time
jsonlite::write_json(
  handoff_receipt_json, evidence_source_receipt_a, auto_unbox = TRUE,
  pretty = TRUE, null = "null", na = "null", digits = NA
)
inv_verify_fetch_source_handoff(
  evidence_artifact_a, evidence_receipt_a, evidence_source_receipt_a
)

# Exercise the actual fetch orchestration without invoking neonUtilities. Both
# unit and QC drift must leave reviewable raw evidence but no source receipt.
fetch_env <- new.env(parent = globalenv())
invisible(capture.output(sys.source("scripts/fetch_inv_all.R", envir = fetch_env)))
fixture_token <- "fixture-token-must-never-enter-errors"
mock_response <- function(status) {
  structure(list(status_code = as.integer(status)), class = "response")
}
expect_true(
  isTRUE(fetch_env$inv_neon_auth_preflight(
    fixture_token, request = function(url, token) mock_response(200L)
  )),
  "NEON authentication preflight accepts HTTP 200"
)
transport_message <- expect_error(
  fetch_env$inv_neon_auth_preflight(
    fixture_token,
    request = function(url, token) {
      stop(sprintf("transport echoed %s", token), call. = FALSE)
    },
    sleep = function(seconds) NULL
  ),
  "authentication preflight failed after 4 attempts.*<redacted>"
)
expect_true(
  !grepl(fixture_token, transport_message, fixed = TRUE),
  "NEON authentication preflight redacts the token from transport errors"
)
expect_error(
  fetch_env$inv_neon_auth_preflight(
    fixture_token, request = function(url, token) mock_response(403L)
  ),
  "authentication preflight returned HTTP 403"
)
retry_status <- c(500L, 429L, 200L)
retry_calls <- 0L
retry_sleeps <- numeric()
expect_true(
  isTRUE(fetch_env$inv_neon_auth_preflight(
    fixture_token,
    request = function(url, token) {
      retry_calls <<- retry_calls + 1L
      mock_response(retry_status[[retry_calls]])
    },
    sleep = function(seconds) retry_sleeps <<- c(retry_sleeps, seconds)
  )),
  "NEON authentication preflight recovers from bounded 5xx/429 responses"
)
expect_true(
  identical(retry_calls, 3L) && identical(retry_sleeps, c(2, 4)),
  "NEON authentication preflight uses the exact bounded backoff schedule"
)
expect_true(
  identical(names(formals(fetch_env$inv_neonutilities_get_api)),
            c("apiURL", "token")) &&
    identical(fetch_env$INV_NEON_HTTP_TIMEOUT_SECONDS, 30) &&
    !grepl(fixture_token, fetch_env$inv_neon_transport_user_agent(), fixed = TRUE) &&
    !grepl("--file|/home/|/Users/", fetch_env$inv_neon_transport_user_agent()),
  "transport shim preserves getAPI formals and uses a stable path-free user agent"
)
contract_get_api <- function(apiURL, token = NA_character_) NULL
expect_true(
  isTRUE(fetch_env$inv_assert_neonutilities_base_url(
    "https://data.neonscience.org/api/v0/"
  )),
  "transport initialization accepts only the exact reviewed NEON API base URL"
)
expect_error(
  fetch_env$inv_assert_neonutilities_base_url("data"),
  "exact reviewed NEON API base URL"
)
expect_true(
  identical(
    paste0(fetch_env$INV_NEON_API_BASE_URL, "data/query?fixture=true"),
    "https://data.neonscience.org/api/v0/data/query?fixture=true"
  ),
  "reviewed base URL composes an absolute HTTPS query endpoint"
)
unset_globals <- new.env(parent = emptyenv())
restore_base_url <- fetch_env$inv_initialize_neonutilities_base_url(
  unset_globals, fetch_env$INV_NEON_UTILITIES_VERSION
)
expect_true(
  identical(unset_globals$baseurl, fetch_env$INV_NEON_API_BASE_URL),
  "base-URL initializer repairs an absent 4.0.1 namespace field"
)
restore_base_url()
restore_base_url()
expect_true(
  !exists("baseurl", envir = unset_globals, inherits = FALSE),
  "base-URL initializer exactly and idempotently removes an originally absent field"
)
blank_globals <- new.env(parent = emptyenv())
blank_globals$baseurl <- ""
restore_base_url <- fetch_env$inv_initialize_neonutilities_base_url(
  blank_globals, fetch_env$INV_NEON_UTILITIES_VERSION
)
restore_base_url()
expect_true(
  identical(blank_globals$baseurl, ""),
  "base-URL initializer exactly restores an originally blank field"
)
hostile_globals <- new.env(parent = emptyenv())
hostile_globals$baseurl <- "https://fixture.invalid/api/"
expect_error(
  fetch_env$inv_initialize_neonutilities_base_url(
    hostile_globals, fetch_env$INV_NEON_UTILITIES_VERSION
  ),
  "exact reviewed NEON API base URL"
)
expect_true(
  identical(hostile_globals$baseurl, "https://fixture.invalid/api/"),
  "base-URL initializer rejects an override without mutating it"
)
expect_error(
  fetch_env$inv_initialize_neonutilities_base_url(
    new.env(parent = emptyenv()), "4.0.2"
  ),
  "requires neonUtilities 4[.]0[.]1 exactly"
)
expect_true(
  isTRUE(fetch_env$inv_assert_neonutilities_getapi_contract(
    fetch_env$INV_NEON_UTILITIES_VERSION, contract_get_api
  )),
  "transport shim accepts only the pinned getAPI contract"
)
expect_error(
  fetch_env$inv_assert_neonutilities_getapi_contract(
    "4.0.2", contract_get_api
  ),
  "requires neonUtilities 4[.]0[.]1 exactly"
)
expect_error(
  fetch_env$inv_assert_neonutilities_getapi_contract(
    fetch_env$INV_NEON_UTILITIES_VERSION, function(url, token = NULL) NULL
  ),
  "getAPI contract drifted"
)
restore_calls <- 0L
restored_value <- NULL
original_binding <- contract_get_api
restore_binding <- fetch_env$inv_make_neonutilities_getapi_restore(
  original_binding,
  function(value) {
    restore_calls <<- restore_calls + 1L
    restored_value <<- value
  }
)
restore_binding()
restore_binding()
expect_true(
  identical(restore_calls, 1L) && identical(restored_value, original_binding),
  "transport shim restoration is exact and idempotent"
)
compat_calls <- 0L
compat_sleeps <- numeric()
ordinary_response <- mock_response(500L)
compat_result <- fetch_env$inv_neon_get_api_request(
  "https://fixture.invalid/api", fixture_token,
  request = function(url, token) {
    compat_calls <<- compat_calls + 1L
    ordinary_response
  },
  sleep = function(seconds) compat_sleeps <<- c(compat_sleeps, seconds),
  has_internet = function() TRUE
)
expect_true(
  identical(compat_result, ordinary_response) && identical(compat_calls, 1L) &&
    !length(compat_sleeps),
  "transport shim preserves ordinary HTTP response semantics"
)
compat_calls <- 0L
compat_sleeps <- numeric()
compat_message <- capture.output(
  compat_result <- fetch_env$inv_neon_get_api_request(
    "https://fixture.invalid/api", fixture_token,
    request = function(url, token) {
      compat_calls <<- compat_calls + 1L
      stop(sprintf("transport echoed %s", token), call. = FALSE)
    },
    sleep = function(seconds) compat_sleeps <<- c(compat_sleeps, seconds),
    has_internet = function() TRUE
  ),
  type = "message"
)
expect_true(
  is.null(compat_result) && identical(compat_calls, 4L) &&
    identical(compat_sleeps, c(2, 4, 8)) &&
    any(grepl("transport failed after 4 attempts.*<redacted>", compat_message)) &&
    !any(grepl(fixture_token, compat_message, fixed = TRUE)),
  "transport shim retries and redacts token-bearing transport errors"
)
compat_calls <- 0L
no_internet_message <- capture.output(
  compat_result <- fetch_env$inv_neon_get_api_request(
    "https://fixture.invalid/api", NA_character_,
    request = function(url, token) {
      compat_calls <<- compat_calls + 1L
      mock_response(200L)
    },
    has_internet = function() FALSE
  ),
  type = "message"
)
expect_true(
  is.null(compat_result) && identical(compat_calls, 0L) &&
    any(grepl("No internet connection detected", no_internet_message)),
  "transport shim preserves the no-internet NULL contract without a request"
)
rate_calls <- 0L
rate_sleeps <- numeric()
rate_response <- function(status, remaining, reset) {
  structure(list(
    status_code = as.integer(status),
    headers = list(
      `x-ratelimit-limit` = "200",
      `x-ratelimit-remaining` = as.character(remaining),
      `x-ratelimit-reset` = as.character(reset)
    )
  ), class = "response")
}
compat_result <- fetch_env$inv_neon_get_api_request(
  "https://fixture.invalid/api", "",
  request = function(url, token) {
    rate_calls <<- rate_calls + 1L
    expect_true(identical(token, ""), "empty token omits authentication material")
    if (rate_calls == 1L) rate_response(200L, 1L, 90L) else mock_response(200L)
  },
  sleep = function(seconds) rate_sleeps <<- c(rate_sleeps, seconds),
  has_internet = function() TRUE
)
expect_true(
  identical(compat_result$status_code, 200L) && identical(rate_calls, 2L) &&
    identical(rate_sleeps, 60),
  "transport shim caps rate-limit sleep and returns the subsequent response"
)
rate_calls <- 0L
rate_sleeps <- numeric()
compat_result <- fetch_env$inv_neon_get_api_request(
  "https://fixture.invalid/api", fixture_token,
  request = function(url, token) {
    rate_calls <<- rate_calls + 1L
    if (rate_calls == 1L) {
      rate_response(200L, 0L, "not-a-number")
    } else {
      mock_response(200L)
    }
  },
  sleep = function(seconds) rate_sleeps <<- c(rate_sleeps, seconds),
  has_internet = function() TRUE
)
expect_true(
  identical(compat_result$status_code, 200L) && identical(rate_calls, 2L) &&
    identical(rate_sleeps, 2),
  "transport shim bounds malformed rate-limit reset headers with normal backoff"
)
for (drift_kind in c("measurement-unit", "qc-schema")) {
  drift <- valid
  if (drift_kind == "measurement-unit") {
    row <- drift$variables_20120$table == "inv_fieldData" &
      drift$variables_20120$fieldName == "benthicArea"
    drift$variables_20120$units[row] <- "squareCentimeter"
    pattern <- "measurement descriptions, types, or units"
  } else {
    novel <- drift$variables_20120[
      drift$variables_20120$table == "inv_persample" &
        drift$variables_20120$fieldName == "dataQF", , drop = FALSE
    ]
    novel$fieldName <- "novelDataQF"
    drift$variables_20120 <- rbind(drift$variables_20120, novel)
    pattern <- "QC fields for inv_persample differ"
  }
  drift_root <- file.path(evidence_root_b, drift_kind)
  dir.create(drift_root)
  drift_artifact <- file.path(drift_root, INV_SOURCE_ARTIFACT_FILE)
  drift_evidence <- file.path(drift_root, INV_FETCH_EVIDENCE_FILE)
  drift_receipt <- file.path(drift_root, INV_SOURCE_RECEIPT_FILE)
  expect_error(
    fetch_env$inv_persist_fetched_source(
      drift, drift_artifact, drift_evidence, drift_receipt, fixed_time,
      FIXTURE_GIT_SHA
    ), pattern
  )
  expect_true(
    file.exists(drift_artifact) && file.exists(drift_evidence) &&
      !file.exists(drift_receipt) &&
      identical(
        fetch_env$inv_verify_fetch_evidence(
          drift_artifact, drift_evidence
        )$contract_validation$publication_authorized,
        FALSE
      ),
    sprintf("%s drift preserves evidence without authorization", drift_kind)
  )
}

unlink(c(evidence_root_a, evidence_root_b), recursive = TRUE, force = TRUE)

receipt_root <- tempfile("inv-source-receipt-")
dir.create(receipt_root)
artifact <- file.path(receipt_root, "DP1.20120.001_all.rds")
receipt <- file.path(receipt_root, "DP1.20120.001_source_receipt.json")
inv_persist_source(
  valid, artifact, receipt, FIXTURE_GIT_SHA, fetched_at_utc = fixed_time
)
verified <- inv_verify_source_receipt(artifact, receipt)
expect_true(identical(verified$release$tag, INV_RELEASE),
            "receipt verifies the pinned release")
expect_true(identical(verified$producer$neonUtilities_version,
                      INV_NEON_UTILITIES_VERSION),
            "receipt verifies the pinned neonUtilities version")
expect_true(identical(verified$producer$git_sha, FIXTURE_GIT_SHA),
            "receipt binds the exact fetching revision")
expect_true(grepl("^[0-9a-f]{64}$", verified$artifact$sha256),
            "receipt carries a SHA-256 artifact hash")
expect_true(identical(verified$required_tables$inv_fieldData$row_count, 36L),
            "receipt carries table row counts")
expect_true(identical(verified$segregation$metabarcode_field_rows, 1L),
            "receipt carries the segregated .DNA row count")
expect_true(identical(verified$measurement_metadata,
                      INV_MEASUREMENT_METADATA),
            "receipt exposes release-locked measurement metadata")

receipt_json <- jsonlite::fromJSON(receipt, simplifyVector = FALSE)
receipt_json$producer$git_sha <- substr(FIXTURE_GIT_SHA, 1L, 39L)
jsonlite::write_json(
  receipt_json, receipt, auto_unbox = TRUE, pretty = TRUE, null = "null",
  na = "null", digits = NA
)
expect_error(
  inv_verify_source_receipt(artifact, receipt),
  "producer git SHA must be exactly 40 lowercase hexadecimal"
)
receipt_json$producer$git_sha <- FIXTURE_GIT_SHA
jsonlite::write_json(
  receipt_json, receipt, auto_unbox = TRUE, pretty = TRUE, null = "null",
  na = "null", digits = NA
)
inv_verify_source_receipt(artifact, receipt)

expect_error(
  inv_persist_source(
    valid, artifact, receipt, FIXTURE_GIT_SHA, fetched_at_utc = fixed_time
  ),
  "Refusing to overwrite source artifact"
)

tampered <- readRDS(artifact)
tampered$inv_fieldData$elevation[1] <- 999
saveRDS(tampered, artifact, version = 3)
expect_error(inv_verify_source_receipt(artifact, receipt),
             "receipt does not match")

workflow_lines <- readLines(".github/workflows/refresh-data.yml", warn = FALSE)
evidence_start <- grep(
  "- name: Stage exact raw fetch evidence and conditional authority",
  workflow_lines, fixed = TRUE
)
bundle_start <- grep(
  "- name: Bundle the exact 34-site product",
  workflow_lines, fixed = TRUE
)
expect_true(
  length(evidence_start) == 1L && length(bundle_start) == 1L &&
    evidence_start < bundle_start,
  "workflow has one raw evidence lane before the candidate build"
)
evidence_block <- paste(
  workflow_lines[evidence_start:(bundle_start - 1L)],
  collapse = "\n"
)
expect_true(
  lengths(regmatches(
    evidence_block,
    gregexpr(
      "always() && github.event_name == 'workflow_dispatch' && inputs.skip_download == false",
      evidence_block, fixed = TRUE
    )
  )) == 2L &&
    grepl(
      "expected=$(printf '%s\\n' DP1.20120.001_all.rds DP1.20120.001_fetch_evidence.json",
      evidence_block, fixed = TRUE
    ) &&
    grepl(
      "DP1.20120.001_fetch_evidence.json DP1.20120.001_source_receipt.json",
      evidence_block, fixed = TRUE
    ) &&
    grepl("if [[ -f ../inverts-data-fetch/DP1.20120.001_source_receipt.json ]]",
          evidence_block, fixed = TRUE) &&
    grepl("name: invert-source-${{ env.SOURCE_SHA }}", evidence_block,
          fixed = TRUE) &&
    grepl("retention-days: 90", evidence_block, fixed = TRUE) &&
    !grepl("invert-fetch-evidence-${{ env.SOURCE_SHA }}", evidence_block,
           fixed = TRUE),
  paste(
    "manual full fetch uploads raw bytes once: two evidence members after",
    "validation failure and the authoritative receipt only after success"
  )
)
bundle_block <- paste(
  workflow_lines[bundle_start:min(length(workflow_lines), bundle_start + 5L)],
  collapse = "\n"
)
expect_true(
  grepl(
    "success() && github.event_name == 'workflow_dispatch' && inputs.skip_download == false",
    bundle_block, fixed = TRUE
  ),
  "candidate build remains success gated when source validation fails"
)
reconcile_start <- grep(
  "- name: Independently reconcile the full-fetch source to the candidate",
  workflow_lines, fixed = TRUE
)
cover_start <- grep(
  "- name: Verify the static and in-app Living Poster contract",
  workflow_lines, fixed = TRUE
)
reconcile_block <- paste(
  workflow_lines[reconcile_start:(cover_start - 1L)], collapse = "\n"
)
expect_true(
  length(reconcile_start) == 1L && length(cover_start) == 1L &&
    grepl(
      "DP1.20120.001_all.rds DP1.20120.001_fetch_evidence.json DP1.20120.001_source_receipt.json",
      reconcile_block, fixed = TRUE
    ) && grepl("RAW_EVIDENCE:", reconcile_block, fixed = TRUE) &&
    grepl("inv_verify_fetch_source_handoff", reconcile_block, fixed = TRUE),
  paste(
    "successful validator requires the exact three-member raw-source artifact",
    "and semantically reconciles the evidence receipt"
  )
)

unlink(receipt_root, recursive = TRUE, force = TRUE)
cat(sprintf("Source contract fixtures OK: %d adversarial/deterministic checks.\n", checks))
