#!/usr/bin/env Rscript

# Verify an immutable My Little Inverts Pass-9 refresh candidate. Scientific
# bundle verification is intentionally delegated to the independent,
# bundle-only verifier, which does not source the producer or science transform.

if (!requireNamespace("jsonlite", quietly = TRUE))
  stop("jsonlite is required to verify manifest.json", call. = FALSE)
if (!requireNamespace("digest", quietly = TRUE))
  stop("digest is required to verify release hashes", call. = FALSE)

source("scripts/inv_release_verifier.R", local = TRUE)

fail <- function(...) stop(sprintf(...), call. = FALSE)
assert <- function(ok, ...) if (!isTRUE(ok)) fail(...)

expected_sites <- INV_RELEASE_EXPECTED_SITES
release_summary <- inv_verify_release_data(".")
site_index <- readRDS("data/site_index.rds")

baseline_args <- commandArgs(trailingOnly = TRUE)
if (length(baseline_args) > 1L) fail("Usage: verify_refresh_candidate.R [baseline-site-index.rds]")
if (length(baseline_args) == 1L) {
  baseline <- readRDS(baseline_args[[1]])
  assert(is.data.frame(baseline) && "site" %in% names(baseline),
         "Baseline site index is invalid")
  baseline_sites <- unique(as.character(baseline$site))
  assert(all(baseline_sites %in% site_index$site),
         "Candidate dropped baseline site(s): %s",
         paste(setdiff(baseline_sites, site_index$site), collapse = ", "))
  # The first Pass-9 migration compares against a legacy taxonomy-first index,
  # whose samples/bouts are not the field opportunity denominator. Once a
  # Pass-9 baseline exists, guard its opportunity and collection-date coverage.
  comparable <- c("n_opportunities", "collectDate_min", "collectDate_max")
  if (all(comparable %in% names(baseline))) {
    old <- baseline[match(expected_sites, as.character(baseline$site)), , drop = FALSE]
    new <- site_index[match(expected_sites, as.character(site_index$site)), , drop = FALSE]
    assert(!anyNA(old$site) && !anyNA(new$site),
           "Baseline comparison could not align the canonical site roster")
    regressed <- expected_sites[as.integer(new$n_opportunities) <
                                  as.integer(old$n_opportunities)]
    assert(!length(regressed),
           "Candidate field opportunities shrank at site(s): %s",
           paste(regressed, collapse = ", "))
    old_min <- as.Date(old$collectDate_min)
    new_min <- as.Date(new$collectDate_min)
    old_max <- as.Date(old$collectDate_max)
    new_max <- as.Date(new$collectDate_max)
    assert(!anyNA(c(old_min, new_min, old_max, new_max)),
           "Collection-date coverage contains missing comparison values")
    assert(!any(new_min > old_min),
           "Candidate lost early collection history at site(s): %s",
           paste(expected_sites[new_min > old_min], collapse = ", "))
    assert(!any(new_max < old_max),
           "Candidate latest collection date regressed at site(s): %s",
           paste(expected_sites[new_max < old_max], collapse = ", "))
  }
}

manifest <- jsonlite::fromJSON("manifest.json", simplifyVector = FALSE)
assert("users" %in% names(manifest), "manifest.json is missing the canonical users key")
assert(is.list(manifest$packages) && "cpp11" %in% names(manifest$packages),
       "manifest.json is missing the required cpp11 package")
required_runtime <- c(
  "shiny", "bslib", "bsicons", "dplyr", "tibble", "tidyr", "stringr",
  "plotly", "leaflet", "DT", "shinyjs", "shinycssloaders", "RColorBrewer",
  "htmltools", "cpp11"
)
missing_runtime <- setdiff(required_runtime, names(manifest$packages))
assert(!length(missing_runtime), "manifest.json omits runtime package(s): %s",
       paste(missing_runtime, collapse = ", "))
leaks <- intersect(c("neonUtilities", "arrow"), names(manifest$packages))
assert(!length(leaks), "Heavy build package(s) leaked into manifest.json: %s",
       paste(leaks, collapse = ", "))
assert(is.list(manifest$files) && length(manifest$files) > 0L &&
         !is.null(names(manifest$files)) && all(nzchar(names(manifest$files))),
       "manifest.json has no named file inventory")

manifest_paths <- names(manifest$files)
release_paths <- c(
  "data/release_contract.rds", "data/source_receipt.json",
  "data/site_index.rds", "data/cross_site.rds", "data/search_index.rds",
  paste0("data/sites/", expected_sites, ".rds"), "data-sample/demo.rds"
)
missing_release <- setdiff(release_paths, manifest_paths)
assert(!length(missing_release), "manifest.json omits release file(s): %s",
       paste(missing_release, collapse = ", "))
missing_files <- manifest_paths[!file.exists(manifest_paths)]
assert(!length(missing_files), "manifest.json names missing file(s): %s",
       paste(missing_files, collapse = ", "))
manifest_data_paths <- manifest_paths[grepl("^(data|data-sample)/", manifest_paths)]
assert(identical(sort(manifest_data_paths), sort(release_paths)),
       "manifest.json data inventory differs from the exact release allowlist")

