# ===========================================================================
# NEON My Little Inverts — one-page field-first PDF
# Base graphics keeps the Connect deployment lean and deterministic.
# ===========================================================================

.inv_wrap_width <- function(text, max_width, cex) {
  words <- strsplit(as.character(text), "\\s+")[[1L]]
  words <- words[nzchar(words)]
  if (!length(words)) return("")
  lines <- character()
  current <- ""
  for (word in words) {
    candidate <- if (nzchar(current)) paste(current, word) else word
    if (graphics::strwidth(candidate, cex = cex, units = "user") > max_width &&
        nzchar(current)) {
      lines <- c(lines, current)
      current <- word
    } else {
      current <- candidate
    }
  }
  if (nzchar(current)) lines <- c(lines, current)
  lines
}

.inv_report_draw <- function(bundle, site_code, label) {
  checked <- inv_validate_bundle(bundle, expected_site = site_code)
  if (!isTRUE(checked)) stop(inv_contract_reason(checked), call. = FALSE)

  meta <- bundle$meta
  ledger <- inv_status_ledger(bundle$opportunities)
  status <- stats::setNames(ledger$n, ledger$record_status)
  processing <- inv_processing_count_counts(bundle$opportunities)
  support <- inv_support_counts(bundle$opportunities)
  source <- bundle$provenance$source %||% list()
  site_row <- neon_sites[neon_sites$site == site_code, , drop = FALSE]

  teal <- "#0e8f9c"
  teal_dark <- "#0a6f7a"
  aqua <- "#2bb7c4"
  ink <- "#102a33"
  ink_two <- "#274a54"
  muted <- "#5d7c84"
  amber <- "#9c5d18"
  line <- "#cfe4e6"
  tile <- "#eef6f7"

  fmt <- function(value) inv_value(value)
  op <- graphics::par(mar = c(0, 0, 0, 0), xpd = NA)
  on.exit(graphics::par(op), add = TRUE)
  graphics::plot.new()
  graphics::plot.window(xlim = c(0, 100), ylim = c(0, 130))
  left <- 8
  right <- 92

  text_at <- function(x, y, text, cex = 1, color = ink, font = 1, adj = 0) {
    graphics::text(x, y, text, cex = cex, col = color, font = font, adj = adj)
  }
  paragraph <- function(x, y, text, max_width, cex = 0.85,
                        color = ink_two, line_height = 2.35, font = 1) {
    lines <- .inv_wrap_width(text, max_width, cex)
    for (i in seq_along(lines)) {
      text_at(x, y - (i - 1L) * line_height, lines[[i]], cex = cex,
              color = color, font = font)
    }
    y - length(lines) * line_height
  }

  graphics::rect(0, 119, 100, 130, col = teal_dark, border = NA)
  graphics::rect(0, 117.7, 100, 119, col = aqua, border = NA)
  text_at(left, 125.2, "NEON · My Little Inverts", cex = 1.7,
          color = "#ffffff", font = 2)
  text_at(left, 121.5, "Field-first aquatic invertebrate record",
          cex = 0.9, color = "#d6f3f5")
  text_at(right, 125.2, source$release %||% "Release unavailable",
          cex = 0.9, color = "#d6f3f5", adj = 1)
  text_at(right, 121.5, "DP1.20120.001", cex = 0.82,
          color = "#bfe7ea", adj = 1)

  text_at(left, 113, label %||% site_code, cex = 1.45, font = 2)
  subtitle <- sprintf(
    "%s · %s · %s",
    TYPE_LAB[meta$aquaticSiteType] %||% meta$aquaticSiteType %||% "Water type unavailable",
    if (nrow(site_row)) paste0("NEON ", site_row$domain[[1L]], " · ",
                               site_row$state[[1L]]) else site_code,
    inv_year_label(meta)
  )
  text_at(left, 109.2, subtitle, cex = 0.95, color = teal_dark)
  if (nrow(site_row)) {
    paragraph(left, 105.6, site_row$bio[[1L]], right - left, cex = 0.87,
              color = muted, line_height = 2.4)
  }

  # Six counts. Each label names its denominator or record boundary.
  grid_top <- 96
  cell_height <- 11
  cell_width <- (right - left) / 3
  cells <- list(
    list(value = fmt(meta$n_opportunities), label = "field opportunities"),
    list(value = fmt(meta$n_primary_opportunities), label = "primary-stratum opportunities"),
    list(value = fmt(meta$n_events), label = "collection events"),
    list(value = fmt(meta$n_count_samples), label = "count-eligible samples"),
    list(value = fmt(meta$n_density_samples), label = "density-eligible samples"),
    list(value = fmt(meta$n_taxa_recorded), label = "mixed-rank taxa recorded")
  )
  for (i in seq_along(cells)) {
    column <- (i - 1L) %% 3L
    row <- (i - 1L) %/% 3L
    x0 <- left + column * cell_width
    y_top <- grid_top - row * (cell_height + 2.4)
    graphics::rect(x0, y_top - cell_height, x0 + cell_width - 2.4, y_top,
                   col = tile, border = line)
    graphics::rect(x0, y_top - 0.9, x0 + cell_width - 2.4, y_top,
                   col = teal, border = NA)
    text_at(x0 + 2.4, y_top - 5.1, cells[[i]]$value, cex = 1.35, font = 2)
    text_at(x0 + 2.4, y_top - 8.7, cells[[i]]$label, cex = 0.67, color = muted)
  }

  y <- 64
  text_at(left, y, "OPPORTUNITY LEDGER · STATUS + SUPPORT", cex = 0.8,
          color = teal_dark, font = 2)
  y <- y - 3.2
  ledger_lines <- c(
    sprintf("Support flags (may overlap): sampling impractical %s · nonstandard collection %s · stratum fields unavailable %s.",
            fmt(support[["sampling_impractical"]]),
            fmt(support[["nonstandard_collection"]]),
            fmt(support[["unstratifiable"]])),
    sprintf("Exclusive outcomes among practical opportunities: processing unknown %s · processed without taxonomy %s · taxonomy/count unavailable %s · taxonomy/count available %s.",
            fmt(processing[["processing_unknown"]]),
            fmt(processing[["processed_no_taxonomy"]]),
            fmt(processing[["taxonomy_count_unavailable"]]),
            fmt(processing[["taxonomy_count_available"]])),
    sprintf("Primary quantitative status: count unavailable %s · area unavailable %s · density unavailable %s.",
            fmt(status[["count_unavailable"]]), fmt(status[["area_unavailable"]]),
            fmt(status[["density_unavailable"]])),
    sprintf("Overlapping support flags: reported zero %s · integer-displayed 0%% with authoritative estimate %s · quantified-community primary status %s.",
            fmt(support[["reported_zero_count"]]),
            fmt(support[["displayed_zero_percent_authoritative_estimate"]]),
            fmt(status[["quantified_community"]]))
  )
  for (item in ledger_lines) {
    graphics::points(left + 0.7, y - 0.8, pch = 19, cex = 0.4, col = teal)
    y <- paragraph(left + 2.5, y, item, right - left - 2.5,
                   cex = 0.82, line_height = 2.3)
    y <- y - 1.2
  }

  text_at(left, y, "HOW TO READ THE RECORD", cex = 0.8,
          color = teal_dark, font = 2)
  y <- y - 3.2
  boundaries <- c(
    "A processed sample with taxonomy unavailable remains unknown. Only a usable laboratory expanded total of zero is labeled reported zero.",
    "Count, density, composition, and taxon support use explicitly named eligible-sample denominators inside one exact event, water type, habitat, and sampler stratum.",
    "Identification rank is retained. EPT is a descriptive taxonomic grouping, and unknown-order counts remain in its composition denominator.",
    "Network comparisons are limited to effort and record counts. Collection density is not a population estimate."
  )
  for (item in boundaries) {
    graphics::points(left + 0.7, y - 0.8, pch = 19, cex = 0.4, col = teal)
    y <- paragraph(left + 2.5, y, item, right - left - 2.5,
                   cex = 0.80, line_height = 2.2)
    y <- y - 0.9
  }

  box_top <- 20
  graphics::rect(left, 7, right, box_top, col = "#fdf3e2", border = "#f1dcb0")
  graphics::rect(left, 7, left + 0.9, box_top, col = amber, border = NA)
  text_at(left + 3, box_top - 3, "SOURCE RECEIPT", cex = 0.76,
          color = amber, font = 2)
  receipt <- sprintf(
    "NEON %s · release %s · provisional %s · publication through %s · raw SHA-256 %s.",
    source$dpid %||% "DP1.20120.001", source$release %||% "unavailable",
    if (isTRUE(source$include_provisional)) "included" else "not included",
    source$publication_date_max %||% "unavailable",
    source$artifact_sha256 %||% "unavailable"
  )
  paragraph(left + 3, box_top - 6.2, receipt, right - left - 4,
            cex = 0.76, color = "#6b4a16", line_height = 2.15)

  text_at(left, 3.5, "Built by Desert Data Labs · Tucson, AZ",
          cex = 0.75, color = muted)
  text_at(right, 3.5, "Unofficial educational explorer",
          cex = 0.72, color = muted, adj = 1)
  invisible(TRUE)
}

inv_report_pdf <- function(file, bundle, site_code, label) {
  grDevices::pdf(file, width = 8.5, height = 11, bg = "#f8fdfd",
                 pointsize = 11)
  on.exit(grDevices::dev.off(), add = TRUE)
  if (is.null(bundle)) {
    graphics::par(mar = c(0, 0, 0, 0))
    graphics::plot.new()
    graphics::text(0.5, 0.5, "No site loaded.", cex = 1.2, col = "#5d7c84")
  } else {
    .inv_report_draw(bundle, site_code, label)
  }
  invisible(file)
}
