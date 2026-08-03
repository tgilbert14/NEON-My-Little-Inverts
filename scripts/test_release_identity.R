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
    "docs/IMAGE-PROVENANCE.md" = "fixture image provenance\n",
    "docs/assets/poster.webp" = "fixture Pages poster\n"
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
  receipt <- list(
    receipt_schema_version = "1.1.0",
    source_request = list(
      dpid = "DP1.20120.001", release = "RELEASE-2026",
      include_provisional = FALSE
    ),
    release = list(tag = "RELEASE-2026", doi = "10.48443/hp56-s582"),
    producer = list(git_sha = fixture_git_sha),
    artifact = list(sha256 = artifact_sha256)
  )
  receipt_path <- file.path(root, "data", "source_receipt.json")
  write_bytes(receipt_path, charToRaw(paste0(jsonlite::toJSON(
    receipt, auto_unbox = TRUE, pretty = TRUE, null = "null"
  ), "\n")))

  bundle_hashes <- vapply(
    file.path(root, bundle_paths), sha256_file, character(1)
  )
  names(bundle_hashes) <- sites
  contract <- list(
    schema_version = "1.0.0", producer_schema_version = "2.0.0",
    bundle_schema_version = "2.0.0", science_version = "fixture",
    source = list(
      dpid = "DP1.20120.001", release = "RELEASE-2026",
      include_provisional = FALSE, publication_date_max = "2026-01-01",
      receipt_schema_version = "1.1.0",
      producer_git_sha = fixture_git_sha,
      artifact_sha256 = artifact_sha256,
      receipt_sha256 = sha256_file(receipt_path)
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
assert(identical(identity_a, identity_b),
       "Production identity depends on object or file creation order.")
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
  "docs/assets/poster.webp", "docs/IMAGE-PROVENANCE.md", "docs/.nojekyll"
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
