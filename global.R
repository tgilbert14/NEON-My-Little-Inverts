# ===========================================================================
# NEON My Little Inverts — global.R
# A field-first explorer for NEON DP1.20120.001. The loaded app accepts only the
# reviewed Pass-9 bundle family. Metrics retain their exact event, water type,
# habitat, and sampler stratum; the cross-site table contains effort and record
# counts only.
# ===========================================================================
suppressPackageStartupMessages({
  library(shiny); library(bslib); library(bsicons)
  library(dplyr); library(tidyr); library(stringr); library(tibble)
  library(plotly); library(leaflet); library(DT)
  library(shinyjs); library(shinycssloaders); library(RColorBrewer); library(htmltools)
})
# ---- basemap --------------------------------------------------------------
# CARTO watermarks unauthenticated basemaps.cartocdn.com raster tiles ("API KEY
# REQUIRED", since 2026-08-26; suite record: NEON-Driver-Cascade
# docs/SUITE-BASEMAP-INCIDENT-2026-08.md). The key rides in the tile URL, so it
# is a public rate-limited identifier, not a credential; Sys.getenv keeps it out
# of git and makes rotation a Connect Cloud setting. addProviderTiles() cannot
# carry it (the bundled CartoDB template has no {apikey} slot), hence addTiles().
# Accepts either a leaflet provider name or a CARTO variant, so ui.R basemap
# choices stay exactly as they are and any non-CARTO provider passes straight
# through. Without the key it falls back to Esri's keyless grey canvas — clean,
# but content-free past z16 at rural sites, so the cap keeps the zoom honest.
add_suite_basemap <- function(map, basemap = "light_all", noWrap = FALSE) {
  variant <- switch(basemap,
    "light_all" = ,
    "CartoDB.Positron" = "light_all",
    "dark_all" = ,
    "CartoDB.DarkMatter" = "dark_all",
    NULL)
  if (is.null(variant))
    return(leaflet::addProviderTiles(map, basemap,
      options = leaflet::providerTileOptions(noWrap = noWrap)))
  key <- Sys.getenv("CARTO_BASEMAP_KEY", "")
  if (nzchar(key)) {
    leaflet::addTiles(map,
      urlTemplate = sprintf(
        "https://{s}.basemaps.cartocdn.com/%s/{z}/{x}/{y}{r}.png?key=%s", variant, key),
      attribution = paste(
        '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
        '&copy; <a href="https://carto.com/attributions">CARTO</a>'),
      options = leaflet::tileOptions(subdomains = "abcd", maxZoom = 20, noWrap = noWrap))
  } else {
    leaflet::addTiles(map,
      urlTemplate = sprintf(
        "https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_%s_Gray_Base/MapServer/tile/{z}/{y}/{x}",
        if (identical(variant, "dark_all")) "Dark" else "Light"),
      attribution = 'Tiles &copy; Esri &mdash; Esri, HERE, Garmin, &copy; OpenStreetMap contributors',
      options = leaflet::tileOptions(maxNativeZoom = 16, maxZoom = 19, noWrap = noWrap))
  }
}

source("R/site_metadata.R", local = FALSE)
source("R/inv_helpers.R",   local = FALSE)
source("R/report_pdf.R",    local = FALSE)

NEON_DPID <- "DP1.20120.001"   # Macroinvertebrate collection
NEON_RELEASE <- "RELEASE-2026"
NEON_DOI <- "10.48443/hp56-s582"
APP_RELEASE_MARKER <- "my-little-inverts-release-2026-v1"
# neonUtilities is referenced by a COMPUTED name so the rsconnect static scan
# never pins it into the manifest (the deploy is bundle-only + lean; no live fetch).
.NEON_PKG <- paste0("neon", "Utilities")
LIVE_FETCH <- (Sys.getenv("INV_LIVE", "0") != "0") && requireNamespace(.NEON_PKG, quietly = TRUE)

SITE_DIR  <- "data/sites"
DEMO_PATH <- "data-sample/demo.rds"
DEMO_META <- list(site = "SYCA", label = "SYCA · Sycamore Creek · demo")

