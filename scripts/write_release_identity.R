#!/usr/bin/env Rscript
# Build or verify the deterministic Pages + Connect production identity.
#
# The identity is created only in the clean validator after the exact data
# family, derived indexes, and a preliminary Connect manifest exist. The final
# manifest may add release/production-identity.json to its file map without a
# hash cycle: the identity binds the canonical non-file manifest contract and
# the complete source-path list with the identity file excluded.

suppressPackageStartupMessages({
  library(jsonlite)
  library(digest)
})
source("scripts/release_path_safety.R", local = TRUE)

ROOT <- Sys.getenv("INV_OUTPUT_ROOT", ".")
MODE <- tolower(trimws(Sys.getenv("INV_RELEASE_IDENTITY_MODE", "verify")))
WRITE_PAGES <- identical(Sys.getenv("INV_WRITE_PAGES_RELEASE", "0"), "1")
if (!MODE %in% c("write", "verify")) {
  stop("INV_RELEASE_IDENTITY_MODE must be 'write' or 'verify'.", call. = FALSE)
}

APP_ID <- "NEON-My-Little-Inverts"
PRODUCT <- "DP1.20120.001"
RELEASE <- "RELEASE-2026"
DOI <- "10.48443/hp56-s582"
DOI_URL <- paste0("https://doi.org/", DOI)
PRODUCT_URL <- paste0(
  "https://data.neonscience.org/data-products/", PRODUCT, "/", RELEASE
)
QUERY_PACKAGE <- "basic"
ARTIFACT_FILE <- "DP1.20120.001_all.rds"
CITATION_OBJECT <- "citation_20120_RELEASE-2026"
PRODUCER_R_VERSION <- "4.5.2"
NEON_UTILITIES_VERSION <- "4.0.1"
NEON_UTILITIES_SOURCE <- paste0(
  "https://packagemanager.posit.co/cran/2026-07-15/src/contrib/",
  "neonUtilities_4.0.1.tar.gz"
)
REQUIRED_TABLES <- c(
  "inv_fieldData", "inv_persample", "inv_taxonomyProcessed"
)
REQUIRED_METADATA <- c(
  "categoricalCodes_20120", "issueLog_20120", "readme_20120",
  "validation_20120", "variables_20120"
)
OBJECT_NAMES <- sort(c(
  REQUIRED_TABLES, REQUIRED_METADATA, CITATION_OBJECT
), method = "radix")
RECEIPT_MEMBERS <- c(
  "receipt_schema_version", "fetched_at_utc", "source_request", "release",
  "producer", "citation", "artifact", "object_names", "required_tables",
  "required_metadata", "all_objects", "site_ids", "segregation",
  "relations", "measurement_metadata"
)
SOURCE_REQUEST_MEMBERS <- c(
  "dpid", "site", "startdate", "enddate", "package", "table",
  "time_index", "cloud_mode", "release", "include_provisional"
)
SOURCE_MEMBERS <- c(
  "dpid", "release", "include_provisional", "package", "doi", "doi_url",
  "product_url", "fetched_at_utc", "publication_date_max", "artifact_file",
  "artifact_bytes", "artifact_sha256", "receipt_schema_version",
  "receipt_sha256", "citation_object", "citation_sha256", "table_rows",
  "metadata_rows", "segregation", "producer_git_sha", "producer_r_version",
  "neonUtilities_version", "neonUtilities_source"
)
SEGREGATION_MEMBERS <- c(
  "collection_field_rows", "metabarcode_field_rows",
  "metabarcode_sample_ids", "metabarcode_site_ids",
  "per_sample_quarantine", "taxonomy_key_reconciliation",
  "dna_family_quarantine", "displayed_zero_percent", "count_unavailable",
  "unresolved_taxonomy"
)
# Independently pin the exact RELEASE-2026 sampleID-primary source relation.
# JSON arrays do not retain R vector names, so the three array orders are fixed
# here: source tables; then practical/per/taxonomy/field-without-per/
# taxonomy-without-per projections.
PRODUCTION_RELATIONS <- list(
  practical_field_rows = 6485L,
  impractical_field_rows = 713L,
  per_sample_rows = 6442L,
  taxonomy_rows = 320068L,
  processed_without_taxonomy = 0L,
  blank_sample_code_rows = c(1602L, 1573L, 83303L),
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
    "2f5fa079e78b81b4e99241d6dce50b4cc60ca9daaf3675ba4b8879d9c7ffe955",
    "0f2172bf0b695b1b64b28f6f619760e7c514b1ec2333699c39783ea1820d5fba",
    "b27cecdbde49204a5a4dc8bcdde1b2175800e7f74784d3a3a5ddb8191f860450",
    "8ab5887e1c7e63e03141b854d55177112c0f2a5e7dca45c4bcd27c79edaf24c4",
    "43cf28a696276245be1d789d2857bd7be0a4bd150d7cd23da6a834324f678d7e"
  ),
  uid_inventory_sha256 = c(
    "7a4553dbb591b962fdd7845846b7f379dceff84c2f18385d191011606c863cf5",
    "26732748813a8823d771c47721f688f957728093c3db327fbe261944ee84829e",
    "1fe075a27ace2dd66bbdcb76b38168439b6d1fd7922342f35a61dc9236e62760",
    "272168e8468021c811ab2037dc53e3dd800f28f4d4342bbb6d7091d83e943d8e",
    "7090552ea8cedb3dd75ec1799047c678a596c9d18078bed498396033aedaf6f6"
  )
)
DOMAIN <- "neon-my-little-inverts-production-instance-v1"
MANIFEST_DOMAIN <- "neon-connect-manifest-contract-v1"
MANIFEST_SOURCES_DOMAIN <- "neon-connect-manifest-source-list-v1"
BUNDLE_DOMAIN <- "neon-inverts-bundle-family-v1"
PAYLOAD_DOMAIN <- "neon-inverts-runtime-payload-v1"
PAGES_DOMAIN <- "neon-inverts-pages-payload-v1"
DEPLOYED_R_HELPERS <- c(
  "R/inv_helpers.R", "R/report_pdf.R", "R/site_metadata.R"
)

