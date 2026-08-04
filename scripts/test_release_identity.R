#!/usr/bin/env Rscript
# Synthetic and adversarial tests for the Pages + Connect production identity.

suppressPackageStartupMessages({
  library(jsonlite)
  library(digest)
})

assert <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}

writer <- normalizePath("scripts/write_release_identity.R", mustWork = TRUE)
manifest_writer <- normalizePath("scripts/write_manifest.R", mustWork = TRUE)
rscript <- file.path(R.home("bin"), "Rscript")
fixture_parent <- tempfile("inverts-production-identity-")
dir.create(fixture_parent, recursive = TRUE, showWarnings = FALSE)
on.exit(unlink(fixture_parent, recursive = TRUE, force = TRUE), add = TRUE)

sites <- c(
  "ARIK", "BARC", "BIGC", "BLDE", "BLUE", "BLWA", "CARI", "COMO",
  "CRAM", "CUPE", "FLNT", "GUIL", "HOPB", "KING", "LECO", "LEWI",
  "LIRO", "MART", "MAYF", "MCDI", "MCRA", "OKSR", "POSE", "PRIN",
  "PRLA", "PRPO", "REDB", "SUGG", "SYCA", "TECR", "TOMB", "TOOK",
  "WALK", "WLOU"
)
fixture_git_sha <- paste(rep("e", 40L), collapse = "")
production_relations <- list(
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

write_bytes <- function(path, bytes) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  connection <- file(path, open = "wb")
  on.exit(close(connection), add = TRUE)
  writeBin(bytes, connection)
}

read_bytes <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  readBin(connection, what = "raw", n = file.info(path)$size)
}

sha256_file <- function(path) {
  unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
}

canonical_manifest <- function(root, files, reverse = FALSE) {
  packages <- list(
    alpha = list(
      Source = "CRAN", Repository = "https://example.invalid/snapshot",
      description = list(Package = "alpha", Version = "1.0.0")
    ),
    beta = list(
      Source = "CRAN", Repository = "https://example.invalid/snapshot",
      description = list(Package = "beta", Version = "2.0.0")
    )
  )
  file_map <- lapply(files, function(path) list(
    checksum = unname(tools::md5sum(file.path(root, path)))
  ))
  names(file_map) <- files
  value <- list(
    version = 1L, locale = "C", platform = "4.5.2",
    metadata = list(
      appmode = "shiny", primary_rmd = NULL, primary_html = NULL,
      content_category = NULL, has_parameters = FALSE
    ),
    packages = packages, files = file_map, users = NULL
  )
  if (reverse) {
    reverse_named <- function(item) {
      if (!is.list(item)) return(item)
      keys <- names(item)
      if (is.null(keys)) return(lapply(item, reverse_named))
      index <- rev(seq_along(item))
      output <- lapply(item[index], reverse_named)
      names(output) <- keys[index]
      output
    }
    value <- reverse_named(value)
  }
  value
}

write_manifest <- function(root, value) {
  write_bytes(file.path(root, "manifest.json"), charToRaw(paste0(
    jsonlite::toJSON(value, auto_unbox = TRUE, pretty = TRUE, null = "null"),
    "\n"
  )))
}

