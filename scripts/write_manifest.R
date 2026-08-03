# ===========================================================================
# write_manifest.R — (re)generate manifest.json for Posit Connect Cloud, then
# CHECK it. Connect Cloud reads the committed manifest, so a stale manifest
# restores the OLD package set; regenerate + commit after any dependency or data
# change.
#
#   Rscript scripts/write_manifest.R
#
# CONTRACT:
#   * Run rsconnect::writeManifest() to write the CANONICAL manifest.json
#     (rsconnect's own format — has the top-level "users" key + per-file
#     "checksum"). Parse with simplifyVector=FALSE so controlled canonicalization
#     preserves every users/file/checksum entry and exact URL string.
#   * Verify the complete retained source closure before changing deploy-lane
#     fields. Never fabricate a package version or rewrite moving provenance.
#   * Reject neonUtilities or arrow if they leak in (those would make the deploy
#     heavy / break it). neonUtilities is referenced by a computed name in
#     global.R, so the static scan should not pick it up.
#   * data.table is a LEGIT plotly dependency and MUST stay — do not flag it.
# ===========================================================================
if (!requireNamespace("rsconnect", quietly = TRUE)) stop("install.packages('rsconnect') first")
if (!requireNamespace("jsonlite",  quietly = TRUE)) stop("install.packages('jsonlite') first")

rsconnect::writeManifest(
  appDir = ".",                   # ui.R + server.R + global.R -> detected as a Shiny app
  appFiles = c(
    "global.R", "ui.R", "server.R",
    list.files("R", full.names = TRUE),
    list.files("www", full.names = TRUE),
    list.files("data", recursive = TRUE, full.names = TRUE),
    list.files("data-sample", full.names = TRUE)
  )
)

# Parse without simplifying nested manifest records.
m <- jsonlite::fromJSON("manifest.json", simplifyVector = FALSE)
pkgs <- names(m$packages)
cat(sprintf("manifest.json written: %d packages.\n", length(pkgs)))

has_users    <- "users" %in% names(m)
has_checksum <- length(m$files) > 0 && all(vapply(m$files, function(f) "checksum" %in% names(f), logical(1)))
cat(sprintf("canonical format: users key %s · per-file checksum %s\n",
            if (has_users) "present" else "MISSING", if (has_checksum) "present" else "MISSING"))

leak <- pkgs[grepl("neonUtilities|^arrow$", pkgs, ignore.case = TRUE)]
if (length(leak)) {
  stop(sprintf("Heavy package(s) leaked into the manifest: %s. Check the global.R computed-name guard / appFiles.", paste(leak, collapse = ", ")))
}
cat("Good: neonUtilities / arrow are NOT in the manifest (lean deploy).\n")
if ("data.table" %in% pkgs) cat("Note: data.table present (a legit plotly dependency — kept).\n")

R_PLATFORM_PIN <- "4.5.2"
RSPM_SNAPSHOT <- "https://packagemanager.posit.co/cran/__linux__/jammy/2026-07-15"
GEO_PINS <- c(
  terra="1.8-50", sf="1.1-1", s2="1.1.11", units="1.0-1",
  wk="0.9.5", classInt="0.4-11", raster="3.6-32", sp="2.2-1")
GEO_URLS <- c(
  terra="https://cran.r-project.org/src/contrib/Archive/terra/terra_1.8-50.tar.gz",
  sf="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/sf_1.1-1.tar.gz",
  s2="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/s2_1.1.11.tar.gz",
  units="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/units_1.0-1.tar.gz",
  wk="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/wk_0.9.5.tar.gz",
  classInt="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/classInt_0.4-11.tar.gz",
  raster="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/raster_3.6-32.tar.gz",
  sp="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/sp_2.2-1.tar.gz")
SNAPSHOT_SOURCE_PINS <- c(plotly="4.12.0")
SNAPSHOT_SOURCE_URLS <- c(
  plotly="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/plotly_4.12.0.tar.gz")

scalar <- function(x) if (is.null(x) || length(x) != 1L || is.na(x)) "" else as.character(x)
problems <- character(0)
if (!identical(scalar(m$platform), R_PLATFORM_PIN))
  problems <- c(problems, sprintf("platform=%s (want %s)", scalar(m$platform), R_PLATFORM_PIN))