EXPECTED_SITES <- c(
  "ARIK", "BARC", "BIGC", "BLDE", "BLUE", "BLWA", "CARI", "COMO",
  "CRAM", "CUPE", "FLNT", "GUIL", "HOPB", "KING", "LECO", "LEWI",
  "LIRO", "MART", "MAYF", "MCDI", "MCRA", "OKSR", "POSE", "PRIN",
  "PRLA", "PRPO", "REDB", "SUGG", "SYCA", "TECR", "TOMB", "TOOK",
  "WALK", "WLOU"
)

identity_path <- file.path(ROOT, "release", "production-identity.json")
pages_path <- file.path(ROOT, "docs", "release.json")
contract_path <- file.path(ROOT, "data", "release_contract.rds")
receipt_path <- file.path(ROOT, "data", "source_receipt.json")
manifest_path <- file.path(ROOT, "manifest.json")
identity_relative <- "release/production-identity.json"
pages_relative <- "docs/release.json"

sha256_file <- function(path) {
  unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
}

sha256_text <- function(domain, text) {
  unname(digest::digest(
    paste(domain, text, sep = "\n"), algo = "sha256", serialize = FALSE
  ))
}

scalar <- function(value) {
  if (is.null(value) || length(value) != 1L || is.na(value)) "" else
    as.character(value)
}

valid_sha256 <- function(value) {
  grepl("^[0-9a-f]{64}$", scalar(value))
}

valid_git_sha <- function(value) {
  grepl("^[0-9a-f]{40}$", scalar(value))
}

valid_utc_second <- function(value) {
  value <- scalar(value)
  if (!grepl(
      "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$",
      value
  )) return(FALSE)
  parsed <- suppressWarnings(as.POSIXct(strptime(
    value, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"
  )))
  !is.na(parsed) &&
    identical(format(parsed, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), value)
}

valid_iso_date <- function(value) {
  value <- scalar(value)
  if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", value)) return(FALSE)
  parsed <- suppressWarnings(as.Date(value, format = "%Y-%m-%d"))
  !is.na(parsed) && identical(format(parsed, "%Y-%m-%d"), value)
}

sha256_literal <- function(value) {
  unname(digest::digest(value, algo = "sha256", serialize = FALSE))
}