make_fixture <- function(root, reverse = FALSE) {
  simple <- c(
    "global.R" = "fixture global\n",
    "ui.R" = "fixture ui\n",
    "server.R" = "fixture server\n",
    "R/inv_helpers.R" = "fixture app helper\n",
    "R/report_pdf.R" = "fixture report helper\n",
    "R/site_metadata.R" = "fixture site metadata\n",
    "www/app.js" = "fixture app\n",
    "www/assets/poster.webp" = "fixture runtime poster\n",
    "data/site_index.rds" = "fixture site index\n",
    "data/cross_site.rds" = "fixture cross site\n",
    "data/search_index.rds" = "fixture search index\n",
    "docs/.nojekyll" = "",
    "docs/index.html" = "<main>fixture Pages poster</main>\n",
    "docs/og-image-v2.png" = "fixture social image\n",
    "docs/assets/inverts-living-poster-v2-840.webp" =
      "fixture responsive Pages poster\n",
    "docs/assets/inverts-living-poster-v2.png" =
      "fixture lossless Pages poster\n",
    "docs/assets/inverts-living-poster-v2.webp" =
      "fixture Pages poster\n",
    "docs/BUILD-TEST-HANDOFF.md" = if (reverse) {
      "fixture mutable handoff with different bytes\n"
    } else {
      "fixture mutable handoff\n"
    },
    "docs/DATA-TAKEAWAYS.md" = "fixture data takeaways\n",
    "docs/IMAGE-PROVENANCE.md" = "fixture image provenance\n",
    "docs/data-bundling-pattern.md" = "fixture bundling pattern\n",
    "docs/neonize-playbook.md" = "fixture app playbook\n"
  )
  order_paths <- names(simple)
  if (reverse) order_paths <- rev(order_paths)
  for (relative in order_paths) {
    write_bytes(file.path(root, relative), charToRaw(simple[[relative]]))
  }

  bundle_paths <- file.path("data", "sites", paste0(sites, ".rds"))
  bundle_order <- seq_along(sites)
  if (reverse) bundle_order <- rev(bundle_order)
  for (index in bundle_order) {
    write_bytes(
      file.path(root, bundle_paths[[index]]),
      charToRaw(paste0("fixture bundle ", sites[[index]], "\n"))
    )
  }
  write_bytes(
    file.path(root, "data-sample", "demo.rds"),
    read_bytes(file.path(root, "data", "sites", "SYCA.rds"))
  )

  artifact_sha256 <- paste(rep("a", 64L), collapse = "")
  object_summary <- function(rows, columns, class = "data.frame") {
    column_classes <- as.list(rep("character", length(columns)))
    names(column_classes) <- columns
    list(
      class = class, row_count = as.integer(rows), columns = columns,
      column_classes = column_classes
    )
  }
  required_tables <- list(
    inv_fieldData = object_summary(36L, c("uid", "publicationDate")),
    inv_persample = object_summary(35L, c("uid", "publicationDate")),
    inv_taxonomyProcessed = object_summary(
      35L, c("uid", "publicationDate")
    )
  )
  required_metadata <- list(
    categoricalCodes_20120 = object_summary(
      2L, c("name", "pubCode"), "tbl_df/tbl/data.frame"
    ),
    issueLog_20120 = object_summary(1L, c("id", "issue")),
    readme_20120 = object_summary(1L, "V1"),
    validation_20120 = object_summary(
      2L, c("table", "fieldName"), "tbl_df/tbl/data.frame"
    ),
    variables_20120 = object_summary(
      3L, c("table", "fieldName"), "data.table/data.frame"
    )
  )
  citation_text <- paste(
    "NEON DP1.20120.001 RELEASE-2026",
    "https://data.neonscience.org/data-products/DP1.20120.001/RELEASE-2026",
    "doi:10.48443/hp56-s582"
  )
  citation_summary <- list(class = "character", length = 1L)
  all_objects <- c(
    required_tables, required_metadata,
    list(`citation_20120_RELEASE-2026` = citation_summary)
  )
  object_names <- sort(names(all_objects), method = "radix")
  all_objects <- all_objects[object_names]
  segregation <- list(
    collection_field_rows = 35L,
    metabarcode_field_rows = 1L,
    metabarcode_sample_ids = "HOPB.fixture.DNA",
    metabarcode_site_ids = "HOPB",
    per_sample_quarantine = list(status = "fixture"),
    taxonomy_key_reconciliation = list(status = "fixture"),
    dna_family_quarantine = list(status = "fixture"),
    displayed_zero_percent = list(status = "fixture"),
    count_unavailable = list(status = "fixture"),
    unresolved_taxonomy = list(status = "fixture")
  )
  receipt <- list(
    receipt_schema_version = "1.2.0",
    fetched_at_utc = "2026-07-15T12:00:00Z",
    source_request = list(
      dpid = "DP1.20120.001", site = "all", startdate = "all",
      enddate = "all", package = "basic", table = "all",
      time_index = "all", cloud_mode = FALSE, release = "RELEASE-2026",
      include_provisional = FALSE
    ),
    release = list(
      tag = "RELEASE-2026",
      product_url = paste0(
        "https://data.neonscience.org/data-products/",
        "DP1.20120.001/RELEASE-2026"
      ),
      doi = "10.48443/hp56-s582",
      doi_url = "https://doi.org/10.48443/hp56-s582"
    ),
    producer = list(
      git_sha = fixture_git_sha, r_version = "4.5.2",
      neonUtilities_version = "4.0.1",
      neonUtilities_source = paste0(
        "https://packagemanager.posit.co/cran/2026-07-15/src/contrib/",
        "neonUtilities_4.0.1.tar.gz"
      )
    ),
    citation = list(
      object = "citation_20120_RELEASE-2026", text = citation_text,
      sha256 = unname(digest::digest(
        citation_text, algo = "sha256", serialize = FALSE
      ))
    ),
    artifact = list(
      file = "DP1.20120.001_all.rds", bytes = 12345,
      sha256 = artifact_sha256
    ),
    object_names = object_names,
    required_tables = required_tables,
    required_metadata = required_metadata,
    all_objects = all_objects,
    site_ids = sites,
    segregation = segregation,
    relations = production_relations,
    measurement_metadata = list()
  )
  receipt_path <- file.path(root, "data", "source_receipt.json")
  write_bytes(receipt_path, charToRaw(paste0(jsonlite::toJSON(
    receipt, auto_unbox = TRUE, pretty = TRUE, null = "null"
  ), "\n")))
  parsed_receipt <- jsonlite::fromJSON(
    receipt_path, simplifyVector = TRUE, simplifyDataFrame = FALSE,
    simplifyMatrix = FALSE
  )
  table_rows <- vapply(names(required_tables), function(table_name) {
    as.integer(parsed_receipt$required_tables[[table_name]]$row_count)
  }, integer(1))
  metadata_rows <- vapply(names(required_metadata), function(metadata_name) {
    as.integer(parsed_receipt$required_metadata[[metadata_name]]$row_count)
  }, integer(1))

  bundle_hashes <- vapply(
    file.path(root, bundle_paths), sha256_file, character(1)
  )
  names(bundle_hashes) <- sites
  contract <- list(
    schema_version = "1.0.0", producer_schema_version = "2.1.0",
    bundle_schema_version = "2.1.0", science_version = "fixture",
    source = list(
      dpid = "DP1.20120.001", release = "RELEASE-2026",
      include_provisional = FALSE, package = "basic",
      doi = "10.48443/hp56-s582",
      doi_url = "https://doi.org/10.48443/hp56-s582",
      product_url = paste0(
        "https://data.neonscience.org/data-products/",
        "DP1.20120.001/RELEASE-2026"
      ),
      fetched_at_utc = "2026-07-15T12:00:00Z",
      publication_date_max = "2026-01-01",
      artifact_file = "DP1.20120.001_all.rds",
      artifact_bytes = 12345,
      artifact_sha256 = artifact_sha256,
      receipt_schema_version = "1.2.0",
      receipt_sha256 = sha256_file(receipt_path),
      citation_object = "citation_20120_RELEASE-2026",
      citation_sha256 = as.character(parsed_receipt$citation$sha256),
      table_rows = table_rows,
      metadata_rows = metadata_rows,
      segregation = parsed_receipt$segregation,
      producer_git_sha = fixture_git_sha,
      producer_r_version = "4.5.2",
      neonUtilities_version = "4.0.1",
      neonUtilities_source = paste0(
        "https://packagemanager.posit.co/cran/2026-07-15/src/contrib/",
        "neonUtilities_4.0.1.tar.gz"
      )
    ),
    science_summary = list(), metric_contract = data.frame(),
    qc_contract = list(), site_ids = sites, bundle_sha256 = bundle_hashes,
    bundle_members = character(), support_index_only = TRUE,
    prohibited_cross_site_fields = character()
  )
  dir.create(file.path(root, "data"), recursive = TRUE, showWarnings = FALSE)
  saveRDS(contract, file.path(root, "data", "release_contract.rds"), version = 3)

  runtime_files <- sort(c(
    "global.R", "ui.R", "server.R", "R/inv_helpers.R", "R/report_pdf.R",
    "R/site_metadata.R", "www/app.js",
    "www/assets/poster.webp", "data/site_index.rds", "data/cross_site.rds",
    "data/search_index.rds", "data/source_receipt.json",
    "data/release_contract.rds", bundle_paths, "data-sample/demo.rds"
  ), method = "radix")
  if (reverse) runtime_files <- rev(runtime_files)
  write_manifest(root, canonical_manifest(root, runtime_files, reverse = reverse))
  invisible(runtime_files)
}