# One deterministic identity binds the reviewed source receipt/artifact, exact
# bundle-hash family, derived indexes, runtime and Pages bytes, and canonical
# Connect manifest contract. It is generated only by the clean validator and is
# exposed in the initial Shiny HTML for content-aware production verification.
RELEASE_IDENTITY_PATH <- "release/production-identity.json"
RELEASE_IDENTITY <- tryCatch(
  jsonlite::fromJSON(RELEASE_IDENTITY_PATH, simplifyVector = FALSE),
  error = function(error) {
    stop("Cannot read deterministic production identity: ",
         conditionMessage(error), call. = FALSE)
  }
)
identity_chr <- function(field) {
  value <- RELEASE_IDENTITY[[field]]
  if (is.null(value) || length(value) != 1L || is.na(value)) "" else
    as.character(value)
}
identity_fields <- c(
  "schema_version", "app_id", "product", "release", "doi",
  "source_artifact_sha256", "source_receipt_sha256",
  "release_contract_sha256", "bundle_family_sha256", "site_index_sha256",
  "cross_site_sha256", "search_index_sha256", "demo_bundle_sha256",
  "runtime_payload_sha256", "pages_payload_sha256",
  "manifest_contract_sha256", "manifest_source_list_sha256", "release_id"
)
identity_hash_fields <- identity_fields[6:17]
if (!identical(names(RELEASE_IDENTITY), identity_fields) ||
    !identical(as.integer(RELEASE_IDENTITY$schema_version), 1L) ||
    !identical(identity_chr("app_id"), "NEON-My-Little-Inverts") ||
    !identical(identity_chr("product"), NEON_DPID) ||
    !identical(identity_chr("release"), NEON_RELEASE) ||
    !identical(identity_chr("doi"), NEON_DOI) ||
    !all(vapply(identity_hash_fields, function(field) {
      grepl("^[0-9a-f]{64}$", identity_chr(field))
    }, logical(1)))) {
  stop("Production identity does not match the app release contract.",
       call. = FALSE)
}
release_identity_material <- c(
  "neon-my-little-inverts-production-instance-v1",
  vapply(identity_fields[2:17], identity_chr, character(1))
)
RELEASE_INSTANCE_ID <- paste0(
  "sha256:", digest::digest(
    paste(release_identity_material, collapse = "\n"),
    algo = "sha256", serialize = FALSE
  )
)
if (!identical(identity_chr("release_id"), RELEASE_INSTANCE_ID)) {
  stop("Production release ID does not re-derive from its identity fields.",
       call. = FALSE)
}

# A corrupt, stale, or legacy bundle never reaches the reactive app. Validation
# returns NULL with a diagnostic rather than attempting a compatibility guess.
read_bundle <- function(f, expected_site = NULL, expected_sha256 = NULL,
                        release_contract = NULL) {
  if (!file.exists(f)) return(NULL)
  if (!is.null(expected_sha256)) {
    hash_check <- inv_verify_file_sha256(f, expected_sha256)
    if (!isTRUE(hash_check)) {
      warning(sprintf("read_bundle('%s'): %s", f,
                      inv_contract_reason(hash_check)))
      return(NULL)
    }
  }
  out <- tryCatch(
    readRDS(f),
    error = function(e) {
      warning(sprintf("read_bundle('%s'): %s", f, conditionMessage(e)))
      NULL
    }
  )
  if (is.null(out)) return(NULL)
  checked <- inv_validate_bundle(
    out, expected_site = expected_site, release_contract = release_contract
  )
  if (!isTRUE(checked)) {
    warning(sprintf("read_bundle('%s'): %s", f, inv_contract_reason(checked)))
    return(NULL)
  }
  out
}
load_site_bundle <- function(site) {
  if (!isTRUE(release_contract_ok) || length(site) != 1L ||
      is.na(site) || !site %in% as.character(RELEASE_CONTRACT$site_ids)) {
    return(NULL)
  }
  expected_hash <- RELEASE_CONTRACT$bundle_sha256[[site]]
  read_bundle(
    file.path(SITE_DIR, paste0(site, ".rds")), expected_site = site,
    expected_sha256 = expected_hash,
    release_contract = RELEASE_CONTRACT
  )
}
load_demo <- function() {
  if (!isTRUE(release_contract_ok)) return(NULL)
  b <- load_site_bundle(DEMO_META$site)
  if (!is.null(b)) return(b)
  expected_hash <- RELEASE_CONTRACT$bundle_sha256[[DEMO_META$site]]
  read_bundle(
    DEMO_PATH, expected_site = DEMO_META$site,
    expected_sha256 = expected_hash,
    release_contract = RELEASE_CONTRACT
  )
}

