# ===========================================================================
# write_manifest.R — (re)generate manifest.json for Posit Connect Cloud, then
# CHECK it. Connect Cloud reads the committed manifest, so a stale manifest
# restores the OLD package set; regenerate + commit after any dependency or data
# change.
#
#   INV_MANIFEST_PHASE=prestamp Rscript scripts/write_manifest.R
#   INV_RELEASE_IDENTITY_MODE=write INV_WRITE_PAGES_RELEASE=1 \
#     Rscript scripts/write_release_identity.R
#   INV_MANIFEST_PHASE=final Rscript scripts/write_manifest.R
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
source("scripts/release_path_safety.R", local = TRUE)
if (!requireNamespace("rsconnect", quietly = TRUE)) stop("install.packages('rsconnect') first")
if (!requireNamespace("jsonlite",  quietly = TRUE)) stop("install.packages('jsonlite') first")

MANIFEST_PHASE <- tolower(trimws(Sys.getenv("INV_MANIFEST_PHASE", "final")))
if (!MANIFEST_PHASE %in% c("prestamp", "final")) {
  stop("INV_MANIFEST_PHASE must be 'prestamp' or 'final'.", call. = FALSE)
}
PRODUCTION_IDENTITY <- "release/production-identity.json"
DEPLOYED_R_HELPERS <- c(
  "R/inv_helpers.R", "R/report_pdf.R", "R/site_metadata.R"
)
if (identical(MANIFEST_PHASE, "final") &&
    (!file.exists(PRODUCTION_IDENTITY) ||
     is.na(file.info(PRODUCTION_IDENTITY)$size) ||
     file.info(PRODUCTION_IDENTITY)$size <= 0)) {
  stop("Final manifest requires release/production-identity.json.", call. = FALSE)
}
missing_helpers <- DEPLOYED_R_HELPERS[!file.exists(DEPLOYED_R_HELPERS)]
if (length(missing_helpers)) {
  stop("Deploy helper allowlist is incomplete: ",
       paste(missing_helpers, collapse = ", "), call. = FALSE)
}

app_files <- c(
  "global.R", "ui.R", "server.R",
  DEPLOYED_R_HELPERS,
  inv_list_release_files(".", "www"),
  inv_list_release_files(".", "data"),
  inv_list_release_files(".", "data-sample"),
  if (identical(MANIFEST_PHASE, "final")) PRODUCTION_IDENTITY else character()
)
app_files <- sort(unique(app_files[
  file.exists(app_files) & !dir.exists(app_files)
]))
app_files <- gsub("\\\\", "/", app_files)
inv_assert_safe_relative_paths(
  ".", app_files, "Connect appFiles", expected = "file"
)
inv_prepare_safe_output(".", "manifest.json", "Connect manifest output")

rsconnect::writeManifest(
  appDir = ".",                   # ui.R + server.R + global.R -> detected as a Shiny app
  appFiles = app_files
)

# Parse without simplifying nested manifest records.
m <- jsonlite::fromJSON("manifest.json", simplifyVector = FALSE)
pkgs <- names(m$packages)
cat(sprintf("%s manifest.json written: %d packages.\n",
            MANIFEST_PHASE, length(pkgs)))