run_writer <- function(root, mode, expect_success) {
  output <- suppressWarnings(system2(
    rscript, c("--vanilla", shQuote(writer)), stdout = TRUE, stderr = TRUE,
    env = c(
      paste0("INV_OUTPUT_ROOT=", root),
      paste0("INV_RELEASE_IDENTITY_MODE=", mode),
      "INV_WRITE_PAGES_RELEASE=1"
    )
  ))
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  if (expect_success && status != 0L) {
    stop("Identity fixture unexpectedly failed:\n", paste(output, collapse = "\n"),
         call. = FALSE)
  }
  if (!expect_success && status == 0L) {
    stop("Identity fixture accepted tampered release bytes.", call. = FALSE)
  }
  invisible(output)
}

root_a <- file.path(fixture_parent, "forward")
root_b <- file.path(fixture_parent, "reverse")
make_fixture(root_a, reverse = FALSE)
make_fixture(root_b, reverse = TRUE)
run_writer(root_a, "write", expect_success = TRUE)
run_writer(root_b, "write", expect_success = TRUE)

identity_a <- read_bytes(file.path(root_a, "release", "production-identity.json"))
identity_b <- read_bytes(file.path(root_b, "release", "production-identity.json"))
assert(!identical(
  read_bytes(file.path(root_a, "docs", "BUILD-TEST-HANDOFF.md")),
  read_bytes(file.path(root_b, "docs", "BUILD-TEST-HANDOFF.md"))
), "Fixture did not vary the exact handoff bytes between write-mode builds.")
assert(identical(identity_a, identity_b),
       paste(
         "Production identity depends on object/file creation order or the",
         "exact mutable handoff bytes."
       ))
assert(identical(
  identity_a, read_bytes(file.path(root_a, "docs", "release.json"))
), "Runtime identity and Pages receipt are not byte-identical.")

