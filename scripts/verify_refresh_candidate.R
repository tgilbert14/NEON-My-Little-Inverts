#!/usr/bin/env Rscript

# Verify a My Little Inverts refresh candidate using only base R + jsonlite.
# Optional argument: path to the committed baseline site_index.rds. When given,
# the candidate must retain every baseline site as well as the canonical roster.

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("jsonlite is required to verify manifest.json", call. = FALSE)
}

fail <- function(...) stop(sprintf(...), call. = FALSE)
assert <- function(ok, ...) if (!isTRUE(ok)) fail(...)

expected_sites <- c(
  "ARIK", "BARC", "BIGC", "BLDE", "BLUE", "BLWA", "CARI", "COMO",
  "CRAM", "CUPE", "FLNT", "GUIL", "HOPB", "KING", "LECO", "LEWI",
  "LIRO", "MART", "MAYF", "MCDI", "MCRA", "OKSR", "POSE", "PRIN",
  "PRLA", "PRPO", "REDB", "SUGG", "SYCA", "TECR", "TOMB", "TOOK",
  "WALK", "WLOU"
)

site_files <- sort(list.files("data/sites", pattern = "^[A-Z0-9]{4}[.]rds$", full.names = TRUE))
site_ids <- sub("[.]rds$", "", basename(site_files))
assert(identical(site_ids, expected_sites),
       "Site bundle roster differs from the canonical 34-site roster: got [%s]",
       paste(site_ids, collapse = ", "))

site_index <- readRDS("data/site_index.rds")
cross_site <- readRDS("data/cross_site.rds")
assert(is.data.frame(site_index), "data/site_index.rds is not a data frame")
assert(is.data.frame(cross_site), "data/cross_site.rds is not a data frame")
assert(!anyNA(site_index$site) && !anyDuplicated(site_index$site),
       "site_index has missing or duplicate site IDs")
assert(identical(sort(as.character(site_index$site)), expected_sites),
       "site_index does not contain the exact canonical 34-site roster")
assert(identical(site_index, cross_site),
       "cross_site.rds must be the exact site_index.rds table")

baseline_args <- commandArgs(trailingOnly = TRUE)
if (length(baseline_args) > 1L) fail("Usage: verify_refresh_candidate.R [baseline-site-index.rds]")
if (length(baseline_args) == 1L) {
  baseline <- readRDS(baseline_args[[1]])
  baseline_fields <- c("site", "n_bouts", "n_samples", "year_min", "year_max")
  assert(is.data.frame(baseline) && all(baseline_fields %in% names(baseline)),
         "Baseline site index is invalid")
  assert(all(baseline_fields %in% names(site_index)),
         "Candidate site index lacks fields required for baseline comparison")
  baseline_sites <- unique(as.character(baseline$site))
  assert(nrow(site_index) >= nrow(baseline),
         "Candidate site roster shrank from %d to %d rows", nrow(baseline), nrow(site_index))
  assert(all(baseline_sites %in% site_index$site),
         "Candidate dropped baseline site(s): %s",
         paste(setdiff(baseline_sites, site_index$site), collapse = ", "))

  baseline_cmp <- baseline[match(expected_sites, as.character(baseline$site)), baseline_fields]
  candidate_cmp <- site_index[match(expected_sites, as.character(site_index$site)), baseline_fields]
  assert(!anyNA(baseline_cmp$site) && !anyNA(candidate_cmp$site),
         "Baseline comparison could not align the canonical site roster")
  for (field in c("n_bouts", "n_samples")) {
    old <- suppressWarnings(as.numeric(baseline_cmp[[field]]))
    new <- suppressWarnings(as.numeric(candidate_cmp[[field]]))
    assert(!anyNA(old) && !anyNA(new), "%s contains missing baseline-comparison values", field)
    regressed <- expected_sites[new < old]
    assert(!length(regressed),
           "Candidate %s shrank at site(s): %s",
           field, paste(regressed, collapse = ", "))
  }
  old_min <- suppressWarnings(as.integer(baseline_cmp$year_min))
  new_min <- suppressWarnings(as.integer(candidate_cmp$year_min))
  old_max <- suppressWarnings(as.integer(baseline_cmp$year_max))
  new_max <- suppressWarnings(as.integer(candidate_cmp$year_max))
  assert(!anyNA(c(old_min, new_min, old_max, new_max)),
         "Year coverage contains missing baseline-comparison values")
  lost_early_history <- expected_sites[new_min > old_min]
  regressed_latest <- expected_sites[new_max < old_max]
  assert(!length(lost_early_history),
         "Candidate lost early-year history at site(s): %s",
         paste(lost_early_history, collapse = ", "))
  assert(!length(regressed_latest),
         "Candidate latest year regressed at site(s): %s",
         paste(regressed_latest, collapse = ", "))
}