has_users    <- "users" %in% names(m)
has_checksum <- length(m$files) > 0 && all(vapply(m$files, function(f) "checksum" %in% names(f), logical(1)))
manifest_paths <- gsub("\\\\", "/", names(m$files))
inv_assert_safe_relative_paths(
  ".", manifest_paths, "generated Connect manifest", expected = "file"
)
if (!identical(sort(manifest_paths, method = "radix"),
               sort(app_files, method = "radix"))) {
  stop("Generated Connect manifest differs from the safe appFiles closure.",
       call. = FALSE)
}
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
RSCONNECT_CRAN_ALIAS <- "https://cloud.r-project.org"
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
# Explicit dated sources cannot be superseded by setup-r-dependencies' moving
# CRAN fallback. Their exact URL identity is retained alongside the version.
SNAPSHOT_SOURCE_PINS <- c(bslib="0.11.0", plotly="4.12.0")
SNAPSHOT_SOURCE_URLS <- c(
  bslib="https://packagemanager.posit.co/cran/2026-07-15/src/contrib/bslib_0.11.0.tar.gz",
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
ordinary <- setdiff(names(m$packages), c(names(GEO_PINS), names(SNAPSHOT_SOURCE_PINS)))
ordinary_alias_seen <- FALSE
for (pkg in ordinary) {
  rec <- m$packages[[pkg]]
  repository <- scalar(rec$Repository)
  remote_type <- scalar(rec$description$RemoteType)
  remote_repos <- scalar(rec$description$RemoteRepos)
  if (!identical(scalar(rec$Source), "CRAN") ||
      !repository %in% c(RSPM_SNAPSHOT, RSCONNECT_CRAN_ALIAS))
    problems <- c(problems, sprintf("%s deployment lane is %s/%s", pkg,
                                    scalar(rec$Source), scalar(rec$Repository)))
  if (!remote_type %in% c("", "standard"))
    problems <- c(problems, sprintf("%s RemoteType=%s", pkg, remote_type))
  if (identical(remote_type, "standard") &&
      !remote_repos %in% c(RSPM_SNAPSHOT, RSCONNECT_CRAN_ALIAS))
    problems <- c(problems, sprintf("%s RemoteRepos=%s", pkg,
                                    remote_repos))
  ordinary_alias_seen <- ordinary_alias_seen ||
    identical(repository, RSCONNECT_CRAN_ALIAS) ||
    identical(remote_repos, RSCONNECT_CRAN_ALIAS)
}
if (ordinary_alias_seen &&
    (!identical(Sys.getenv("RSPM"), RSPM_SNAPSHOT) ||
     !identical(Sys.getenv("RENV_CONFIG_REPOS_OVERRIDE"), RSPM_SNAPSHOT)))
  problems <- c(problems, paste0(
    "rsconnect emitted its cloud.r-project.org ordinary-CRAN alias outside the ",
    "workflow's exact RSPM/RENV snapshot environment"))
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
for (pkg in ordinary) {
  m$packages[[pkg]]$Source <- "CRAN"
  m$packages[[pkg]]$Repository <- RSPM_SNAPSHOT
  if (identical(scalar(m$packages[[pkg]]$description$RemoteType), "standard"))
    m$packages[[pkg]]$description$RemoteRepos <- RSPM_SNAPSHOT
}
jsonlite::write_json(m, "manifest.json", auto_unbox = TRUE, pretty = TRUE, null = "null")

check <- jsonlite::fromJSON("manifest.json", simplifyVector = FALSE)
has_users <- "users" %in% names(check)
has_checksum <- length(check$files) > 0L &&
  all(vapply(check$files, function(f) "checksum" %in% names(f), logical(1)))
inv_assert_safe_relative_paths(
  ".", gsub("\\\\", "/", names(check$files)),
  "canonical Connect manifest", expected = "file"
)
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
for (pkg in ordinary) {
  rec <- check$packages[[pkg]]
  standard_remote_bad <- identical(scalar(rec$description$RemoteType), "standard") &&
    !identical(scalar(rec$description$RemoteRepos), RSPM_SNAPSHOT)
  if (!identical(scalar(rec$Source), "CRAN") ||
      !identical(scalar(rec$Repository), RSPM_SNAPSHOT) || standard_remote_bad)
    stop(sprintf("Post-canonicalization ordinary-package gate failed for %s.", pkg),
         call. = FALSE)
}
canonical_text <- paste(readLines("manifest.json", warn = FALSE), collapse = "\n")
if (grepl("cloud[.]r-project[.]org|cran[.]rstudio[.]com|cran/(?:__linux__/jammy/)?latest",
          canonical_text, perl = TRUE))
  stop("Post-canonicalization manifest still contains a moving package repository.",
       call. = FALSE)
cat("Manifest OK: canonical fields preserved and exact retained package provenance verified.\n")
