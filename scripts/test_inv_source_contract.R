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
  held_rows$siteID <- other_sites
  held_rows$decimalLatitude <- seq(30, 46, length.out = length(other_sites))
  held_rows$decimalLongitude <- seq(-120, -70, length.out = length(other_sites))
  field <- rbind(field, held_rows)
  dna_row <- field[1, , drop = FALSE]
  dna_row$eventID <- "SYCA.2024.metabarcode"
  dna_row$sampleID <- "SYCA.INV.S1.DNA"
  dna_row$sampleCode <- "INV-S1-DNA"
  dna_row$sampleNumber <- "DNA"
  field <- rbind(field, dna_row)

  per_sample <- data.frame(
    sampleID = "SYCA.INV.S1",
    sampleCode = "INV-S1",
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

  taxonomy <- data.frame(
    sampleID = "SYCA.INV.S1",
    sampleCode = "INV-S1",
    slideID = NA_character_,
    slideCode = NA_character_,
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
    dataQF = "taxonomy review note",
    publicationDate = "2026-01-23T00:00:00Z",
    release = INV_RELEASE,
    stringsAsFactors = FALSE
  )

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
      primaryKey = ifelse(fields %in% INV_PRIMARY_KEYS[[table_name]], "Y", "N"),
      categoricalCodeName = ifelse(
        table_name == "inv_fieldData" & fields == "samplingImpractical",
        "smp.samplingImpractical", ""
      ),
      stringsAsFactors = FALSE
    )
  }))
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

summary <- inv_validate_source(valid)
expect_true(identical(names(summary$tables), INV_REQUIRED_TABLES),
            "valid fixture carries all required analysis tables")
expect_true(identical(summary$relations$practical_field_rows, 1L),
            "valid fixture counts practical field rows")
expect_true(identical(summary$relations$impractical_field_rows, 34L),
            "valid fixture counts impractical field rows")
expect_true(identical(names(summary$relations), c(
  "practical_field_rows", "impractical_field_rows",
  "processed_without_taxonomy"
)), "source relation receipt uses exact unknown-not-zero terminology")
expect_true(identical(summary$relations$processed_without_taxonomy, 0L),
            "valid fixture has no processed sample without taxonomy")
expect_true(identical(summary$segregation$collection_field_rows, 35L),
            "valid fixture counts only non-.DNA collection field rows")
expect_true(identical(summary$segregation$metabarcode_field_rows, 1L),
            "valid fixture segregates its .DNA field row")
expect_true(identical(summary$segregation$metabarcode_sample_ids,
                      "SYCA.INV.S1.DNA"),
            "valid fixture records the segregated .DNA identity")
expect_true(all(vapply(names(INV_VF_QC_COLUMNS), function(table_name) {
  all(INV_VF_QC_COLUMNS[[table_name]] %in% names(valid[[table_name]]))
}, logical(1))), "valid fixture carries every official vF QC field")
expect_true(all(INV_ISSUE_LOG_COLUMNS %in% names(valid$issueLog_20120)),
            "valid fixture carries the full official issue-log schema")

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
dna_row_index <- grepl("[.]DNA$", bad$inv_fieldData$sampleID)
bad$inv_fieldData$siteID[dna_row_index] <- "WLOU"
bad$inv_fieldData <- bad$inv_fieldData[
  !(bad$inv_fieldData$siteID == "WLOU" & !dna_row_index), , drop = FALSE
]
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
expect_error(inv_validate_source(bad), "[.]DNA inv_fieldData has an ambiguous repeated sampleID")

bad <- valid
dna_field <- bad$inv_fieldData[grepl("[.]DNA$", bad$inv_fieldData$sampleID), ]
dna_per_sample <- bad$inv_persample[1, ]
dna_per_sample$sampleID <- dna_field$sampleID
dna_per_sample$sampleCode <- dna_field$sampleCode
bad$inv_persample <- rbind(bad$inv_persample, dna_per_sample)
expect_error(inv_validate_source(bad), "inv_persample contains [.]DNA rows")

bad <- valid
dna_field <- bad$inv_fieldData[grepl("[.]DNA$", bad$inv_fieldData$sampleID), ]
dna_taxonomy <- bad$inv_taxonomyProcessed[1, ]
dna_taxonomy$sampleID <- dna_field$sampleID
dna_taxonomy$sampleCode <- dna_field$sampleCode
bad$inv_taxonomyProcessed <- rbind(bad$inv_taxonomyProcessed, dna_taxonomy)
expect_error(inv_validate_source(bad), "inv_taxonomyProcessed contains [.]DNA rows")

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
expect_error(inv_validate_source(bad), "duplicate RELEASE-2026 primary key")

bad <- valid
bad$inv_persample$sampleCode <- ""
expect_error(inv_validate_source(bad), "missing sampleID/sampleCode")

bad <- valid
bad$inv_persample <- bad$inv_persample[FALSE, , drop = FALSE]
expect_error(inv_validate_source(bad), "inv_persample has no rows")

bad <- valid
bad$inv_persample$sampleID <- "ORPHAN"
expect_error(inv_validate_source(bad), "practical inv_fieldData sample.*has no inv_persample")

bad <- valid
bad$inv_taxonomyProcessed$sampleID <- "ORPHAN"
expect_error(inv_validate_source(bad), "has no inv_persample parent")

bad <- valid
bad$inv_fieldData$samplingImpractical[1] <- "location dry"
expect_error(inv_validate_source(bad), "has no practical inv_fieldData parent")

bad <- valid
bad$inv_fieldData$samplingImpractical[2] <- "OK"
expect_error(inv_validate_source(bad), "missing sampleID/sampleCode")

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
zero_candidate$inv_taxonomyProcessed$sampleID <- "SECOND"
zero_candidate$inv_taxonomyProcessed$sampleCode <- "SECOND"
second_field <- zero_candidate$inv_fieldData[1, ]
second_field$sampleID <- "SECOND"
second_field$sampleCode <- "SECOND"
second_field$sampleNumber <- "3"
second_field$eventID <- "SYCA.2024.second"
zero_candidate$inv_fieldData <- rbind(zero_candidate$inv_fieldData, second_field)
second_per <- zero_candidate$inv_persample[1, ]
second_per$sampleID <- "SECOND"
second_per$sampleCode <- "SECOND"
zero_candidate$inv_persample <- rbind(zero_candidate$inv_persample, second_per)
zero_summary <- inv_validate_source(zero_candidate)
expect_true(identical(zero_summary$relations$processed_without_taxonomy, 1L),
            "per-sample row without taxonomy is retained as an unknown outcome")

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