bundle_stamps <- character(length(site_files))
names(bundle_stamps) <- site_ids
for (i in seq_along(site_files)) {
  bundle <- readRDS(site_files[[i]])
  assert(is.list(bundle) && all(c("samples", "bouts", "taxa", "meta") %in% names(bundle)),
         "%s is not a complete site bundle", basename(site_files[[i]]))
  assert(is.data.frame(bundle$samples) && nrow(bundle$samples) > 0L,
         "%s has no sample rows", basename(site_files[[i]]))
  assert(is.data.frame(bundle$bouts) && nrow(bundle$bouts) > 0L,
         "%s has no bout rows", basename(site_files[[i]]))
  assert(is.data.frame(bundle$taxa) && nrow(bundle$taxa) > 0L,
         "%s has no taxon rows", basename(site_files[[i]]))
  assert(identical(as.character(bundle$meta$site), site_ids[[i]]),
         "%s carries meta$site=%s", basename(site_files[[i]]), as.character(bundle$meta$site))
  assert(identical(as.integer(bundle$meta$n_samples), as.integer(nrow(bundle$samples))),
         "%s meta$n_samples does not match its sample table", basename(site_files[[i]]))
  assert(identical(as.integer(bundle$meta$n_bouts), as.integer(nrow(bundle$bouts))),
         "%s meta$n_bouts does not match its bout table", basename(site_files[[i]]))
  stamp <- as.character(bundle$meta$built)[1]
  assert(!is.na(stamp) && grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", stamp),
         "%s has an invalid meta$built stamp", basename(site_files[[i]]))
  bundle_stamps[[i]] <- stamp
}

search_index <- readRDS("data/search_index.rds")
assert(is.list(search_index) && all(c("taxa", "sites", "built") %in% names(search_index)),
       "data/search_index.rds is incomplete")
assert(is.data.frame(search_index$taxa) && nrow(search_index$taxa) > 0L,
       "Search index has no taxon occurrences")
assert(is.data.frame(search_index$sites), "Search index site table is invalid")
assert(identical(sort(unique(as.character(search_index$taxa$site))), expected_sites),
       "Search taxon occurrences do not span the canonical roster")
assert(identical(sort(as.character(search_index$sites$site)), expected_sites),
       "Search site table does not contain the canonical roster")
expected_stamp <- format(max(as.Date(bundle_stamps, format = "%Y-%m-%d")), "%Y-%m-%d")
assert(identical(as.character(search_index$built), expected_stamp),
       "Search index built stamp %s does not match deterministic bundle stamp %s",
       as.character(search_index$built), expected_stamp)

demo <- readRDS("data-sample/demo.rds")
assert(is.list(demo) && identical(as.character(demo$meta$site), "SYCA"),
       "Demo bundle must be the canonical SYCA bundle")
assert(identical(demo, readRDS("data/sites/SYCA.rds")),
       "Demo bundle bytes decode to content other than data/sites/SYCA.rds")

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
  "Candidate OK: %d exact sites, %d bouts, %d samples, %d search rows, stamp %s, %d manifest checksums.\n",
  nrow(site_index), sum(site_index$n_bouts), sum(site_index$n_samples),
  nrow(search_index$taxa), expected_stamp, length(manifest_paths)
))