identity <- jsonlite::fromJSON(rawToChar(identity_a), simplifyVector = FALSE)
expected_fields <- c(
  "schema_version", "app_id", "product", "release", "doi",
  "source_artifact_sha256", "source_receipt_sha256",
  "release_contract_sha256", "bundle_family_sha256", "site_index_sha256",
  "cross_site_sha256", "search_index_sha256", "demo_bundle_sha256",
  "runtime_payload_sha256", "pages_payload_sha256",
  "manifest_contract_sha256", "manifest_source_list_sha256", "release_id"
)
assert(identical(names(identity), expected_fields) &&
         identical(as.integer(identity$schema_version), 1L) &&
         all(vapply(identity[6:17], function(value) {
           grepl("^[0-9a-f]{64}$", as.character(value))
         }, logical(1))) &&
         grepl("^sha256:[0-9a-f]{64}$", as.character(identity$release_id)),
       "Synthetic identity has an invalid schema or digest field.")

pages_static_files <- c(
  "docs/.nojekyll",
  "docs/index.html",
  "docs/og-image-v2.png",
  "docs/assets/inverts-living-poster-v2-840.webp",
  "docs/assets/inverts-living-poster-v2.png",
  "docs/assets/inverts-living-poster-v2.webp"
)
pages_markdown_files <- c(
  "docs/DATA-TAKEAWAYS.md", "docs/IMAGE-PROVENANCE.md",
  "docs/data-bundling-pattern.md", "docs/neonize-playbook.md"
)
expected_pages_paths <- sort(
  c(pages_static_files, pages_markdown_files), method = "radix"
)
expected_pages_entries <- paste(
  expected_pages_paths,
  vapply(file.path(root_a, expected_pages_paths), sha256_file, character(1)),
  sep = "\t"
)
expected_pages_sha256 <- unname(digest::digest(
  paste(
    "neon-inverts-pages-payload-v2",
    paste0(paste(expected_pages_entries, collapse = "\n"), "\n"),
    sep = "\n"
  ),
  algo = "sha256", serialize = FALSE
))
assert(identical(
  as.character(identity$pages_payload_sha256), expected_pages_sha256
), paste(
  "Pages identity does not bind the exact static allowlist and every",
  "non-handoff root Markdown file under the v2 domain."
))

# Write mode must accept its previously generated receipt and reproduce the
# exact identity; this is the normal shape of a release-candidate rebuild.
run_writer(root_a, "write", expect_success = TRUE)
assert(identical(
  identity_a, read_bytes(file.path(root_a, "release", "production-identity.json"))
), "Write mode changed identity when its prior Pages receipt was present.")

identity_material <- c(
  "neon-my-little-inverts-production-instance-v1",
  as.character(unlist(identity[2:17], use.names = FALSE))
)
expected_id <- paste0("sha256:", digest::digest(
  paste(identity_material, collapse = "\n"),
  algo = "sha256", serialize = FALSE
))
assert(identical(as.character(identity$release_id), expected_id),
       "Release ID does not independently re-derive from the identity fields.")

write_extra_markdown_root <- file.path(
  fixture_parent, "write-extra-root-markdown"
)
make_fixture(write_extra_markdown_root)
write_bytes(
  file.path(write_extra_markdown_root, "docs", "EXPERT-REVIEW.md"),
  charToRaw("fixture expert review\n")
)
run_writer(write_extra_markdown_root, "write", expect_success = TRUE)
write_extra_identity <- jsonlite::fromJSON(
  file.path(write_extra_markdown_root, "release", "production-identity.json"),
  simplifyVector = FALSE
)
assert(!identical(
  as.character(write_extra_identity$pages_payload_sha256),
  as.character(identity$pages_payload_sha256)
), "Write mode did not identity-bind an added root docs/*.md file.")

write_missing_handoff_root <- file.path(
  fixture_parent, "write-missing-handoff"
)
make_fixture(write_missing_handoff_root)
unlink(file.path(
  write_missing_handoff_root, "docs", "BUILD-TEST-HANDOFF.md"
))
write_missing_handoff_output <- run_writer(
  write_missing_handoff_root, "write", expect_success = FALSE
)
assert(any(grepl(
  "lacks the exact build/test handoff", write_missing_handoff_output,
  fixed = TRUE
)), "Write mode accepted a missing exact build/test handoff path.")

write_missing_static_root <- file.path(
  fixture_parent, "write-missing-static"
)
make_fixture(write_missing_static_root)
unlink(file.path(write_missing_static_root, "docs", "og-image-v2.png"))
write_missing_static_output <- run_writer(
  write_missing_static_root, "write", expect_success = FALSE
)
assert(any(grepl(
  "Pages payload inventory is not exact", write_missing_static_output,
  fixed = TRUE
)), "Write mode accepted an incomplete static Pages allowlist.")