read_app_rds <- function(path) {
  tryCatch(readRDS(path), error = function(e) {
    warning(sprintf("readRDS('%s'): %s", path, conditionMessage(e)))
    NULL
  })
}

identity_file_contract <- c(
  "data/release_contract.rds" = identity_chr("release_contract_sha256"),
  "data/source_receipt.json" = identity_chr("source_receipt_sha256"),
  "data/site_index.rds" = identity_chr("site_index_sha256"),
  "data/cross_site.rds" = identity_chr("cross_site_sha256"),
  "data/search_index.rds" = identity_chr("search_index_sha256"),
  "data-sample/demo.rds" = identity_chr("demo_bundle_sha256")
)
for (path in names(identity_file_contract)) {
  identity_file_check <- inv_verify_file_sha256(
    path, unname(identity_file_contract[[path]])
  )
  if (!isTRUE(identity_file_check)) {
    stop("Production release file differs from its identity: ", path, " (",
         inv_contract_reason(identity_file_check), ")", call. = FALSE)
  }
}

RELEASE_CONTRACT <- read_app_rds("data/release_contract.rds")
release_contract_check <- inv_validate_release_contract(
  RELEASE_CONTRACT, expected_sites = as.character(neon_sites$site)
)
release_contract_ok <- isTRUE(release_contract_check)
if (release_contract_ok) {
  bundle_entries <- paste(
    as.character(RELEASE_CONTRACT$site_ids),
    as.character(RELEASE_CONTRACT$bundle_sha256), sep = "\t"
  )
  bundle_material <- paste0(paste(bundle_entries, collapse = "\n"), "\n")
  bundle_family_sha256 <- unname(digest::digest(
    paste("neon-inverts-bundle-family-v1", bundle_material, sep = "\n"),
    algo = "sha256", serialize = FALSE
  ))
  if (!identical(
    as.character(RELEASE_CONTRACT$source$artifact_sha256),
    identity_chr("source_artifact_sha256")
  ) || !identical(
    as.character(RELEASE_CONTRACT$source$receipt_sha256),
    identity_chr("source_receipt_sha256")
  ) || !identical(bundle_family_sha256,
                  identity_chr("bundle_family_sha256"))) {
    release_contract_check <- inv_contract_result(
      FALSE, "release contract differs from the production identity"
    )
    release_contract_ok <- FALSE
  }
}
if (release_contract_ok) {
  receipt_check <- inv_verify_file_sha256(
    "data/source_receipt.json", RELEASE_CONTRACT$source$receipt_sha256
  )
  if (!isTRUE(receipt_check)) {
    release_contract_check <- receipt_check
    release_contract_ok <- FALSE
  }
}
if (!release_contract_ok) {
  warning(sprintf(
    "Pass-9 release contract is missing or invalid; bundled data are disabled: %s",
    inv_contract_reason(release_contract_check)
  ))
}

SITE_INDEX <- if (release_contract_ok) read_app_rds("data/site_index.rds") else NULL
site_index_ok <- inv_validate_site_index(
  SITE_INDEX, if (release_contract_ok) RELEASE_CONTRACT else NULL
)
if (!isTRUE(site_index_ok)) {
  if (!is.null(SITE_INDEX)) warning(inv_contract_reason(site_index_ok))
  SITE_INDEX <- NULL
}
BUNDLED <- if (!is.null(SITE_INDEX)) {
  roster <- as.character(RELEASE_CONTRACT$site_ids)
  if (!identical(as.character(SITE_INDEX$site), roster)) {
    warning("site_index roster/order differs from the release contract")
    character(0)
  } else roster
} else character(0)

# ---------------------------------------------------------------------------
# The search index carries exact-stratum taxon support rows and the same
# effort/records-only site table. It is disabled if either contract is stale.
# ---------------------------------------------------------------------------
SEARCH_INDEX <- if (length(BUNDLED)) read_app_rds("data/search_index.rds") else NULL
search_index_ok <- inv_validate_search_index(
  SEARCH_INDEX,
  if (release_contract_ok) RELEASE_CONTRACT else NULL,
  SITE_INDEX
)
if (!isTRUE(search_index_ok)) {
  if (!is.null(SEARCH_INDEX)) warning(inv_contract_reason(search_index_ok))
  SEARCH_INDEX <- NULL
}
SEARCH_TAXA <- if (!is.null(SEARCH_INDEX)) SEARCH_INDEX$taxa else NULL