value_equal <- function(actual, expected) {
  if (is.data.frame(actual) || is.data.frame(expected)) {
    if (!is.data.frame(actual) || !is.data.frame(expected) ||
        !identical(names(actual), names(expected)) ||
        nrow(actual) != nrow(expected)) return(FALSE)
    return(all(vapply(names(expected), function(field) {
      value_equal(actual[[field]], expected[[field]])
    }, logical(1))))
  }
  if (is.list(actual) || is.list(expected)) {
    if (!is.list(actual) || !is.list(expected) ||
        length(actual) != length(expected) ||
        !identical(names(actual), names(expected))) return(FALSE)
    return(all(vapply(seq_along(expected), function(index) {
      value_equal(actual[[index]], expected[[index]])
    }, logical(1))))
  }
  if (!identical(names(actual), names(expected)) ||
      length(actual) != length(expected)) return(FALSE)
  if (is.numeric(actual) || is.integer(actual) ||
      is.numeric(expected) || is.integer(expected)) {
    return(identical(as.numeric(actual), as.numeric(expected)))
  }
  if (is.logical(actual) || is.logical(expected)) {
    return(identical(as.logical(actual), as.logical(expected)))
  }
  identical(as.character(actual), as.character(expected))
}

validate_object_summary <- function(summary, label) {
  valid <- is.list(summary) && identical(names(summary), c(
    "class", "row_count", "columns", "column_classes"
  )) && grepl(
    "(^|/)data[.]frame($|/)", scalar(summary$class), perl = TRUE
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
      nzchar(scalar(value))
    }, logical(1)))
  if (!isTRUE(valid)) {
    stop("Published source receipt ", label,
         " schema inventory is invalid.", call. = FALSE)
  }
  invisible(summary)
}

validate_source_receipt <- function(receipt, receipt_path) {
  if (!is.list(receipt) || !identical(names(receipt), RECEIPT_MEMBERS)) {
    stop("Published source receipt member set is not exact.", call. = FALSE)
  }
  request <- receipt$source_request
  release <- receipt$release
  producer <- receipt$producer
  citation <- receipt$citation
  artifact <- receipt$artifact
  request_ok <- is.list(request) &&
    identical(names(request), SOURCE_REQUEST_MEMBERS) &&
    identical(scalar(request$dpid), PRODUCT) &&
    identical(scalar(request$site), "all") &&
    identical(scalar(request$startdate), "all") &&
    identical(scalar(request$enddate), "all") &&
    identical(scalar(request$package), QUERY_PACKAGE) &&
    identical(scalar(request$table), "all") &&
    identical(scalar(request$time_index), "all") &&
    identical(request$cloud_mode, FALSE) &&
    identical(scalar(request$release), RELEASE) &&
    identical(request$include_provisional, FALSE)
  release_ok <- is.list(release) &&
    identical(names(release), c("tag", "product_url", "doi", "doi_url")) &&
    identical(scalar(release$tag), RELEASE) &&
    identical(scalar(release$product_url), PRODUCT_URL) &&
    identical(scalar(release$doi), DOI) &&
    identical(scalar(release$doi_url), DOI_URL)
  producer_ok <- is.list(producer) && identical(names(producer), c(
    "git_sha", "r_version", "neonUtilities_version", "neonUtilities_source"
  )) && valid_git_sha(producer$git_sha) &&
    identical(scalar(producer$r_version), PRODUCER_R_VERSION) &&
    identical(scalar(producer$neonUtilities_version),
              NEON_UTILITIES_VERSION) &&
    identical(scalar(producer$neonUtilities_source), NEON_UTILITIES_SOURCE)
  citation_text <- scalar(citation$text)
  citation_ok <- is.list(citation) &&
    identical(names(citation), c("object", "text", "sha256")) &&
    identical(scalar(citation$object), CITATION_OBJECT) &&
    nzchar(citation_text) && grepl(PRODUCT, citation_text, fixed = TRUE) &&
    grepl(RELEASE, citation_text, fixed = TRUE) &&
    grepl(DOI, citation_text, fixed = TRUE) &&
    grepl(PRODUCT_URL, citation_text, fixed = TRUE) &&
    valid_sha256(citation$sha256) &&
    identical(sha256_literal(citation_text), scalar(citation$sha256))
  artifact_bytes <- suppressWarnings(as.numeric(artifact$bytes))
  artifact_ok <- is.list(artifact) &&
    identical(names(artifact), c("file", "bytes", "sha256")) &&
    identical(scalar(artifact$file), ARTIFACT_FILE) &&
    length(artifact_bytes) == 1L && is.finite(artifact_bytes) &&
    artifact_bytes > 0 && artifact_bytes == floor(artifact_bytes) &&
    valid_sha256(artifact$sha256)
  if (!identical(scalar(receipt$receipt_schema_version), "1.2.0") ||
      !valid_utc_second(receipt$fetched_at_utc) || !request_ok ||
      !release_ok || !producer_ok || !citation_ok || !artifact_ok) {
    stop("Published source receipt authority is invalid.", call. = FALSE)
  }
  if (!identical(as.character(receipt$object_names), OBJECT_NAMES) ||
      !is.list(receipt$required_tables) ||
      !identical(names(receipt$required_tables), REQUIRED_TABLES) ||
      !is.list(receipt$required_metadata) ||
      !identical(names(receipt$required_metadata), REQUIRED_METADATA) ||
      !is.list(receipt$all_objects) ||
      !identical(names(receipt$all_objects), OBJECT_NAMES) ||
      !identical(as.character(receipt$site_ids), EXPECTED_SITES) ||
      !is.list(receipt$segregation) ||
      !identical(names(receipt$segregation), SEGREGATION_MEMBERS)) {
    stop("Published source receipt object inventory is not exact.",
         call. = FALSE)
  }
  if (!value_equal(receipt$relations, PRODUCTION_RELATIONS)) {
    stop("Published source receipt relation authority is invalid.",
         call. = FALSE)
  }
  for (object_name in c(REQUIRED_TABLES, REQUIRED_METADATA)) {
    validate_object_summary(
      receipt$all_objects[[object_name]], paste("all_objects", object_name)
    )
  }
  citation_summary <- receipt$all_objects[[CITATION_OBJECT]]
  if (!is.list(citation_summary) ||
      !identical(names(citation_summary), c("class", "length")) ||
      !identical(scalar(citation_summary$class), "character") ||
      as.integer(citation_summary$length) < 1L) {
    stop("Published source receipt citation schema is invalid.", call. = FALSE)
  }
  for (table_name in REQUIRED_TABLES) {
    if (!value_equal(receipt$required_tables[[table_name]],
                     receipt$all_objects[[table_name]])) {
      stop("Published source receipt required-table inventory drifts.",
           call. = FALSE)
    }
  }
  for (metadata_name in REQUIRED_METADATA) {
    if (!value_equal(receipt$required_metadata[[metadata_name]],
                     receipt$all_objects[[metadata_name]])) {
      stop("Published source receipt metadata inventory drifts.",
           call. = FALSE)
    }
  }
  if (!file.exists(receipt_path)) {
    stop("Published source receipt file is missing.", call. = FALSE)
  }
  invisible(receipt)
}