write_unknown_non_document_root <- file.path(
  fixture_parent, "write-unknown-non-document"
)
make_fixture(write_unknown_non_document_root)
write_bytes(
  file.path(write_unknown_non_document_root, "docs", "notes.txt"),
  charToRaw("unreviewed Pages file\n")
)
write_unknown_non_document_output <- run_writer(
  write_unknown_non_document_root, "write", expect_success = FALSE
)
assert(any(grepl(
  "Pages payload inventory is not exact", write_unknown_non_document_output,
  fixed = TRUE
)), "Write mode accepted a non-allowlisted Pages file.")

write_nested_markdown_root <- file.path(
  fixture_parent, "write-nested-markdown"
)
make_fixture(write_nested_markdown_root)
write_bytes(
  file.path(write_nested_markdown_root, "docs", "nested", "REVIEW.md"),
  charToRaw("nested unreviewed document\n")
)
write_nested_markdown_output <- run_writer(
  write_nested_markdown_root, "write", expect_success = FALSE
)
assert(any(grepl(
  "Pages payload inventory is not exact", write_nested_markdown_output,
  fixed = TRUE
)), "Write mode accepted Markdown outside root docs/*.md.")

invalid_lineage_root <- file.path(fixture_parent, "invalid-lineage")
make_fixture(invalid_lineage_root)
invalid_contract_path <- file.path(
  invalid_lineage_root, "data", "release_contract.rds"
)
invalid_contract <- readRDS(invalid_contract_path)
invalid_contract$source$producer_git_sha <- toupper(fixture_git_sha)
saveRDS(invalid_contract, invalid_contract_path, version = 3)
invalid_lineage_output <- run_writer(
  invalid_lineage_root, "write", expect_success = FALSE
)
assert(any(grepl("source identity is invalid", invalid_lineage_output,
                 fixed = TRUE)),
       "Identity writer accepted a non-lowercase producer Git SHA.")

mismatched_lineage_root <- file.path(fixture_parent, "mismatched-lineage")
make_fixture(mismatched_lineage_root)
mismatched_contract_path <- file.path(
  mismatched_lineage_root, "data", "release_contract.rds"
)
mismatched_contract <- readRDS(mismatched_contract_path)
mismatched_contract$source$producer_git_sha <-
  paste(rep("f", 40L), collapse = "")
saveRDS(mismatched_contract, mismatched_contract_path, version = 3)
mismatched_lineage_output <- run_writer(
  mismatched_lineage_root, "write", expect_success = FALSE
)
assert(any(grepl("source receipt differs", mismatched_lineage_output,
                 fixed = TRUE)),
       "Identity writer accepted receipt/contract producer-SHA drift.")

source_drift_mutators <- list(
  package = function(source) {
    source$package <- "expanded"
    source
  },
  citation_identity = function(source) {
    source$citation_object <- "citation_20120_RELEASE-2025"
    source$citation_sha256 <- paste(rep("f", 64L), collapse = "")
    source
  },
  runtime = function(source) {
    source$producer_r_version <- "4.5.3"
    source$neonUtilities_version <- "4.0.2"
    source$neonUtilities_source <- paste0(source$neonUtilities_source, "?drift")
    source
  },
  fetched_time = function(source) {
    source$fetched_at_utc <- "2026-07-15T12:00:01Z"
    source
  },
  artifact_bytes = function(source) {
    source$artifact_bytes <- as.numeric(source$artifact_bytes) + 1
    source
  },
  table_inventory = function(source) {
    source$table_rows[["inv_fieldData"]] <-
      as.integer(source$table_rows[["inv_fieldData"]]) + 1L
    source
  }
)
for (label in names(source_drift_mutators)) {
  drift_root <- file.path(fixture_parent, paste0("source-drift-", label))
  make_fixture(drift_root)
  drift_contract_path <- file.path(drift_root, "data", "release_contract.rds")
  drift_contract <- readRDS(drift_contract_path)
  drift_contract$source <- source_drift_mutators[[label]](
    drift_contract$source
  )
  saveRDS(drift_contract, drift_contract_path, version = 3)
  drift_output <- run_writer(drift_root, "write", expect_success = FALSE)
  assert(any(grepl(
    "Published source receipt differs", drift_output, fixed = TRUE
  )), paste("Identity writer accepted receipt/contract", label, "drift."))
}

bad_citation_root <- file.path(fixture_parent, "bad-receipt-citation-hash")
make_fixture(bad_citation_root)
bad_citation_receipt_path <- file.path(
  bad_citation_root, "data", "source_receipt.json"
)
bad_citation_receipt <- jsonlite::fromJSON(
  bad_citation_receipt_path, simplifyVector = TRUE,
  simplifyDataFrame = FALSE, simplifyMatrix = FALSE
)
bad_citation_receipt$citation$text <- paste0(
  bad_citation_receipt$citation$text, " coordinated citation drift"
)
write_bytes(bad_citation_receipt_path, charToRaw(paste0(jsonlite::toJSON(
  bad_citation_receipt, auto_unbox = TRUE, pretty = TRUE, null = "null"
), "\n")))
bad_citation_contract_path <- file.path(
  bad_citation_root, "data", "release_contract.rds"
)
bad_citation_contract <- readRDS(bad_citation_contract_path)
bad_citation_contract$source$receipt_sha256 <-
  sha256_file(bad_citation_receipt_path)
