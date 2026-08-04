# ===========================================================================
# fetch_inv_all.R — pull the immutable RELEASE-2026 Macroinvertebrate
# collection source for all aquatic sites. Persist non-authoritative fetch
# evidence before contract validation, then issue the authoritative source
# receipt only after the complete source contract passes.
#
# Run from the repository root with exactly R 4.5.2 and neonUtilities 4.0.1:
#   Rscript --vanilla scripts/fetch_inv_all.R
# ===========================================================================

source("scripts/inv_source_contract.R", local = TRUE)

INV_NEON_API_BASE_URL <- "https://data.neonscience.org/api/v0/"
INV_NEON_AUTH_CHECK_URL <- paste0(
  INV_NEON_API_BASE_URL, "data/query?",
  "productCode=DP1.10003.001&siteCode=BART&",
  "startDateMonth=2023-01&endDateMonth=2023-12&",
  "release=RELEASE-2025"
)
INV_NEON_AUTH_ATTEMPTS <- 4L
INV_NEON_AUTH_BACKOFF_SECONDS <- c(2, 4, 8)
INV_NEON_HTTP_TIMEOUT_SECONDS <- 30
INV_NEON_RATE_LIMIT_MAX_SECONDS <- 60

inv_redact_transport_message <- function(message, token) {
  message <- paste(as.character(message), collapse = " ")
  if (nzchar(token)) {
    message <- gsub(token, "<redacted>", message, fixed = TRUE)
  }
  message
}

inv_neon_auth_preflight <- function(token, request = NULL,
                                    sleep = Sys.sleep) {
  inv_assert(length(token) == 1L && !is.na(token) && nzchar(token),
             "NEON_TOKEN is required for the authentication preflight")
  if (is.null(request)) {
    inv_assert(requireNamespace("httr", quietly = TRUE),
               "httr is required for the NEON API authentication preflight")
    request <- function(url, secret) {
      httr::GET(
        url,
        httr::user_agent("NEON-My-Little-Inverts/RELEASE-2026"),
        httr::add_headers(.headers = c(
          "X-API-Token" = secret, "accept" = "application/json"
        )),
        httr::timeout(30)
      )
    }
  }
  last_transport <- "no HTTP response"
  for (attempt in seq_len(INV_NEON_AUTH_ATTEMPTS)) {
    response <- tryCatch(
      request(INV_NEON_AUTH_CHECK_URL, token),
      error = function(error) error
    )
    if (inherits(response, "condition")) {
      last_transport <- sprintf(
        "%s: %s", class(response)[[1L]],
        inv_redact_transport_message(conditionMessage(response), token)
      )
    } else if (!inherits(response, "response")) {
      last_transport <- sprintf(
        "unexpected response class %s",
        paste(class(response), collapse = "/")
      )
    } else {
      status <- as.integer(response$status_code)
      if (length(status) != 1L || is.na(status)) {
        last_transport <- "invalid HTTP status"
      } else if (identical(status, 200L)) {
        return(invisible(TRUE))
      } else if (status %in% c(401L, 403L)) {
        inv_fail(
          paste0(
            "NEON API authentication preflight returned HTTP %d; ",
            "NEON_TOKEN was rejected or has expired"
          ),
          status
        )
      } else if (!(identical(status, 429L) || status >= 500L)) {
        inv_fail("NEON API authentication preflight returned HTTP %d", status)
      } else {
        last_transport <- sprintf("retryable HTTP %d", status)
      }
    }

    if (attempt < INV_NEON_AUTH_ATTEMPTS) {
      sleep(INV_NEON_AUTH_BACKOFF_SECONDS[[attempt]])
    }
  }
  inv_fail(
    "NEON API authentication preflight failed after %d attempts: %s",
    INV_NEON_AUTH_ATTEMPTS, last_transport
  )
}

# neonUtilities 4.0.1 catches its internal httr error with try(..., silent=TRUE),
# prints only "No response", and returns NULL immediately. The authenticated
# preflight above exercises the same endpoint and headers successfully, so use a
# process-local compatibility binding that preserves getAPI's response contract
# while retaining the underlying transport detail, bounded retries, and a stable
# user agent. Exact package-version and formal-argument guards make the override
# fail closed if the pinned package implementation changes.
inv_neon_transport_user_agent <- function() {
  sprintf(
    "NEON-My-Little-Inverts/RELEASE-2026 neonUtilities/%s R/%s",
    INV_NEON_UTILITIES_VERSION, as.character(getRversion())
  )
}