named_receipt_vector <- function(value, field_names, mode) {
  value <- unlist(value, recursive = FALSE, use.names = FALSE)
  if (!length(value)) {
    return(switch(mode, integer = integer(), numeric = numeric(),
                  character = character()))
  }
  if (length(value) != length(field_names)) {
    stop("Published source receipt named-vector inventory is invalid.",
         call. = FALSE)
  }
  value <- switch(
    mode,
    integer = as.integer(value), numeric = as.numeric(value),
    character = as.character(value)
  )
  stats::setNames(value, field_names)
}

receipt_rows <- function(rows, columns) {
  data.frame(stats::setNames(lapply(columns, function(column) {
    vapply(rows, function(row) {
      value <- row[[column]]
      if (is.null(value) || !length(value)) NA_character_ else
        as.character(value[[1L]])
    }, character(1))
  }), columns), check.names = FALSE, stringsAsFactors = FALSE)
}

contract_segregation <- function(segregation) {
  out <- segregation
  taxonomy <- out$taxonomy_key_reconciliation
  if (!is.null(taxonomy$metadata)) {
    metadata_columns <- c(
      "fieldName", "description", "dataType", "units", "downloadPkg",
      "pubFormat", "primaryKey", "categoricalCodeName"
    )
    taxonomy$metadata <- receipt_rows(taxonomy$metadata, metadata_columns)
  }
  if (!is.null(taxonomy$group_size_counts)) {
    group_names <- if (length(taxonomy$group_size_counts)) {
      as.character(2:(length(taxonomy$group_size_counts) + 1L))
    } else character()
    taxonomy$group_size_counts <- named_receipt_vector(
      taxonomy$group_size_counts, group_names, "integer"
    )
  }
  if (!is.null(taxonomy$laboratory_group_counts)) {
    laboratory_names <- if (length(taxonomy$laboratory_group_counts)) c(
      "EcoAnalysts Inc.", "GEI Consultants Inc.", "Rhithron Associates, Inc."
    ) else character()
    taxonomy$laboratory_group_counts <- named_receipt_vector(
      taxonomy$laboratory_group_counts, laboratory_names, "integer"
    )
  }
  out$taxonomy_key_reconciliation <- taxonomy

  dna <- out$dna_family_quarantine
  dna_names <- c(
    "inv_fieldData", "inv_persample", "inv_taxonomyProcessed"
  )
  if (!is.null(dna$rows)) {
    dna$rows <- named_receipt_vector(dna$rows, dna_names, "integer")
  }
  if (!is.null(dna$taxonomy_rows_by_sample)) {
    dna$taxonomy_rows_by_sample <- named_receipt_vector(
      dna$taxonomy_rows_by_sample, as.character(dna$sample_ids), "integer"
    )
  }
  for (field in c("uid_inventory_sha256", "row_inventory_sha256")) {
    if (!is.null(dna[[field]])) {
      dna[[field]] <- named_receipt_vector(
        dna[[field]], dna_names, "character"
      )
    }
  }
  out$dna_family_quarantine <- dna

  displayed <- out$displayed_zero_percent
  for (field in c(
      "estimated_total_count_range", "individual_count_range",
      "displayed_zero_minus_200x_range")) {
    if (!is.null(displayed[[field]])) {
      displayed[[field]] <- named_receipt_vector(
        displayed[[field]], c("min", "max"), "numeric"
      )
    }
  }
  out$displayed_zero_percent <- displayed

  count_unavailable <- out$count_unavailable
  if (!is.null(count_unavailable$issue_counts)) {
    issue_names <- if (length(count_unavailable$issue_counts)) {
      "estimated_count_unavailable"
    } else character()
    count_unavailable$issue_counts <- named_receipt_vector(
      count_unavailable$issue_counts, issue_names, "integer"
    )
  }
  out$count_unavailable <- count_unavailable

  unresolved <- out$unresolved_taxonomy
  unresolved_names <- list(
    target_taxa_present_counts = "N",
    identification_remark_counts = c(
      "2nd oligochaeta slide created", "<blank>",
      "No BMI specimens present in sample", "No organisms found",
      "Oligochaeta slide created by lab with no taxon information",
      "no individuals in sample", "no organisms found",
      "sample arrived broken and not recoverable"
    ),
    sample_condition_counts = c(
      "<blank>", "damaged, affecting taxonomy", "other (specified in remarks)"
    )
  )
  for (field in names(unresolved_names)) {
    if (!is.null(unresolved[[field]])) {
      field_names <- if (length(unresolved[[field]])) {
        unresolved_names[[field]]
      } else character()
      unresolved[[field]] <- named_receipt_vector(
        unresolved[[field]], field_names, "integer"
      )
    }
  }
  out$unresolved_taxonomy <- unresolved
  out
}