expected_md5 <- vapply(manifest$files, function(entry) {
  checksum <- entry$checksum
  if (is.null(checksum) || length(checksum) != 1L) "" else as.character(checksum)
}, character(1))
assert(all(grepl("^[0-9a-fA-F]{32}$", expected_md5)),
       "manifest.json contains a missing or malformed checksum")
actual_md5 <- unname(tools::md5sum(manifest_paths))
bad_md5 <- manifest_paths[tolower(actual_md5) != tolower(expected_md5)]
assert(!length(bad_md5), "Manifest checksum mismatch for: %s",
       paste(bad_md5, collapse = ", "))
manifest_text <- paste(readLines("manifest.json", warn = FALSE), collapse = "\n")
assert(!grepl("cloud[.]r-project[.]org|cran[.]rstudio[.]com|cran/(?:__linux__/jammy/)?latest",
              manifest_text, perl = TRUE),
       "manifest.json contains a moving package repository")
assert(grepl("packagemanager[.]posit[.]co/cran/__linux__/jammy/2026-07-15",
             manifest_text),
       "manifest.json does not carry the pinned 2026-07-15 package snapshot")

scalar <- function(x) if (is.null(x) || length(x) != 1L || is.na(x)) "" else as.character(x)
expected_platform <- "4.5.2"
expected_repository <- "https://packagemanager.posit.co/cran/__linux__/jammy/2026-07-15"
expected_geo_pins <- c(
  terra="1.8-50", sf="1.1-1", s2="1.1.11", units="1.0-1",
  wk="0.9.5", classInt="0.4-11", raster="3.6-32", sp="2.2-1")
expected_geo_urls <- c(
  terra="https://cran.r-project.org/src/contrib/Archive/terra/terra_1.8-50.tar.gz",
  sf="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/sf_1.1-1.tar.gz",
  s2="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/s2_1.1.11.tar.gz",
  units="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/units_1.0-1.tar.gz",
  wk="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/wk_0.9.5.tar.gz",
  classInt="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/classInt_0.4-11.tar.gz",
  raster="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/raster_3.6-32.tar.gz",
  sp="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/sp_2.2-1.tar.gz")
expected_snapshot_pins <- c(plotly="4.12.0")
expected_snapshot_urls <- c(
  plotly="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/plotly_4.12.0.tar.gz")

assert(identical(scalar(manifest$platform), expected_platform),
       "manifest platform is %s; expected %s", scalar(manifest$platform), expected_platform)
for (pkg in names(expected_geo_pins)) {
  rec <- manifest$packages[[pkg]]
  assert(!is.null(rec), "manifest lacks geospatial package %s", pkg)
  expected_ref <- paste0("url::", unname(expected_geo_urls[[pkg]]))
  assert(identical(scalar(rec$description$Version), unname(expected_geo_pins[[pkg]])) &&
           identical(scalar(rec$Source), "CRAN") &&
           identical(scalar(rec$Repository), "https://cran.r-project.org") &&
           identical(scalar(rec$description$RemoteType), "url") &&
           identical(scalar(rec$description$RemotePkgRef), expected_ref) &&
           !nzchar(scalar(rec$description$Built)),
         "manifest geospatial provenance is invalid for %s", pkg)
}
for (pkg in names(expected_snapshot_pins)) {
  rec <- manifest$packages[[pkg]]
  assert(!is.null(rec), "manifest lacks snapshot-source package %s", pkg)
  expected_ref <- paste0("url::", unname(expected_snapshot_urls[[pkg]]))
  assert(identical(scalar(rec$description$Version), unname(expected_snapshot_pins[[pkg]])) &&
           identical(scalar(rec$Source), "CRAN") &&
           identical(scalar(rec$Repository), expected_repository) &&
           identical(scalar(rec$description$RemoteType), "url") &&
           identical(scalar(rec$description$RemotePkgRef), expected_ref) &&
           !nzchar(scalar(rec$description$Built)),
         "manifest snapshot-source provenance is invalid for %s", pkg)
}
ordinary <- setdiff(names(manifest$packages),
                   c(names(expected_geo_pins), names(expected_snapshot_pins)))
bad_ordinary <- ordinary[vapply(ordinary, function(pkg) {
  rec <- manifest$packages[[pkg]]
  remote_type <- scalar(rec$description$RemoteType)
  remote_type_bad <- !remote_type %in% c("", "standard")
  standard_remote_bad <- identical(remote_type, "standard") &&
    !identical(scalar(rec$description$RemoteRepos), expected_repository)
  !identical(scalar(rec$Source), "CRAN") ||
    !identical(scalar(rec$Repository), expected_repository) ||
    remote_type_bad || standard_remote_bad
}, logical(1))]
assert(!length(bad_ordinary), "manifest ordinary-package provenance is invalid for: %s",
       paste(bad_ordinary, collapse = ", "))

cat(sprintf(
  paste0(
    "Candidate OK: %d exact sites, %d field opportunities, %d count-eligible, ",
    "%d density-eligible, %d unstratifiable, %d search rows, stamp %s, ",
    "%d manifest checksums.\n"
  ),
  release_summary$sites, release_summary$opportunities,
  release_summary$count_samples, release_summary$density_samples,
  release_summary$unstratifiable, release_summary$taxon_search_rows,
  paste(release_summary$source_stamp, collapse = ","), length(manifest_paths)
))