inv_neon_get_api_request <- function(api_url, token = NA_character_,
                                     request = NULL, sleep = Sys.sleep,
                                     has_internet = curl::has_internet) {
  token_present <- length(token) == 1L && !is.na(token) && nzchar(token)
  token_text <- if (token_present) as.character(token) else ""
  if (!isTRUE(has_internet())) {
    message("No internet connection detected. Cannot access NEON API.")
    return(invisible(NULL))
  }
  if (is.null(request)) {
    inv_assert(requireNamespace("httr", quietly = TRUE),
               "httr is required for the NEON API transport compatibility layer")
    request <- function(url, secret) {
      configs <- list(
        httr::user_agent(inv_neon_transport_user_agent()),
        httr::timeout(INV_NEON_HTTP_TIMEOUT_SECONDS)
      )
      if (nzchar(secret)) {
        configs <- c(configs, list(httr::add_headers(.headers = c(
          "X-API-Token" = secret, "accept" = "application/json"
        ))))
      }
      do.call(httr::GET, c(list(url = url), configs))
    }
  }

  last_transport <- "no HTTP response"
  for (attempt in seq_len(INV_NEON_AUTH_ATTEMPTS)) {
    response <- tryCatch(
      request(api_url, token_text),
      error = function(error) error
    )
    if (inherits(response, "response")) {
      # Preserve the package's status/body/header semantics. Its callers own
      # ordinary HTTP-status handling; only its existing rate-limit signal causes
      # this compatibility layer to pause and retry.
      limit <- response$headers$`x-ratelimit-limit`
      remaining <- suppressWarnings(as.numeric(
        response$headers$`x-ratelimit-remaining`
      ))
      rate_limited <- !is.null(limit) && length(remaining) == 1L &&
        is.finite(remaining) && remaining <= 1
      if (!rate_limited || attempt == INV_NEON_AUTH_ATTEMPTS) {
        return(response)
      }

      reset <- suppressWarnings(as.numeric(
        response$headers$`x-ratelimit-reset`
      ))
      delay <- INV_NEON_AUTH_BACKOFF_SECONDS[[attempt]]
      if (length(reset) == 1L && is.finite(reset) && reset >= 0) {
        delay <- min(reset, INV_NEON_RATE_LIMIT_MAX_SECONDS)
      }
      sleep(delay)
      next
    }

    if (inherits(response, "condition")) {
      last_transport <- sprintf(
        "%s: %s", class(response)[[1L]],
        inv_redact_transport_message(conditionMessage(response), token_text)
      )
    } else {
      last_transport <- sprintf(
        "unexpected response class %s",
        paste(class(response), collapse = "/")
      )
    }
    if (attempt < INV_NEON_AUTH_ATTEMPTS) {
      sleep(INV_NEON_AUTH_BACKOFF_SECONDS[[attempt]])
    }
  }

  message(sprintf(
    "NEON API transport failed after %d attempts: %s",
    INV_NEON_AUTH_ATTEMPTS, last_transport
  ))
  invisible(NULL)
}

inv_neonutilities_get_api <- function(apiURL, token = NA_character_) {
  if (identical(token, "")) token <- NA_character_
  inv_neon_get_api_request(apiURL, token)
}

inv_assert_neonutilities_getapi_contract <- function(actual_version, get_api) {
  inv_assert(
    identical(actual_version, INV_NEON_UTILITIES_VERSION),
    "NEON transport compatibility requires neonUtilities %s exactly; running %s",
    INV_NEON_UTILITIES_VERSION, actual_version
  )
  inv_assert(
    is.function(get_api) && identical(names(formals(get_api)), c("apiURL", "token")),
    "neonUtilities getAPI contract drifted; refusing process-local compatibility binding"
  )
  invisible(TRUE)
}

inv_make_neonutilities_getapi_restore <- function(original, assign_binding) {
  restored <- FALSE
  function() {
    if (!restored) {
      assign_binding(original)
      restored <<- TRUE
    }
    invisible(TRUE)
  }
}