expected_source_from_receipt <- function(receipt, receipt_path,
                                         publication_date_max) {
  table_rows <- vapply(REQUIRED_TABLES, function(table_name) {
    as.integer(receipt$required_tables[[table_name]]$row_count)
  }, integer(1))
  metadata_rows <- vapply(REQUIRED_METADATA, function(table_name) {
    as.integer(receipt$required_metadata[[table_name]]$row_count)
  }, integer(1))
  list(
    dpid = scalar(receipt$source_request$dpid),
    release = scalar(receipt$source_request$release),
    include_provisional = isTRUE(receipt$source_request$include_provisional),
    package = scalar(receipt$source_request$package),
    doi = scalar(receipt$release$doi),
    doi_url = scalar(receipt$release$doi_url),
    product_url = scalar(receipt$release$product_url),
    fetched_at_utc = scalar(receipt$fetched_at_utc),
    publication_date_max = as.character(publication_date_max),
    artifact_file = scalar(receipt$artifact$file),
    artifact_bytes = as.numeric(receipt$artifact$bytes),
    artifact_sha256 = scalar(receipt$artifact$sha256),
    receipt_schema_version = scalar(receipt$receipt_schema_version),
    receipt_sha256 = sha256_file(receipt_path),
    citation_object = scalar(receipt$citation$object),
    citation_sha256 = scalar(receipt$citation$sha256),
    table_rows = table_rows,
    metadata_rows = metadata_rows,
    segregation = contract_segregation(receipt$segregation),
    producer_git_sha = scalar(receipt$producer$git_sha),
    producer_r_version = scalar(receipt$producer$r_version),
    neonUtilities_version = scalar(receipt$producer$neonUtilities_version),
    neonUtilities_source = scalar(receipt$producer$neonUtilities_source)
  )
}