# the autocomplete vocabulary: one entry per distinct taxon (display -> code-ish
# key uses the scientificName itself; EPT is a descriptive taxonomic grouping)
search_taxon_choices <- function() {
  if (is.null(SEARCH_TAXA) || !nrow(SEARCH_TAXA)) return(NULL)
  u <- SEARCH_TAXA[
    !duplicated(SEARCH_TAXA$scientificName),
    c("scientificName", "taxonRank", "is_ept", "order")
  ]
  u <- u[order(u$scientificName), ]
  lab <- inv_taxon_label(u$scientificName, u$taxonRank, u$is_ept)
  setNames(u$scientificName, lab)
}

# join the NEON site metadata (name / state / domain / bio) onto the index. The
# bundle's meta$name is NA-filled at build time, so the app supplies it here.
site_table <- if (length(BUNDLED)) {
  m <- neon_sites[match(BUNDLED, neon_sites$site), ]
  keep <- setdiff(INV_SITE_INDEX_COLUMNS, "site")
  out <- cbind(m, SITE_INDEX[match(m$site, SITE_INDEX$site), keep, drop = FALSE])
  # fall back to the index's aquaticSiteType where the metadata table is missing one
  out$type <- ifelse(is.na(out$type), out$aquaticSiteType, out$type)
  out[order(out$name), ]
} else neon_sites[0, ]

NO_DATA <- is.null(SITE_INDEX) || !length(BUNDLED) || !nrow(site_table)

# state choices for the by-name select panel
inv_state_choices <- function() {
  st <- sort(unique(site_table$state)); if (!length(st)) return(NULL)
  setNames(st, sprintf("%s (%d)", state_names[st] %||% st, as.integer(table(site_table$state)[st])))
}
inv_sites_in_state <- function(stt) {
  rows <- site_table[site_table$state == stt, ]; rows <- rows[order(rows$name), ]
  if (!nrow(rows)) return(character(0))
  setNames(rows$site, sprintf("%s · %s", rows$site, rows$name))
}

# ---------------------------------------------------------------------------
# "Riffle & Teal" palette (Vera). A water-teal/aqua primary on a cool
# paper page, a kingfisher-blue secondary, and a reserved coral for the high QC
# flag. OLD key names (navy / cardinal / gold / sky / green) are kept and
# REMAPPED so the shared chrome (server.R's DDL$… references, styles.css token
# names) re-themes for free. The DATA palettes (EPT / aquaticSiteType) are LOCKED
# below — they encode data, never theme, and are never aliased to a CSS token.
# ---------------------------------------------------------------------------
DDL <- list(
  paper = "#f8fdfd", bg = "#eef6f7",
  ink = "#102a33", ink2 = "#274a54", muted = "#5d7c84", line = "#cfe4e6",
  teal = "#0e8f9c", teal2 = "#0a6f7a", aqua = "#2bb7c4",
  coral = "#e0524d", coral_ink = "#9c3531",
  # legacy aliases -> riffle-teal, so shared code paths stay on-theme
  navy = "#123640", navy2 = "#1f5560", cardinal = "#0e8f9c",
  gold = "#e08a2b", gold2 = "#9c5d18", sky = "#2bb7c4",
  green = "#3f9e6e", green2 = "#2f7d56", terra = "#0e8f9c", rust = "#0e8f9c")

# ---- LOCKED DATA palettes (data, never theme; never read from var(--…)) ----
# EPT vs other — a descriptive taxonomic grouping, never a condition class.
EPT_COL <- c(EPT = "#0e8f9c", other = "#94a7ad")
ept_col <- function(c) { out <- unname(EPT_COL[c]); ifelse(is.na(out), unname(EPT_COL["other"]), out) }
# aquatic site type — the picker-map + cross-site colour. Fixed legend order.
TYPE_COL <- c(stream = "#0e8f9c", river = "#2f7daa", lake = "#5a8f3e")
type_col <- function(t) { out <- unname(TYPE_COL[t]); ifelse(is.na(out), "#94a7ad", out) }
TYPE_LAB <- c(stream = "Stream", river = "River", lake = "Lake")