saveRDS(bad_citation_contract, bad_citation_contract_path, version = 3)
bad_citation_output <- run_writer(
  bad_citation_root, "write", expect_success = FALSE
)
assert(any(grepl(
  "source receipt authority is invalid", bad_citation_output,
  fixed = TRUE
)), "Identity writer accepted a receipt citation whose text hash is stale.")

bad_relation_root <- file.path(fixture_parent, "bad-receipt-relation")
make_fixture(bad_relation_root)
bad_relation_receipt_path <- file.path(
  bad_relation_root, "data", "source_receipt.json"
)
bad_relation_receipt <- jsonlite::fromJSON(
  bad_relation_receipt_path, simplifyVector = TRUE,
  simplifyDataFrame = FALSE, simplifyMatrix = FALSE
)
bad_relation_receipt$relations$practical_field_rows <-
  as.integer(bad_relation_receipt$relations$practical_field_rows) + 1L
write_bytes(bad_relation_receipt_path, charToRaw(paste0(jsonlite::toJSON(
  bad_relation_receipt, auto_unbox = TRUE, pretty = TRUE, null = "null"
), "\n")))
bad_relation_contract_path <- file.path(
  bad_relation_root, "data", "release_contract.rds"
)
bad_relation_contract <- readRDS(bad_relation_contract_path)
bad_relation_contract$source$receipt_sha256 <-
  sha256_file(bad_relation_receipt_path)
saveRDS(bad_relation_contract, bad_relation_contract_path, version = 3)
bad_relation_manifest_path <- file.path(bad_relation_root, "manifest.json")
bad_relation_manifest <- jsonlite::fromJSON(
  bad_relation_manifest_path, simplifyVector = FALSE
)
for (relative in c(
  "data/source_receipt.json", "data/release_contract.rds"
)) {
  bad_relation_manifest$files[[relative]]$checksum <-
    unname(tools::md5sum(file.path(bad_relation_root, relative)))
}
write_manifest(bad_relation_root, bad_relation_manifest)
bad_relation_output <- run_writer(
  bad_relation_root, "write", expect_success = FALSE
)
assert(any(grepl(
  "source receipt relation authority is invalid", bad_relation_output,
  fixed = TRUE
)), paste(
  "Identity writer accepted coordinated relation-value, receipt-hash,",
  "contract-hash, and manifest-checksum tampering."
))

# The final Connect manifest adds only the excluded identity file to its file
# map; the canonical manifest contract and payload source list remain cycle-free.
manifest_path <- file.path(root_a, "manifest.json")
manifest <- jsonlite::fromJSON(manifest_path, simplifyVector = FALSE)
manifest$files[["release/production-identity.json"]] <-
  list(checksum = unname(tools::md5sum(file.path(
    root_a, "release", "production-identity.json"
  ))))
write_manifest(root_a, manifest)
final_manifest <- read_bytes(manifest_path)
run_writer(root_a, "verify", expect_success = TRUE)

handoff_path <- file.path(root_a, "docs", "BUILD-TEST-HANDOFF.md")
handoff_original <- read_bytes(handoff_path)
write_bytes(handoff_path, c(
  handoff_original, charToRaw("mutable session closeout\n")
))
run_writer(root_a, "verify", expect_success = TRUE)
assert(identical(
  identity_a, read_bytes(file.path(root_a, "release", "production-identity.json"))
), "Exact handoff byte changes unexpectedly changed production identity.")
write_bytes(handoff_path, handoff_original)

unlink(handoff_path)
missing_handoff_output <- run_writer(
  root_a, "verify", expect_success = FALSE
)
assert(any(grepl(
  "lacks the exact build/test handoff", missing_handoff_output, fixed = TRUE
)), "Verify mode accepted a missing exact handoff path.")
write_bytes(handoff_path, handoff_original)
run_writer(root_a, "verify", expect_success = TRUE)

extra_markdown_path <- file.path(root_a, "docs", "EXPERT-REVIEW.md")
write_bytes(extra_markdown_path, charToRaw("new expert review\n"))
run_writer(root_a, "verify", expect_success = FALSE)
unlink(extra_markdown_path)
run_writer(root_a, "verify", expect_success = TRUE)

handoff_lookalike_path <- file.path(
  root_a, "docs", "BUILD-TEST-HANDOFF-copy.md"
)
write_bytes(handoff_lookalike_path, charToRaw("not the exact handoff\n"))
run_writer(root_a, "verify", expect_success = FALSE)
unlink(handoff_lookalike_path)
run_writer(root_a, "verify", expect_success = TRUE)