read_exact <- function(path) {
  if (!file.exists(path) || dir.exists(path)) return(NA_character_)
  size <- file.info(path)$size
  if (is.na(size) || size <= 0) return(NA_character_)
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  rawToChar(readBin(connection, what = "raw", n = size))
}

write_exact <- function(relative, contents) {
  path <- inv_prepare_safe_output(ROOT, relative, "production identity")
  connection <- file(path, open = "wb")
  on.exit(close(connection), add = TRUE)
  writeBin(charToRaw(contents), connection)
}

canonical_object <- function(value) {
  if (!is.list(value)) return(value)
  keys <- names(value)
  if (is.null(keys)) return(lapply(value, canonical_object))
  index <- order(keys, method = "radix")
  output <- lapply(value[index], canonical_object)
  names(output) <- keys[index]
  output
}

files_below <- function(directory, pattern = NULL, recursive = TRUE,
                        all_files = FALSE) {
  base <- file.path(ROOT, directory)
  if (!dir.exists(base)) return(character())
  if (!isTRUE(recursive)) {
    stop("Production identity requires recursive safe enumeration.",
         call. = FALSE)
  }
  inv_list_release_files(
    ROOT, directory, all_files = all_files, pattern = pattern
  )
}

normalize_relative <- function(paths) {
  sort(unique(gsub("\\\\", "/", paths)), method = "radix")
}

assert_safe_paths <- function(paths, label) {
  inv_assert_safe_relative_paths(ROOT, paths, label, expected = "file")
  invisible(TRUE)
}

hash_family <- function(paths, domain) {
  assert_safe_paths(paths, domain)
  entries <- paste(
    paths, vapply(file.path(ROOT, paths), sha256_file, character(1)), sep = "\t"
  )
  sha256_text(domain, paste0(paste(entries, collapse = "\n"), "\n"))
}

required <- c(contract_path, receipt_path, manifest_path)
missing <- required[
  !file.exists(required) | dir.exists(required) |
    is.na(file.info(required)$size) | file.info(required)$size <= 0
]
if (length(missing)) {
  stop("Cannot create production identity without: ",
       paste(missing, collapse = ", "), call. = FALSE)
}
assert_safe_paths(
  c("data/release_contract.rds", "data/source_receipt.json", "manifest.json"),
  "identity input"
)

contract <- readRDS(contract_path)
receipt <- jsonlite::fromJSON(
  receipt_path, simplifyVector = TRUE, simplifyDataFrame = FALSE,
  simplifyMatrix = FALSE
)
if (!is.list(contract) ||
    !identical(scalar(contract$schema_version), "1.0.0") ||
    !identical(scalar(contract$producer_schema_version), "2.1.0") ||
    !identical(scalar(contract$bundle_schema_version), "2.1.0") ||
    !identical(as.character(contract$site_ids), EXPECTED_SITES)) {
  stop("Release contract is not the exact reviewed 34-site family.", call. = FALSE)
}

source <- contract$source
if (!is.list(source) || !identical(names(source), SOURCE_MEMBERS) ||
    !valid_iso_date(source$publication_date_max) ||
    !valid_git_sha(source$producer_git_sha) ||
    !valid_sha256(source$artifact_sha256) ||
    !valid_sha256(source$receipt_sha256) ||
    !valid_sha256(source$citation_sha256)) {
  stop("Release contract source identity is invalid.", call. = FALSE)
}

validate_source_receipt(receipt, receipt_path)
source_receipt_sha256 <- sha256_file(receipt_path)
expected_source <- expected_source_from_receipt(
  receipt, receipt_path, scalar(source$publication_date_max)
)
if (!identical(source_receipt_sha256, scalar(source$receipt_sha256)) ||
    !value_equal(source, expected_source)) {
  stop("Published source receipt differs from the release contract.", call. = FALSE)
}