inv_assert_neonutilities_base_url <- function(base_url) {
  inv_assert(
    length(base_url) == 1L && !is.na(base_url) &&
      identical(as.character(base_url), INV_NEON_API_BASE_URL),
    paste0(
      "neonUtilities must use the exact reviewed NEON API base URL; ",
      "running %s"
    ),
    if (length(base_url)) as.character(base_url[[1L]]) else "<unset>"
  )
  invisible(TRUE)
}

inv_initialize_neonutilities_base_url <- function(globals = NULL,
                                                   actual_version = NULL) {
  # neonUtilities 4.0.1 initializes nu.globals$baseurl only in .onAttach().
  # Namespace-qualified calls load but do not attach the package, leaving the
  # value absent and turning its intended URL into the bare host "data". Set only
  # that process-local field, reject any nonblank override, and return an exact,
  # idempotent restoration closure.
  if (is.null(actual_version)) {
    actual_version <- as.character(utils::packageVersion("neonUtilities"))
  }
  inv_assert(
    identical(actual_version, INV_NEON_UTILITIES_VERSION),
    "NEON base-URL initialization requires neonUtilities %s exactly; running %s",
    INV_NEON_UTILITIES_VERSION, actual_version
  )
  if (is.null(globals)) {
    globals <- get(
      "nu.globals", envir = asNamespace("neonUtilities"), inherits = FALSE
    )
  }
  inv_assert(
    is.environment(globals),
    "neonUtilities nu.globals contract drifted; refusing base-URL initialization"
  )
  prior_exists <- exists("baseurl", envir = globals, inherits = FALSE)
  prior <- if (prior_exists) get("baseurl", envir = globals) else NULL
  prior_blank <- !prior_exists || !length(prior) ||
    (length(prior) == 1L && !is.na(prior) && identical(as.character(prior), ""))
  if (!prior_blank) inv_assert_neonutilities_base_url(prior)
  assign("baseurl", INV_NEON_API_BASE_URL, envir = globals)
  inv_assert_neonutilities_base_url(globals$baseurl)

  restored <- FALSE
  function() {
    if (!restored) {
      if (prior_exists) {
        assign("baseurl", prior, envir = globals)
      } else if (exists("baseurl", envir = globals, inherits = FALSE)) {
        rm(list = "baseurl", envir = globals)
      }
      restored <<- TRUE
    }
    invisible(TRUE)
  }
}

inv_install_neonutilities_getapi_compat <- function() {
  actual_version <- as.character(utils::packageVersion("neonUtilities"))
  namespace <- asNamespace("neonUtilities")
  original <- get("getAPI", envir = namespace, inherits = FALSE)
  inv_assert_neonutilities_getapi_contract(actual_version, original)
  assign_binding <- function(value) {
    utils::assignInNamespace("getAPI", value, ns = "neonUtilities")
  }
  assign_binding(inv_neonutilities_get_api)
  restore <- inv_make_neonutilities_getapi_restore(original, assign_binding)
  installed <- get("getAPI", envir = namespace, inherits = FALSE)
  installed_ok <- is.function(installed) &&
    identical(names(formals(installed)), c("apiURL", "token"))
  if (!installed_ok) {
    restore()
  }
  inv_assert(
    installed_ok,
    "Failed to install the guarded neonUtilities transport compatibility binding"
  )
  restore
}

inv_persist_fetched_source <- function(source_data, artifact_path,
                                       evidence_path, receipt_path,
                                       fetched_at_utc, producer_git_sha) {
  # neonUtilities can return Arrow ALTREP-backed atomic columns. Allocate
  # ordinary base vectors before serialization so independent validators do not
  # need Arrow merely to read the immutable evidence artifact.
  source_data <- inv_materialize_source(source_data)
  inv_persist_fetch_evidence(
    source_data, artifact_path, evidence_path, producer_git_sha,
    fetched_at_utc
  )
  inv_verify_fetch_evidence(artifact_path, evidence_path)

  # Authority is based on the exact object reread from the persisted bytes, not
  # on a potentially different in-memory representation returned by the client.
  persisted_source <- readRDS(artifact_path)
  inv_assert(identical(persisted_source, source_data),
             "Portable source changed during the persisted-byte round trip")

  # Any failure below intentionally leaves only the raw artifact plus its
  # non-authoritative evidence receipt. No source receipt means no candidate.
  source_summary <- inv_validate_source(persisted_source)
  inv_persist_authoritative_source_receipt(
    persisted_source, artifact_path, receipt_path, producer_git_sha,
    fetched_at_utc
  )
  receipt <- inv_verify_fetch_source_handoff(
    artifact_path, evidence_path, receipt_path
  )$receipt
  invisible(list(summary = source_summary, receipt = receipt))
}