unknown_non_document_path <- file.path(root_a, "docs", "notes.txt")
write_bytes(unknown_non_document_path, charToRaw("unreviewed Pages file\n"))
unknown_non_document_output <- run_writer(
  root_a, "verify", expect_success = FALSE
)
assert(any(grepl(
  "Pages payload inventory is not exact", unknown_non_document_output,
  fixed = TRUE
)), "Verify mode accepted a non-allowlisted Pages file.")
unlink(unknown_non_document_path)
run_writer(root_a, "verify", expect_success = TRUE)

hidden_non_document_path <- file.path(root_a, "docs", ".unreviewed")
write_bytes(hidden_non_document_path, charToRaw("hidden Pages file\n"))
hidden_non_document_output <- run_writer(
  root_a, "verify", expect_success = FALSE
)
assert(any(grepl(
  "Pages payload inventory is not exact", hidden_non_document_output,
  fixed = TRUE
)), "Verify mode ignored a hidden non-allowlisted Pages file.")
unlink(hidden_non_document_path)
run_writer(root_a, "verify", expect_success = TRUE)

nested_markdown_path <- file.path(root_a, "docs", "nested", "REVIEW.md")
write_bytes(nested_markdown_path, charToRaw("nested unreviewed document\n"))
nested_markdown_output <- run_writer(
  root_a, "verify", expect_success = FALSE
)
assert(any(grepl(
  "Pages payload inventory is not exact", nested_markdown_output,
  fixed = TRUE
)), "Verify mode accepted Markdown outside root docs/*.md.")
unlink(nested_markdown_path)
unlink(dirname(nested_markdown_path), recursive = TRUE)
run_writer(root_a, "verify", expect_success = TRUE)

static_path <- file.path(root_a, "docs", "og-image-v2.png")
static_original <- read_bytes(static_path)
unlink(static_path)
missing_static_output <- run_writer(root_a, "verify", expect_success = FALSE)
assert(any(grepl(
  "Pages payload inventory is not exact", missing_static_output, fixed = TRUE
)), "Verify mode accepted an incomplete static Pages allowlist.")
write_bytes(static_path, static_original)
run_writer(root_a, "verify", expect_success = TRUE)

pages_receipt_path <- file.path(root_a, "docs", "release.json")
pages_receipt_original <- read_bytes(pages_receipt_path)
unlink(pages_receipt_path)
missing_pages_receipt_output <- run_writer(
  root_a, "verify", expect_success = FALSE
)
assert(any(grepl(
  "lacks its generated release receipt", missing_pages_receipt_output,
  fixed = TRUE
)), "Verify mode accepted a missing generated Pages receipt.")
write_bytes(pages_receipt_path, pages_receipt_original)
run_writer(root_a, "verify", expect_success = TRUE)

outside_governance <- file.path(fixture_parent, "outside-governance.md")
write_bytes(outside_governance, charToRaw("outside governance bytes\n"))
linked_governance <- file.path(root_a, "docs", "LINKED-REVIEW.md")
assert(isTRUE(file.symlink(outside_governance, linked_governance)),
       "Could not create the linked Pages-document fixture.")
linked_governance_output <- run_writer(
  root_a, "verify", expect_success = FALSE
)
assert(any(grepl(
  "release enumeration must not enter symbolic-link components",
  linked_governance_output, fixed = TRUE
)), "Safe Pages enumeration accepted a linked root Markdown file.")
unlink(linked_governance)
run_writer(root_a, "verify", expect_success = TRUE)

outside_tree <- file.path(fixture_parent, "outside-tree")
write_bytes(
  file.path(outside_tree, "nested", "escaped.txt"),
  charToRaw("outside release root\n")
)
linked_tree <- file.path(root_a, "www", "linked-tree")
assert(isTRUE(file.symlink(outside_tree, linked_tree)),
       "Could not create the adversarial linked-directory fixture.")
legacy_recursive <- list.files(
  file.path(root_a, "www"), recursive = TRUE, full.names = FALSE
)
assert("linked-tree/nested/escaped.txt" %in% legacy_recursive,
       "Fixture did not prove recursive list.files follows linked directories.")
linked_tree_output <- run_writer(root_a, "verify", expect_success = FALSE)
assert(any(grepl(
  "release enumeration must not enter symbolic-link components",
  linked_tree_output, fixed = TRUE
)), "Safe release enumeration entered a linked directory.")
unlink(linked_tree)
run_writer(root_a, "verify", expect_success = TRUE)

empty_outside <- file.path(fixture_parent, "empty-outside")
dir.create(empty_outside)
hidden_link <- file.path(root_a, "www", ".hidden-empty-link")
assert(isTRUE(file.symlink(empty_outside, hidden_link)),
       "Could not create the hidden linked-directory fixture.")