bundle_hashes <- contract$bundle_sha256
if (is.null(names(bundle_hashes)) ||
    !identical(names(bundle_hashes), EXPECTED_SITES) ||
    !all(vapply(bundle_hashes, valid_sha256, logical(1)))) {
  stop("Release contract bundle hashes are not the exact site family.", call. = FALSE)
}
bundle_paths <- file.path("data", "sites", paste0(EXPECTED_SITES, ".rds"))
assert_safe_paths(bundle_paths, "bundle family")
actual_bundle_hashes <- vapply(
  file.path(ROOT, bundle_paths), sha256_file, character(1)
)
if (!identical(unname(actual_bundle_hashes), unname(as.character(bundle_hashes)))) {
  stop("Site bundle bytes differ from the release contract.", call. = FALSE)
}
bundle_entries <- paste(EXPECTED_SITES, as.character(bundle_hashes), sep = "\t")
bundle_family_sha256 <- sha256_text(
  BUNDLE_DOMAIN, paste0(paste(bundle_entries, collapse = "\n"), "\n")
)

derived_paths <- c(
  site_index_sha256 = "data/site_index.rds",
  cross_site_sha256 = "data/cross_site.rds",
  search_index_sha256 = "data/search_index.rds",
  demo_bundle_sha256 = "data-sample/demo.rds"
)
assert_safe_paths(unname(derived_paths), "derived release")
derived_hashes <- vapply(
  file.path(ROOT, unname(derived_paths)), sha256_file, character(1)
)
names(derived_hashes) <- names(derived_paths)
if (!identical(unname(derived_hashes[["demo_bundle_sha256"]]),
               unname(as.character(bundle_hashes[["SYCA"]])))) {
  stop("Demo bundle is not byte-identical to the reviewed SYCA bundle.",
       call. = FALSE)
}

manifest <- jsonlite::fromJSON(manifest_path, simplifyVector = FALSE)
manifest_fields <- c(
  "version", "locale", "platform", "metadata", "packages", "files", "users"
)
if (!is.list(manifest) || length(names(manifest)) != length(manifest_fields) ||
    !setequal(names(manifest), manifest_fields) ||
    !is.list(manifest$packages) || !length(manifest$packages) ||
    !is.list(manifest$files) || !length(manifest$files)) {
  stop("Connect manifest lacks the exact dependency and source-list contract.",
       call. = FALSE)
}

manifest_raw_paths <- gsub("\\\\", "/", names(manifest$files))
if (anyDuplicated(manifest_raw_paths)) {
  stop("Connect manifest source paths are not unique.", call. = FALSE)
}
manifest_checksums <- vapply(manifest$files, function(entry) {
  if (!is.list(entry)) return("")
  scalar(entry$checksum)
}, character(1))
names(manifest_checksums) <- manifest_raw_paths
manifest_paths <- normalize_relative(manifest_raw_paths)
assert_safe_paths(manifest_paths, "Connect manifest")
runtime_paths <- normalize_relative(c(
  "global.R", "ui.R", "server.R",
  DEPLOYED_R_HELPERS,
  files_below("www"), files_below("data"), files_below("data-sample")
))
runtime_paths <- setdiff(runtime_paths, identity_relative)
assert_safe_paths(runtime_paths, "runtime payload")
expected_manifest_paths <- normalize_relative(c(
  runtime_paths, if (identical(MODE, "verify")) identity_relative else character()
))
if (!identical(manifest_paths, expected_manifest_paths)) {
  stop("Connect manifest source list differs from the exact runtime payload.",
       call. = FALSE)
}
if (identical(MODE, "write") && identity_relative %in% manifest_paths) {
  stop("Write mode requires a preliminary manifest without the identity file.",
       call. = FALSE)
}
if (identical(MODE, "verify") && !identity_relative %in% manifest_paths) {
  stop("Verify mode requires a final manifest containing the identity file.",
       call. = FALSE)
}
if (any(!grepl("^[0-9a-fA-F]{32}$", manifest_checksums))) {
  stop("Connect manifest contains an invalid file checksum.", call. = FALSE)
}
actual_manifest_md5 <- unname(tools::md5sum(file.path(ROOT, manifest_paths)))
expected_manifest_md5 <- tolower(unname(manifest_checksums[manifest_paths]))
if (any(is.na(actual_manifest_md5)) ||
    !identical(tolower(actual_manifest_md5), expected_manifest_md5)) {
  stop("Connect manifest checksum map differs from deployed file bytes.",
       call. = FALSE)
}

