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
receipt <- jsonlite::fromJSON(receipt_path, simplifyVector = FALSE)
if (!is.list(contract) ||
    !identical(scalar(contract$schema_version), "1.0.0") ||
    !identical(scalar(contract$producer_schema_version), "2.0.0") ||
    !identical(scalar(contract$bundle_schema_version), "2.0.0") ||
    !identical(as.character(contract$site_ids), EXPECTED_SITES)) {
  stop("Release contract is not the exact reviewed 34-site family.", call. = FALSE)
}

source <- contract$source
if (!is.list(source) ||
    !identical(scalar(source$dpid), PRODUCT) ||
    !identical(scalar(source$release), RELEASE) ||
    !identical(source$include_provisional, FALSE) ||
    !identical(scalar(source$receipt_schema_version), "1.1.0") ||
    !valid_git_sha(source$producer_git_sha) ||
    !valid_sha256(source$artifact_sha256) ||
    !valid_sha256(source$receipt_sha256)) {
  stop("Release contract source identity is invalid.", call. = FALSE)
}

source_receipt_sha256 <- sha256_file(receipt_path)
if (!identical(source_receipt_sha256, scalar(source$receipt_sha256)) ||
    !identical(scalar(receipt$receipt_schema_version), "1.1.0") ||
    !identical(scalar(receipt$source_request$dpid), PRODUCT) ||
    !identical(scalar(receipt$source_request$release), RELEASE) ||
    !identical(receipt$source_request$include_provisional, FALSE) ||
    !valid_git_sha(receipt$producer$git_sha) ||
    !identical(scalar(receipt$producer$git_sha),
               scalar(source$producer_git_sha)) ||
    !identical(scalar(receipt$release$tag), RELEASE) ||
    !identical(scalar(receipt$release$doi), DOI) ||
    !identical(scalar(receipt$artifact$sha256),
               scalar(source$artifact_sha256))) {
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