for (pkg in names(GEO_PINS)) {
  rec <- m$packages[[pkg]]
  if (is.null(rec)) {
    problems <- c(problems, sprintf("%s=<missing>", pkg))
    next
  }
  expected_ref <- paste0("url::", unname(GEO_URLS[[pkg]]))
  if (!identical(scalar(rec$description$Version), unname(GEO_PINS[[pkg]])) ||
      !identical(scalar(rec$description$RemoteType), "url") ||
      !identical(scalar(rec$description$RemotePkgRef), expected_ref))
    problems <- c(problems, sprintf(
      "%s origin version=%s type=%s ref=%s (want %s from %s)",
      pkg, scalar(rec$description$Version), scalar(rec$description$RemoteType),
      scalar(rec$description$RemotePkgRef), unname(GEO_PINS[[pkg]]), expected_ref))
}
for (pkg in names(SNAPSHOT_SOURCE_PINS)) {
  rec <- m$packages[[pkg]]
  if (is.null(rec)) {
    problems <- c(problems, sprintf("%s=<missing>", pkg))
    next
  }
  expected_ref <- paste0("url::", unname(SNAPSHOT_SOURCE_URLS[[pkg]]))
  if (!identical(scalar(rec$description$Version), unname(SNAPSHOT_SOURCE_PINS[[pkg]])) ||
      !identical(scalar(rec$description$RemoteType), "url") ||
      !identical(scalar(rec$description$RemotePkgRef), expected_ref))
    problems <- c(problems, sprintf(
      "%s snapshot origin version=%s type=%s ref=%s (want %s from %s)",
      pkg, scalar(rec$description$Version), scalar(rec$description$RemoteType),
      scalar(rec$description$RemotePkgRef), unname(SNAPSHOT_SOURCE_PINS[[pkg]]), expected_ref))
}
for (pkg in setdiff(names(m$packages), c(names(GEO_PINS), names(SNAPSHOT_SOURCE_PINS)))) {
  rec <- m$packages[[pkg]]
  if (!identical(scalar(rec$Source), "CRAN") ||
      !identical(scalar(rec$Repository), RSPM_SNAPSHOT))
    problems <- c(problems, sprintf("%s deployment lane is %s/%s", pkg,
                                    scalar(rec$Source), scalar(rec$Repository)))
  if (identical(scalar(rec$description$RemoteType), "standard") &&
      !identical(scalar(rec$description$RemoteRepos), RSPM_SNAPSHOT))
    problems <- c(problems, sprintf("%s RemoteRepos=%s", pkg,
                                    scalar(rec$description$RemoteRepos)))
}
if (length(problems)) stop(sprintf(
  "MANIFEST PROVENANCE GATE FAILED: %s. Install exact retained sources; never rewrite versions after generation.",
  paste(problems, collapse = "; ")), call. = FALSE)

# Only after exact installed-origin proof, canonicalize the deployment fields
# Connect uses as network locations and remove non-semantic validator build clocks.
for (pkg in names(GEO_PINS)) {
  m$packages[[pkg]]$description$Built <- NULL
  m$packages[[pkg]]$Source <- "CRAN"
  m$packages[[pkg]]$Repository <- "https://cran.r-project.org"
}
for (pkg in names(SNAPSHOT_SOURCE_PINS)) {
  m$packages[[pkg]]$description$Built <- NULL
  m$packages[[pkg]]$Source <- "CRAN"
  m$packages[[pkg]]$Repository <- RSPM_SNAPSHOT
}
jsonlite::write_json(m, "manifest.json", auto_unbox = TRUE, pretty = TRUE, null = "null")

check <- jsonlite::fromJSON("manifest.json", simplifyVector = FALSE)
has_users <- "users" %in% names(check)
has_checksum <- length(check$files) > 0L &&
  all(vapply(check$files, function(f) "checksum" %in% names(f), logical(1)))
if (!has_users || !has_checksum)
  stop("manifest.json lost canonical users/checksum fields during controlled canonicalization.", call. = FALSE)
for (pkg in names(GEO_PINS)) {
  rec <- check$packages[[pkg]]
  expected_ref <- paste0("url::", unname(GEO_URLS[[pkg]]))
  if (!identical(scalar(rec$Source), "CRAN") ||
      !identical(scalar(rec$Repository), "https://cran.r-project.org") ||
      !identical(scalar(rec$description$RemotePkgRef), expected_ref) ||
      nzchar(scalar(rec$description$Built)))
    stop(sprintf("Post-canonicalization geospatial gate failed for %s.", pkg), call. = FALSE)
}
cat("Manifest OK: canonical fields preserved and exact retained package provenance verified.\n")