runtime_payload_sha256 <- hash_family(runtime_paths, PAYLOAD_DOMAIN)
manifest_source_list_sha256 <- sha256_text(
  MANIFEST_SOURCES_DOMAIN,
  paste0(paste(runtime_paths, collapse = "\n"), "\n")
)
manifest_contract <- list(
  version = manifest$version,
  locale = manifest$locale,
  platform = manifest$platform,
  metadata = canonical_object(manifest$metadata),
  packages = canonical_object(manifest$packages),
  users = canonical_object(manifest$users)
)
manifest_contract_json <- as.character(jsonlite::toJSON(
  manifest_contract, auto_unbox = TRUE, pretty = FALSE, null = "null",
  na = "null"
))
manifest_contract_sha256 <- sha256_text(
  MANIFEST_DOMAIN, manifest_contract_json
)

pages_paths <- setdiff(
  normalize_relative(files_below("docs", all_files = TRUE)),
  "docs/release.json"
)
required_pages <- c("docs/index.html", "docs/og-image-v2.png")
if (length(setdiff(required_pages, pages_paths))) {
  stop("Pages payload lacks the cover or social image.", call. = FALSE)
}
assert_safe_paths(pages_paths, "Pages payload")
pages_payload_sha256 <- hash_family(pages_paths, PAGES_DOMAIN)

release_contract_sha256 <- sha256_file(contract_path)
identity_values <- c(
  APP_ID, PRODUCT, RELEASE, DOI,
  scalar(source$artifact_sha256), source_receipt_sha256,
  release_contract_sha256, bundle_family_sha256,
  unname(derived_hashes[["site_index_sha256"]]),
  unname(derived_hashes[["cross_site_sha256"]]),
  unname(derived_hashes[["search_index_sha256"]]),
  unname(derived_hashes[["demo_bundle_sha256"]]),
  runtime_payload_sha256, pages_payload_sha256,
  manifest_contract_sha256, manifest_source_list_sha256
)
release_id <- paste0(
  "sha256:", digest::digest(
    paste(c(DOMAIN, identity_values), collapse = "\n"),
    algo = "sha256", serialize = FALSE
  )
)

identity <- list(
  schema_version = 1L,
  app_id = APP_ID,
  product = PRODUCT,
  release = RELEASE,
  doi = DOI,
  source_artifact_sha256 = scalar(source$artifact_sha256),
  source_receipt_sha256 = source_receipt_sha256,
  release_contract_sha256 = release_contract_sha256,
  bundle_family_sha256 = bundle_family_sha256,
  site_index_sha256 = unname(derived_hashes[["site_index_sha256"]]),
  cross_site_sha256 = unname(derived_hashes[["cross_site_sha256"]]),
  search_index_sha256 = unname(derived_hashes[["search_index_sha256"]]),
  demo_bundle_sha256 = unname(derived_hashes[["demo_bundle_sha256"]]),
  runtime_payload_sha256 = runtime_payload_sha256,
  pages_payload_sha256 = pages_payload_sha256,
  manifest_contract_sha256 = manifest_contract_sha256,
  manifest_source_list_sha256 = manifest_source_list_sha256,
  release_id = release_id
)
canonical <- paste0(jsonlite::toJSON(
  identity, auto_unbox = TRUE, pretty = TRUE, null = "null"
), "\n")

if (identical(MODE, "verify") && WRITE_PAGES) {
  assert_safe_paths(pages_relative, "Pages release receipt")
}
if (identical(MODE, "write")) {
  write_exact(identity_relative, canonical)
  if (WRITE_PAGES) write_exact(pages_relative, canonical)
} else {
  if (!identical(read_exact(identity_path), canonical)) {
    stop("Committed production identity differs from its exact release bytes.",
         call. = FALSE)
  }
  if (WRITE_PAGES && !identical(read_exact(pages_path), canonical)) {
    stop("Pages release receipt differs from the exact production identity.",
         call. = FALSE)
  }
}
if (WRITE_PAGES &&
    !identical(read_exact(pages_path), read_exact(identity_path))) {
  stop("Pages release receipt is not byte-identical to the runtime identity.",
       call. = FALSE)
}

cat(sprintf(
  paste0(
    "OK: %s production instance %s binds %d bundles, %d runtime files, ",
    "%d Pages files, four derived artifacts, and the Connect manifest (%s).\n"
  ),
  RELEASE, release_id, length(bundle_paths), length(runtime_paths),
  length(pages_paths), MODE
))