# Rubik is named as a PLAIN CSS font-family here (a bslib font_collection of bare
# strings), NOT font_google("Rubik"). font_google() defaults to local = TRUE, which
# makes bslib DOWNLOAD the font from Google and compile it into the theme AT APP
# STARTUP. On Connect Cloud that live fetch runs on every cold start against an empty
# cache; when Google Fonts is slow/unreachable the Sass compile blocks/fails during
# boot -> black screen / "start-up error" (republish only re-primes the cache until the
# next recycle). Naming the family as a string does ZERO network at boot; the real
# Rubik glyphs are still delivered client-side by the <link> in ui.R (display=swap),
# with a system-sans fallback. See docs/neonize-playbook.md §4.
rubik_stack <- bslib::font_collection(
  "Rubik", "system-ui", "-apple-system", "Segoe UI", "Roboto", "Helvetica Neue", "Arial", "sans-serif")
app_theme <- bs_theme(version = 5, bg = "#f8fdfd", fg = DDL$ink,
  primary = DDL$teal, secondary = DDL$aqua, success = DDL$green, info = DDL$sky,
  warning = DDL$gold, danger = DDL$coral,
  base_font = rubik_stack, heading_font = rubik_stack, "border-radius" = "10px")

asset_url <- function(path) { f <- file.path("www", path)
  v <- if (file.exists(f)) as.integer(as.numeric(file.mtime(f))) else 0L; sprintf("%s?v=%s", path, v) }
spin <- function(x, img = NULL) shinycssloaders::withSpinner(x, color = DDL$teal, type = 6)
info_pop <- function(title, ..., placement = "auto")
  bslib::popover(tags$span(class = "info-dot", bsicons::bs_icon("info-circle")), ..., title = title, placement = placement)
insight_banner <- function(icon, ..., tone = "navy")
  div(class = paste("chart-insight", paste0("ci-", tone)), bsicons::bs_icon(icon), div(class = "ci-text", ...))
glow_badge <- function(label, color = "#0e8f9c", glow = color)
  span(class = "glow-badge", style = sprintf("color:#fff; background:%s; border-color:%s;", color, color), label)
card_head <- function(icon, title, ...)
  bslib::card_header(class = "with-info", bsicons::bs_icon(icon), tags$span(class = "ch-title", " ", title), ...)
fmt_int <- function(x) format(round(as.numeric(x)), big.mark = ",", trim = TRUE)

# ---------------------------------------------------------------------------
# The suite registry (ONE source of truth, mirrored in docs/index.html). Every
# sibling links to every other; the About "Explore the NEON series" block renders
# this. is-self is flagged by matching dpid to NEON_DPID. Keep in sync when an app
# ships. URLs are the github.io showcase covers (the public front doors).
# ---------------------------------------------------------------------------
SUITE_REGISTRY <- list(
  list(name = "Small Mammal Tracker",  emoji = "\U0001F42D", tag = "tagged rodents, mark-recapture", dpid = "DP1.10072.001", url = "https://tgilbert14.github.io/NEON-Small-Mammal-Tracker-App/"),
  list(name = "Plant Diversity",       emoji = "\U0001F33F", tag = "plots, richness, expected-vs-observed", dpid = "DP1.10058.001", url = "https://tgilbert14.github.io/NEON-Plant-Diversity/"),
  list(name = "Breeding Birds",        emoji = "\U0001F426", tag = "point counts and community records", dpid = "DP1.10003.001", url = "https://tgilbert14.github.io/NEON-Breeding-Birds/"),
  list(name = "Plant Phenology",       emoji = "\U0001F33C", tag = "leaf-out and flowering timing", dpid = "DP1.10055.001", url = "https://tgilbert14.github.io/NEON-Plant-Phenology-Explorer/"),
  list(name = "Vegetation Structure",  emoji = "\U0001F332", tag = "tree size, basal area, standing stock", dpid = "DP1.10098.001", url = "https://tgilbert14.github.io/NEON-Vegetation-Structure-Explorer/"),
  list(name = "Ground Beetle Tracker", emoji = "\U0001FAB2", tag = "pitfall carabids by site", dpid = "DP1.10022.001", url = "https://tgilbert14.github.io/NEON-Ground-Beetle-Tracker/"),
  list(name = "Water Chemistry",       emoji = "\U0001F4A7", tag = "stream chemistry and conductivity", dpid = "DP1.20093.001", url = "https://tgilbert14.github.io/NEON-WaterChemistry-Analyte-Viewer-App/"),
  list(name = "Mosquito Pulse",        emoji = "\U0001F99F", tag = "CO2-trap mosquitoes, the monsoon pulse", dpid = "DP1.10043.001", url = "https://tgilbert14.github.io/NEON-Mosquito-Pulse/"),
  list(name = "My Little Inverts",     emoji = "\U0001F990", tag = "stream and lake bottom-dwellers, EPT", dpid = "DP1.20120.001", url = "https://tgilbert14.github.io/NEON-My-Little-Inverts/"),
  list(name = "Driver Cascade",        emoji = "\U0001F30E", tag = "cross-product synthesis, the master view", dpid = "cascade", url = "https://tgilbert14.github.io/NEON-Driver-Cascade/"))