fetch_inv_all <- function() {
  inv_assert_fetch_runtime()
  restore_base_url <- inv_initialize_neonutilities_base_url()
  on.exit(restore_base_url(), add = TRUE)
  producer_git_sha <- inv_assert_producer_git_sha(
    trimws(Sys.getenv("SOURCE_SHA", ""))
  )

  out_dir <- normalizePath(file.path("..", "inverts-data-fetch"), mustWork = FALSE)
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  artifact_path <- file.path(out_dir, INV_SOURCE_ARTIFACT_FILE)
  evidence_path <- file.path(out_dir, INV_FETCH_EVIDENCE_FILE)
  receipt_path <- file.path(out_dir, INV_SOURCE_RECEIPT_FILE)

  artifact_exists <- file.exists(artifact_path)
  evidence_exists <- file.exists(evidence_path)
  receipt_exists <- file.exists(receipt_path)
  if (artifact_exists || evidence_exists || receipt_exists) {
    inv_assert(artifact_exists && evidence_exists,
               paste0(
                 "Existing fetch evidence is incomplete: artifact=%s ",
                 "evidence=%s receipt=%s"
               ), artifact_exists, evidence_exists, receipt_exists)
    inv_verify_fetch_evidence(artifact_path, evidence_path)
    inv_assert(receipt_exists,
               paste0(
                 "Existing fetch is evidence-only and is not publication ",
                 "authorized: %s"
               ), evidence_path)
    inv_verify_fetch_source_handoff(artifact_path, evidence_path, receipt_path)
    cat(sprintf(
      "Verified existing raw evidence and authoritative receipt: %s\n",
      artifact_path
    ))
    return(invisible(artifact_path))
  }

  token <- trimws(Sys.getenv("NEON_TOKEN", ""))
  inv_assert(nzchar(token),
             "NEON_TOKEN is required; anonymous or workstation-path fallback is forbidden")
  inv_neon_auth_preflight(token)
  restore_transport <- inv_install_neonutilities_getapi_compat()
  on.exit(restore_transport(), add = TRUE)

  cat(sprintf(
    "Fetching %s, all sites/all dates, package=%s, release=%s, provisional=%s...\n",
    INV_DPID, INV_QUERY_PACKAGE, INV_RELEASE, INV_INCLUDE_PROVISIONAL
  ))
  started <- Sys.time()
  source_data <- neonUtilities::loadByProduct(
    dpID = INV_DPID,
    site = "all",
    startdate = NA,
    enddate = NA,
    package = INV_QUERY_PACKAGE,
    tabl = "all",
    timeIndex = "all",
    cloud.mode = FALSE,
    release = INV_RELEASE,
    include.provisional = INV_INCLUDE_PROVISIONAL,
    check.size = FALSE,
    token = token,
    nCores = 1,
    forceParallel = FALSE,
    useFasttime = FALSE,
    progress = TRUE
  )
  inv_assert(
    is.list(source_data) && !is.null(names(source_data)) &&
      length(names(source_data)) == length(source_data),
    paste0(
      "neonUtilities returned no named RELEASE-2026 source after a ",
      "successful authenticated preflight"
    )
  )

  fetched_at_utc <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  persisted <- inv_persist_fetched_source(
    source_data, artifact_path, evidence_path, receipt_path, fetched_at_utc,
    producer_git_sha
  )
  source_summary <- persisted$summary
  cat("Validated objects:", paste(source_summary$object_names, collapse = ", "), "\n")
  for (table_name in INV_REQUIRED_TABLES) {
    table <- source_data[[table_name]]
    cat(sprintf("  %-32s %7d rows x %d cols\n",
                table_name, nrow(table), ncol(table)))
  }

  receipt <- persisted$receipt
  cat(sprintf(
    "Saved and receipt-verified %s (%s; %.1f min)\n",
    artifact_path, receipt$artifact$sha256,
    as.numeric(difftime(Sys.time(), started, units = "mins"))
  ))
  invisible(artifact_path)
}

if (sys.nframe() == 0L) fetch_inv_all()