hidden_link_output <- run_writer(root_a, "verify", expect_success = FALSE)
assert(any(grepl(
  "release enumeration must not enter symbolic-link components",
  hidden_link_output, fixed = TRUE
)), "Safe release enumeration ignored a hidden empty linked directory.")
unlink(hidden_link)
run_writer(root_a, "verify", expect_success = TRUE)

manifest_writer_lines <- readLines(manifest_writer, warn = FALSE)
safe_enumeration_line <- grep(
  'inv_list_release_files(".", "www")', manifest_writer_lines, fixed = TRUE
)
safe_output_line <- grep(
  'inv_prepare_safe_output(".", "manifest.json"', manifest_writer_lines,
  fixed = TRUE
)
write_manifest_line <- grep(
  "^[[:space:]]*rsconnect::writeManifest[(]", manifest_writer_lines
)
assert(length(safe_enumeration_line) == 1L &&
         length(safe_output_line) == 1L &&
         length(write_manifest_line) == 1L &&
         safe_enumeration_line < write_manifest_line &&
         safe_output_line < write_manifest_line,
       "Manifest writer does not guard enumeration/output before writing.")
path_safety_env <- new.env(parent = baseenv())
sys.source("scripts/release_path_safety.R", envir = path_safety_env)
manifest_guard_root <- file.path(fixture_parent, "manifest-output-guard")
dir.create(manifest_guard_root)
outside_manifest <- file.path(fixture_parent, "outside-manifest.json")
write_bytes(outside_manifest, charToRaw("outside manifest\n"))
assert(isTRUE(file.symlink(
  outside_manifest, file.path(manifest_guard_root, "manifest.json")
)), "Could not create the linked manifest-output fixture.")
manifest_guard_error <- tryCatch({
  path_safety_env$inv_prepare_safe_output(
    manifest_guard_root, "manifest.json", "Connect manifest output"
  )
  NA_character_
}, error = function(error) conditionMessage(error))
assert(!is.na(manifest_guard_error) &&
         grepl("output must not be a symbolic link", manifest_guard_error,
               fixed = TRUE),
       "Manifest output preflight accepted a linked manifest.json.")

tamper_file <- function(relative) {
  path <- file.path(root_a, relative)
  original <- read_bytes(path)
  write_bytes(path, c(original, charToRaw("tamper\n")))
  run_writer(root_a, "verify", expect_success = FALSE)
  write_bytes(path, original)
  run_writer(root_a, "verify", expect_success = TRUE)
}
for (relative in c(
  "global.R", "data/sites/ARIK.rds", "data/search_index.rds",
  "docs/assets/inverts-living-poster-v2.webp",
  "docs/IMAGE-PROVENANCE.md", "docs/.nojekyll"
)) tamper_file(relative)

manifest_value <- jsonlite::fromJSON(rawToChar(final_manifest), simplifyVector = FALSE)
manifest_value$files[["global.R"]]$checksum <- paste(rep("0", 32L), collapse = "")
write_manifest(root_a, manifest_value)
run_writer(root_a, "verify", expect_success = FALSE)
write_bytes(manifest_path, final_manifest)
run_writer(root_a, "verify", expect_success = TRUE)

manifest_value <- jsonlite::fromJSON(rawToChar(final_manifest), simplifyVector = FALSE)
manifest_value$packages$alpha$description$Version <- "1.0.1"
write_manifest(root_a, manifest_value)
run_writer(root_a, "verify", expect_success = FALSE)
write_bytes(manifest_path, final_manifest)
run_writer(root_a, "verify", expect_success = TRUE)

manifest_value <- jsonlite::fromJSON(rawToChar(final_manifest), simplifyVector = FALSE)
manifest_value$files$global.R <- NULL
write_manifest(root_a, manifest_value)
run_writer(root_a, "verify", expect_success = FALSE)
write_bytes(manifest_path, final_manifest)
run_writer(root_a, "verify", expect_success = TRUE)

pages_path <- file.path(root_a, "docs", "release.json")
pages_original <- read_bytes(pages_path)
outside_pages <- file.path(fixture_parent, "outside-release.json")
write_bytes(outside_pages, pages_original)
unlink(pages_path)
assert(isTRUE(file.symlink(outside_pages, pages_path)),
       "Could not create the linked Pages-receipt fixture.")
pages_link_output <- run_writer(root_a, "verify", expect_success = FALSE)
assert(any(grepl("symbolic-link components", pages_link_output, fixed = TRUE)),
       "Verify mode accepted a linked Pages release receipt.")
unlink(pages_path)
write_bytes(pages_path, pages_original)
run_writer(root_a, "verify", expect_success = TRUE)
write_bytes(pages_path, c(pages_original, charToRaw("tamper\n")))
run_writer(root_a, "verify", expect_success = FALSE)

cat(paste(
  "OK: production identity is deterministic and cycle-free; code, bundle,",
  "derived-index, Pages, manifest-contract, source-list, lineage, and symlink",
  "tampering are rejected.\n"
))