# ---------------------------------------------------------------------------
# The app mascot — "Riffle," a friendly round mayfly nymph (the EPT poster-bug)
# in the riffle-teal accent. Flat, no gradient, no id (safely reusable as the
# loading spinner, the splash guide, and the celebration hop). Tails are classed
# mascot-ear-l/r so the CSS can wiggle them; eyes blink via mascot-eyes.
# ---------------------------------------------------------------------------
MASCOT_CRITTER <- htmltools::HTML(paste0(
  '<svg class="mascot" viewBox="0 0 120 120" aria-hidden="true">',
  # antennae
  '<g stroke="#2bb7c4" stroke-width="3" stroke-linecap="round" fill="none">',
  '<path d="M52,42 Q47,28 51,20"/><path d="M68,42 Q73,28 69,20"/>',
  '<circle cx="51" cy="20" r="2.5" fill="#7fe0e8" stroke="none"/><circle cx="69" cy="20" r="2.5" fill="#7fe0e8" stroke="none"/></g>',
  # three tails (cerci) — the mayfly signature, the wiggly "ears"
  '<g class="mascot-ear-l" stroke="#0a6f7a" stroke-width="3" stroke-linecap="round" fill="none">',
  '<path d="M48,98 q-10,14 -22,18"/><path d="M52,100 q-6,16 -14,22"/></g>',
  '<g class="mascot-ear-r" stroke="#0a6f7a" stroke-width="3" stroke-linecap="round" fill="none">',
  '<path d="M72,98 q10,14 22,18"/><path d="M68,100 q6,16 14,22"/></g>',
  # middle tail
  '<path d="M60,100 q0,18 0,22" stroke="#0a6f7a" stroke-width="3" stroke-linecap="round" fill="none"/>',
  # legs
  '<g stroke="#0a6f7a" stroke-width="2.6" stroke-linecap="round" fill="none">',
  '<path d="M44,72 q-16,2 -24,-6"/><path d="M44,82 q-15,8 -26,8"/>',
  '<path d="M76,72 q16,2 24,-6"/><path d="M76,82 q15,8 26,8"/></g>',
  # gill plates along the abdomen (faint teal frills)
  '<g fill="#7fe0e8" fill-opacity=".55"><ellipse cx="40" cy="62" rx="6" ry="9"/><ellipse cx="80" cy="62" rx="6" ry="9"/>',
  '<ellipse cx="42" cy="78" rx="5.5" ry="8"/><ellipse cx="78" cy="78" rx="5.5" ry="8"/></g>',
  # body (head + segmented abdomen)
  '<ellipse cx="60" cy="58" rx="20" ry="18" fill="#0e8f9c"/>',
  '<ellipse cx="60" cy="80" rx="16" ry="20" fill="#0e8f9c"/>',
  '<ellipse cx="60" cy="80" rx="9" ry="15" fill="#36b3bd"/>',
  # blush
  '<g fill="#ff9ec4" opacity=".28"><ellipse cx="48" cy="60" rx="6.5" ry="4.5"/><ellipse cx="72" cy="60" rx="6.5" ry="4.5"/></g>',
  # eyes
  '<g class="mascot-eyes"><circle cx="52" cy="55" r="6.5" fill="#0b2a30"/><circle cx="68" cy="55" r="6.5" fill="#0b2a30"/>',
  '<circle cx="50.3" cy="52.8" r="2.3" fill="#ffffff"/><circle cx="66.3" cy="52.8" r="2.3" fill="#ffffff"/></g>',
  '</svg>'))
