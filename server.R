# ===========================================================================
# NEON My Little Inverts — field-first server
# ===========================================================================

server <- function(input, output, session) {
  is_dark <- function() identical(input$colorMode, "dark")

  plotly_theme <- function(p, legend = TRUE, left = 64L) {
    dark <- is_dark()
    ink <- if (dark) "#e4f6f7" else "#102a33"
    grid <- if (dark) "rgba(228,246,247,0.09)" else "rgba(16,42,51,0.07)"
    line <- if (dark) "#1f4248" else "#cfe4e6"
    p %>%
      plotly::layout(
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        font = list(color = ink, family = "Rubik"),
        xaxis = list(gridcolor = grid, linecolor = line),
        yaxis = list(gridcolor = grid, linecolor = line),
        showlegend = legend,
        legend = list(bgcolor = "rgba(0,0,0,0)", orientation = "h", y = -0.2),
        margin = list(l = left, r = 30, t = 42, b = 64),
        hoverlabel = list(
          bgcolor = if (dark) "rgba(11,42,48,0.97)" else "rgba(16,42,51,0.95)",
          bordercolor = DDL$aqua,
          font = list(color = "#fff", family = "Rubik", size = 13)
        )
      ) %>%
      plotly::config(displayModeBar = FALSE, responsive = TRUE)
  }

  note_plot <- function(message, icon = "\U0001F990") {
    plotly::plot_ly(type = "scatter", mode = "markers") %>%
      plotly::layout(
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor = "rgba(0,0,0,0)",
        xaxis = list(visible = FALSE), yaxis = list(visible = FALSE),
        annotations = list(list(
          text = paste0(icon, "<br>", message), showarrow = FALSE,
          font = list(color = if (is_dark()) "#8db4ba" else DDL$muted,
                      size = 15), align = "center"
        ))
      ) %>%
      plotly::config(displayModeBar = FALSE)
  }

  dt <- function(data, page_length = 12L, escape = TRUE) {
    DT::datatable(
      data, rownames = FALSE, escape = escape, selection = "none",
      options = list(
        pageLength = page_length,
        scrollX = TRUE,
        autoWidth = TRUE,
        dom = "tip"
      ),
      class = "compact stripe hover"
    )
  }

  rv <- reactiveValues(
    bundle = NULL, meta = NULL, opportunities = NULL, strata = NULL,
    taxa = NULL, label = NULL, site = NULL, pendingSite = NULL
  )
  carry_tab <- reactiveVal(NULL)
  recent_codes <- reactiveVal(character())

  # ---- site picker -------------------------------------------------------
  observe({
    choices <- inv_state_choices()
    selected <- if ("AZ" %in% choices) "AZ" else if (length(choices)) choices[[1L]] else NULL
    updateSelectInput(session, "stateSel", choices = choices, selected = selected)
  })

  observeEvent(input$stateSel, {
    choices <- inv_sites_in_state(input$stateSel)
    selected <- if (!is.null(rv$pendingSite) && rv$pendingSite %in% choices) {
      rv$pendingSite
    } else if (length(choices)) choices[[1L]] else NULL
    rv$pendingSite <- NULL
    updateSelectInput(session, "site", choices = choices, selected = selected)
  }, ignoreInit = FALSE)

  output$siteBio <- renderUI({
    req(input$site)
    bio <- site_bio(input$site)
    if (is.null(bio)) return(NULL)
    div(class = "site-bio", bs_icon("info-circle-fill"), span(bio))
  })

  output$siteCards <- renderUI({
    if (is.null(SITE_INDEX) || !nrow(site_table)) return(NULL)
    div(class = "site-cards", lapply(seq_len(nrow(site_table)), function(i) {
      row <- site_table[i, , drop = FALSE]
      tags$a(
        class = "site-card", href = "#",
        onclick = sprintf(
          paste0("smtLoadStart('%s · loading…');",
                 "Shiny.setInputValue('siteExplore','%s',{priority:'event'});",
                 "return false;"),
          gsub("'", "", row$name), row$site
        ),
        div(class = "sc-emoji", "\U0001F990"),
        div(
          class = "sc-body",
          div(class = "sc-name", tags$b(row$site), sprintf(" · %s", row$name)),
          div(
            class = "sc-meta",
            sprintf(
              "%s · %s · %s opportunities · %s count-eligible",
              row$state, TYPE_LAB[row$type] %||% row$type,
              inv_value(row$n_opportunities), inv_value(row$n_count_samples)
            )
          )
        )
      )
    }))
  })

  shinyjs::hide("mainTabsWrap")

  ingest <- function(bundle, label) {
    checked <- inv_validate_bundle(bundle)
    if (!isTRUE(checked)) {
      session$sendCustomMessage("loadDone", list())
      showNotification(
        paste("The site bundle did not pass the Pass-9 contract:",
              inv_contract_reason(checked)),
        type = "error", duration = 14
      )
      return(invisible(FALSE))
    }
    bundle$meta$name <- site_name(bundle$meta$site)
    rv$bundle <- bundle
    rv$meta <- bundle$meta
    rv$opportunities <- bundle$opportunities
    rv$strata <- bundle$event_strata
    rv$taxa <- bundle$taxon_strata
    rv$label <- label
    rv$site <- bundle$meta$site

    shinyjs::show("mainTabsWrap")
    shinyjs::hide("splash")
    landing <- carry_tab()
    if (is.null(landing) || !nzchar(landing)) landing <- "overview"
    carry_tab(NULL)
    nav_select("tabs", landing)

    updateQueryString(
      paste0("?site=", utils::URLencode(rv$site, reserved = TRUE)),
      mode = "replace"
    )
    session$sendCustomMessage("invSaveSite", list(site = rv$site))
    session$sendCustomMessage("countUp", list())
    session$sendCustomMessage("loadDone", list())
    invisible(TRUE)
  }

  load_site <- function(site) {
    if (is.null(site) || !length(site) || !nzchar(site)) {
      session$sendCustomMessage("loadDone", list())
      return(invisible())
    }
    bundle <- load_site_bundle(site)
    if (is.null(bundle)) {
      session$sendCustomMessage("loadDone", list())
      showNotification(
        "That site does not have a reviewed Pass-9 bundle.",
        type = "error", duration = 12
      )
      return(invisible())
    }
    row <- site_table[site_table$site == site, , drop = FALSE]
    if (nrow(row) && !is.na(row$state) && !identical(input$stateSel, row$state)) {
      rv$pendingSite <- site
      updateSelectInput(session, "stateSel", selected = row$state)
    } else if (nrow(row)) {
      updateSelectInput(session, "site", selected = site)
    }
    ingest(bundle, sprintf("%s · %s", site, if (nrow(row)) row$name else site))
  }

  observeEvent(input$loadBtn, load_site(input$site))
  observeEvent(input$siteExplore, load_site(input$siteExplore))
  observeEvent(input$recentPick, load_site(input$recentPick))

  observeEvent(input$changeSite, {
    carry_tab(input$tabs)
    rv$bundle <- NULL
    rv$meta <- NULL
    rv$opportunities <- NULL
    rv$strata <- NULL
    rv$taxa <- NULL
    rv$label <- NULL
    rv$site <- NULL
    shinyjs::hide("mainTabsWrap")
    shinyjs::show("splash")
    updateQueryString("?", mode = "replace")
    session$sendCustomMessage("kickMaps", list())
  })

  valid_site <- function(code) {
    !is.null(code) && length(code) == 1L && nzchar(code) && code %in% site_table$site
  }
  observeEvent(input$invLastSite, once = TRUE, ignoreNULL = FALSE, {
    query <- tryCatch(
      parseQueryString(session$clientData$url_search %||% ""),
      error = function(e) list()
    )
    target <- if (valid_site(query$site)) query$site else {
      saved <- input$invLastSite %||% ""
      if (valid_site(saved)) saved else NULL
    }
    if (is.null(target)) return(invisible())
    session$sendCustomMessage("smtLoadStart", list(label = paste0(target, " · loading…")))
    load_site(target)
  })

  observeEvent(input$invRecents, ignoreNULL = FALSE, {
    raw <- input$invRecents %||% ""
    codes <- trimws(unlist(strsplit(raw, ",", fixed = TRUE)))
    codes <- unique(codes[nzchar(codes) & codes %in% site_table$site])
    recent_codes(head(codes, 4L))
  })

  output$recentsStrip <- renderUI({
    codes <- recent_codes()
    if (!length(codes)) return(NULL)
    div(
      class = "recents-strip",
      tags$span(class = "recents-lab", bs_icon("clock-history"),
                " Recently viewed:"),
      lapply(codes, function(code) {
        row <- site_table[site_table$site == code, , drop = FALSE]
        name <- if (nrow(row)) gsub("'", "", row$name) else code
        tags$a(
          href = "#", class = "recent-chip", title = name,
          onclick = sprintf(
            paste0("smtLoadStart('%s · loading…');",
                   "Shiny.setInputValue('recentPick','%s',{priority:'event'});",
                   "return false;"),
            name, code
          ),
          code
        )
      })
    )
  })

  observeEvent(input$help, {
    showModal(modalDialog(
      title = tagList(bs_icon("layers"), " How to read My Little Inverts"),
      easyClose = TRUE,
      tags$ol(
        tags$li(tags$b("Start with opportunities."),
                " A field row stays visible even when collection or processing did not yield a quantitative record."),
        tags$li(tags$b("Keep the exact stratum."),
                " Compare events only after fixing water type, habitat, and sampler."),
        tags$li(tags$b("Read each denominator."),
                " Count, density, composition, and taxon support can use different eligible sample sets."),
        tags$li(tags$b("Treat EPT descriptively."),
                " Unknown-order counts remain in the composition denominator; no condition class is inferred."),
        tags$li(tags$b("Keep missing distinct from zero."),
                paste(
                  " Only a usable laboratory total reported as zero receives the reported-zero support flag.",
                  "That flag can overlap an area- or density-unavailable primary status."
                ))
      ),
      footer = modalButton("Got it")
    ))
  })

  observeEvent(input$goStrata, nav_select("tabs", "strata"))
  observeEvent(input$goTaxa, nav_select("tabs", "taxa"))
  observeEvent(input$goNetwork, nav_select("tabs", "network"))
  observeEvent(input$goQA, nav_select("tabs", "qa"))

  # ---- hero and overview -------------------------------------------------
  output$heroStats <- renderUI({
    meta <- rv$meta
    if (is.null(meta)) return(NULL)
    hero <- function(value, label, icon, tone = "navy") {
      value <- num(value)
      missing <- length(value) != 1L || !is.finite(value)
      div(
        class = paste0("hero-stat hero-", tone,
                       if (missing) " hero-grayed" else ""),
        div(class = "hs-icon", bs_icon(icon)),
        div(
          if (missing) div(class = "hs-v", "n/a") else
            div(class = "hs-v count-up", `data-target` = value, "0"),
          div(class = "hs-l", label)
        )
      )
    }
    div(
      class = "hero-band",
      div(
        class = "hero-title", bs_icon("water"), tags$b(rv$label),
        actionLink("changeSite", tagList(bs_icon("arrow-left-circle"),
                                         " change site"),
                   class = "hero-change"),
        downloadLink("reportPdf", tagList(bs_icon("file-earmark-pdf"),
                                           " field-first report"),
                     class = "hero-report"),
        downloadLink("reportCsv", tagList(bs_icon("file-earmark-spreadsheet"),
                                           " site summary"),
                     class = "hero-report")
      ),
      div(
        class = "hero-grid",
        hero(meta$n_opportunities, "field opportunities", "clipboard-data"),
        hero(meta$n_count_samples, "count-eligible", "123", "terra"),
        hero(meta$n_density_samples, "density-eligible", "rulers", "pine"),
        hero(meta$n_taxa_recorded, "mixed-rank taxa recorded", "bug-fill", "gold"),
        hero(meta$n_events, "collection events", "calendar3")
      )
    )
  })

  output$overviewStatusPlot <- renderPlotly({
    req(rv$opportunities)
    ledger <- inv_status_ledger(rv$opportunities)
    colors <- c(
      "#9aa8ac", "#7c8f95", "#8b6e4f", "#8b6b9c", "#d87858",
      "#d4a13a", "#c97654", "#3f9e6e", "#0e8f9c"
    )
    ledger$label <- factor(ledger$label, levels = rev(ledger$label))
    plotly::plot_ly(
      ledger, x = ~n, y = ~label, type = "bar", orientation = "h",
      marker = list(color = colors),
      customdata = ~meaning,
      hovertemplate = paste0(
        "%{y}<br><b>%{x}</b> opportunities<br>",
        "%{customdata}<extra></extra>"
      )
    ) %>%
      plotly_theme(legend = FALSE, left = 190L) %>%
      plotly::layout(
        xaxis = list(title = "Field opportunities", rangemode = "tozero"),
        yaxis = list(title = ""), showlegend = FALSE
      )
  })

  overview_timeline <- reactive({
    req(rv$opportunities)
    opportunities <- rv$opportunities
    dates <- suppressWarnings(as.Date(substr(as.character(opportunities$collectDate),
                                             1L, 10L)))
    year <- ifelse(is.na(dates), "Date unavailable", format(dates, "%Y"))
    out <- aggregate(
      rep(1L, nrow(opportunities)),
      list(year = year, record_status = opportunities$record_status),
      sum
    )
    names(out)[[3L]] <- "n"
    out$label <- INV_STATUS_META$label[
      match(out$record_status, INV_STATUS_META$record_status)
    ]
    out
  })

  output$overviewTimeline <- renderPlotly({
    timeline <- overview_timeline()
    plotly::plot_ly(
      timeline, x = ~year, y = ~n, color = ~label, type = "bar",
      colors = c("#0e8f9c", "#3f9e6e", "#d4a13a", "#c97654", "#8b6b9c",
                 "#8b6e4f", "#7c8f95", "#9aa8ac", "#60757b"),
      hovertemplate = "%{x}<br>%{fullData.name}: %{y}<extra></extra>"
    ) %>%
      plotly_theme() %>%
      plotly::layout(
        barmode = "stack", xaxis = list(title = "Collection year"),
        yaxis = list(title = "Field opportunities", rangemode = "tozero")
      )
  })

  output$overviewTimelineNote <- renderUI({
    req(rv$opportunities)
    missing_date <- sum(is.na(suppressWarnings(as.Date(substr(
      as.character(rv$opportunities$collectDate), 1L, 10L
    )))))
    div(
      class = "denominator-note compact-note", bs_icon("info-circle"),
      sprintf(
        "%s opportunities are shown. %s have no usable collection date and remain in a separate category.",
        inv_value(nrow(rv$opportunities)), inv_value(missing_date)
      )
    )
  })

  output$siteNarrative <- renderUI({
    req(rv$meta, rv$opportunities)
    processing <- inv_processing_count_counts(rv$opportunities)
    rank_text <- rv$meta$taxonomic_ranks %||% "rank unavailable"
    tags$ul(
      class = "insight-list field-first-story",
      tags$li(HTML(sprintf(
        "NEON recorded <b>%s field opportunities</b> at this site across <b>%s events</b> (%s).",
        inv_value(rv$meta$n_opportunities), inv_value(rv$meta$n_events),
        inv_year_label(rv$meta)
      ))),
      tags$li(HTML(sprintf(
        "<b>%s</b> samples meet the count denominator; <b>%s</b> also have usable benthic area for density.",
        inv_value(rv$meta$n_count_samples), inv_value(rv$meta$n_density_samples)
      ))),
      tags$li(HTML(sprintf(
        "<b>%s</b> practical field opportunities have a per-sample processing record but no taxonomy outcome; <b>%s</b> count-eligible samples are explicitly reported as zero.",
        inv_value(processing[["processed_no_taxonomy"]]),
        inv_value(rv$meta$n_reported_zero_count)
      ))),
      tags$li(HTML(sprintf(
        "<b>%s</b> opportunities lack one or more exact-stratum fields and remain visible outside quantitative event strata; sampling-practicality and collection-method flags remain available separately from primary status.",
        inv_value(rv$meta$n_unstratifiable)
      ))),
      tags$li(HTML(sprintf(
        "The record contains <b>%s distinct taxa</b> across retained identification ranks: %s.",
        inv_value(rv$meta$n_taxa_recorded), htmltools::htmlEscape(rank_text)
      ))),
      tags$li(paste(
        "EPT summaries describe recorded mayfly, stonefly, and caddisfly composition.",
        "They are not a site condition classification, and unknown-order counts stay in the denominator."
      ))
    )
  })

  # ---- exact-stratum selectors ------------------------------------------
  observeEvent(rv$strata, {
    strata <- rv$strata
    if (is.null(strata) || !nrow(strata)) return()
    choices <- sort(unique(as.character(strata$aquaticSiteType)))
    updateSelectInput(session, "stratumAquaticType", choices = choices,
                      selected = choices[[1L]])
    updateSelectizeInput(
      session, "taxonStratum", choices = inv_stratum_choices(strata),
      selected = as.character(strata$stratum_key[[1L]]), server = TRUE
    )
  })

  observeEvent(list(rv$strata, input$stratumAquaticType), {
    strata <- rv$strata
    if (is.null(strata) || !nrow(strata) || is.null(input$stratumAquaticType)) return()
    part <- strata[strata$aquaticSiteType == input$stratumAquaticType, , drop = FALSE]
    choices <- sort(unique(as.character(part$habitatType)))
    updateSelectInput(session, "stratumHabitat", choices = choices,
                      selected = if (length(choices)) choices[[1L]] else NULL)
  }, ignoreInit = TRUE)

  observeEvent(list(rv$strata, input$stratumAquaticType, input$stratumHabitat), {
    strata <- rv$strata
    if (is.null(strata) || !nrow(strata) || is.null(input$stratumAquaticType) ||
        is.null(input$stratumHabitat)) return()
    part <- strata[
      strata$aquaticSiteType == input$stratumAquaticType &
        strata$habitatType == input$stratumHabitat, , drop = FALSE
    ]
    choices <- sort(unique(as.character(part$samplerType)))
    updateSelectInput(session, "stratumSampler", choices = choices,
                      selected = if (length(choices)) choices[[1L]] else NULL)
  }, ignoreInit = TRUE)

  selected_strata <- reactive({
    req(rv$strata, input$stratumAquaticType, input$stratumHabitat,
        input$stratumSampler)
    out <- rv$strata[
      rv$strata$aquaticSiteType == input$stratumAquaticType &
        rv$strata$habitatType == input$stratumHabitat &
        rv$strata$samplerType == input$stratumSampler, , drop = FALSE
    ]
    out$plot_date <- suppressWarnings(as.Date(out$collectDate_min))
    out[order(out$plot_date, out$eventID), , drop = FALSE]
  })

  output$stratumDenominators <- renderUI({
    strata <- selected_strata()
    div(
      class = "denominator-grid",
      div(class = "denominator-card",
          tags$b(inv_value(sum(strata$n_opportunities))),
          span(" field opportunities")),
      div(class = "denominator-card",
          tags$b(inv_value(sum(strata$n_count_samples))),
          span(" count-eligible samples")),
      div(class = "denominator-card",
          tags$b(inv_value(sum(strata$n_composition_samples))),
          span(" positive-total composition samples")),
      div(class = "denominator-card",
          tags$b(inv_value(sum(strata$n_density_samples))),
          span(" density-eligible samples")),
      div(class = "denominator-explain",
          bs_icon("info-circle"),
          "Totals summarize the selected method family across events; plotted values remain one exact event-stratum per point.")
    )
  })

  output$stratumDensityPlot <- renderPlotly({
    strata <- selected_strata()
    keep <- is.finite(num(strata$mean_sample_density_m2)) & !is.na(strata$plot_date)
    if (!any(keep)) return(note_plot(
      "No density-eligible event strata for this water type, habitat, and sampler."
    ))
    data <- strata[keep, , drop = FALSE]
    data$hover <- sprintf(
      paste0("%s<br>%s · %s · %s<br>",
             "mean %.1f /m² · n density = %d<br>",
             "n count = %d · n opportunities = %d"),
      data$eventID, data$aquaticSiteType, data$habitatType, data$samplerType,
      data$mean_sample_density_m2, data$n_density_samples,
      data$n_count_samples, data$n_opportunities
    )
    plotly::plot_ly(
      data, x = ~plot_date, y = ~mean_sample_density_m2,
      type = "scatter", mode = "lines+markers", text = ~hover,
      hovertemplate = "%{text}<extra></extra>",
      line = list(color = DDL$teal, width = 2),
      marker = list(color = DDL$teal, size = 9),
      error_y = list(
        type = "data", array = num(data$se_sample_density_m2),
        visible = TRUE, color = DDL$muted, thickness = 1.2
      )
    ) %>%
      plotly_theme(legend = FALSE) %>%
      plotly::layout(
        xaxis = list(title = "Collection event date"),
        yaxis = list(title = "Mean sample density (individuals / m²)",
                     rangemode = "tozero"),
        showlegend = FALSE
      )
  })

  output$stratumCompositionPlot <- renderPlotly({
    strata <- selected_strata()
    keep <- !is.na(strata$plot_date) &
      (is.finite(num(strata$mean_sample_pct_ept_of_all_estimated_count)) |
         is.finite(num(strata$mean_sample_pct_order_classified_estimated_count)))
    if (!any(keep)) return(note_plot(
      "No positive-total composition samples for this method family."
    ))
    data <- strata[keep, , drop = FALSE]
    plotly::plot_ly(data, x = ~plot_date) %>%
      plotly::add_lines(
        y = ~mean_sample_pct_ept_of_all_estimated_count,
        name = "EPT share", line = list(color = DDL$teal, width = 2.5),
        customdata = ~n_composition_samples,
        hovertemplate = paste0(
          "%{x|%Y-%m-%d}<br>EPT share %{y:.1f}%<br>",
          "composition n = %{customdata}<extra></extra>"
        )
      ) %>%
      plotly::add_lines(
        y = ~mean_sample_pct_order_classified_estimated_count,
        name = "Order classified", line = list(color = DDL$gold, width = 2,
                                                 dash = "dot"),
        customdata = ~n_composition_samples,
        hovertemplate = paste0(
          "%{x|%Y-%m-%d}<br>order classified %{y:.1f}%<br>",
          "composition n = %{customdata}<extra></extra>"
        )
      ) %>%
      plotly_theme() %>%
      plotly::layout(
        xaxis = list(title = "Collection event date"),
        yaxis = list(title = "Mean sample share", ticksuffix = "%",
                     range = c(0, 100))
      )
  })

  strata_display <- reactive({
    data <- selected_strata()
    keep <- c(
      "eventID", "collectDate_min", "aquaticSiteType", "habitatType",
      "samplerType", "n_opportunities", "n_count_samples",
      "n_composition_samples", "n_density_samples", "n_reported_zero_count",
      "mean_sample_density_m2", "se_sample_density_m2",
      "mean_sample_taxa_observed", "mean_sample_ept_taxa_observed",
      "mean_sample_pct_ept_of_all_estimated_count",
      "mean_sample_pct_order_classified_estimated_count"
    )
    data[, keep, drop = FALSE]
  })

  output$strataTable <- DT::renderDT(dt(strata_display(), page_length = 10L))
  output$strataCsv <- downloadHandler(
    filename = function() inv_safe_filename(rv$site %||% "site", "event-strata"),
    content = function(file) write.csv(strata_display(), file, row.names = FALSE,
                                       na = "")
  )

  # ---- taxon records -----------------------------------------------------
  selected_taxa <- reactive({
    req(rv$taxa, input$taxonStratum)
    inv_taxa_for_stratum(rv$taxa, input$taxonStratum)
  })

  output$taxonDenominators <- renderUI({
    taxa <- selected_taxa()
    stratum <- rv$strata[rv$strata$stratum_key == input$taxonStratum, , drop = FALSE]
    if (!nrow(stratum)) return(div(class = "denominator-note", "Stratum unavailable."))
    order_support <- stratum$mean_sample_pct_order_classified_estimated_count[[1L]]
    div(
      class = "denominator-note taxon-boundary", bs_icon("info-circle-fill"),
      HTML(sprintf(
        paste0(
          "<b>%s</b> taxon rows · support denominator <b>%s count-eligible samples</b> · ",
          "density denominator <b>%s samples with usable area</b> · ",
          "mean order-classified composition <b>%s</b>. ",
          "A missing taxonomy record is unknown; it is never zero-filled."
        ),
        inv_value(nrow(taxa)), inv_value(stratum$n_count_samples[[1L]]),
        inv_value(stratum$n_density_samples[[1L]]),
        if (is.finite(num(order_support))) inv_value(order_support, 1L, "%") else
          "Unavailable"
      ))
    )
  })

  top_taxa <- function(taxa, n = 24L) {
    if (!nrow(taxa)) return(taxa)
    head(taxa, n)
  }

  output$taxonSupportPlot <- renderPlotly({
    taxa <- top_taxa(selected_taxa())
    if (!nrow(taxa)) return(note_plot("No positive taxon records in this stratum."))
    taxa$taxon_label <- factor(taxa$taxon_label, levels = rev(taxa$taxon_label))
    color <- ifelse(inv_true(taxa$is_ept), DDL$teal, "#94a7ad")
    plotly::plot_ly(
      taxa, x = ~support_pct, y = ~taxon_label, type = "bar", orientation = "h",
      marker = list(color = color), customdata = ~n_count_eligible_samples,
      hovertemplate = paste0(
        "%{y}<br>support %{x:.1f}%<br>",
        "count-eligible denominator = %{customdata}<extra></extra>"
      )
    ) %>%
      plotly_theme(legend = FALSE, left = 220L) %>%
      plotly::layout(
        xaxis = list(title = "Samples with positive count / count-eligible samples",
                     ticksuffix = "%", range = c(0, 100)),
        yaxis = list(title = ""), showlegend = FALSE
      )
  })

  output$taxonCountPlot <- renderPlotly({
    taxa <- selected_taxa()
    if (!nrow(taxa)) return(note_plot("No positive taxon records in this stratum."))
    taxa <- taxa[order(-num(taxa$total_estimated_count)), , drop = FALSE]
    taxa <- head(taxa, 24L)
    taxa$taxon_label <- factor(taxa$taxon_label, levels = rev(taxa$taxon_label))
    plotly::plot_ly(
      taxa, x = ~total_estimated_count, y = ~taxon_label,
      type = "bar", orientation = "h", marker = list(color = DDL$gold),
      customdata = ~n_count_eligible_samples,
      hovertemplate = paste0(
        "%{y}<br>expanded count sum %{x:,.1f}<br>",
        "count-eligible denominator = %{customdata}<br>",
        "collection record, not a population count<extra></extra>"
      )
    ) %>%
      plotly_theme(legend = FALSE, left = 220L) %>%
      plotly::layout(
        xaxis = list(title = "Expanded laboratory count sum", rangemode = "tozero"),
        yaxis = list(title = ""), showlegend = FALSE
      )
  })

  taxa_display <- reactive({
    taxa <- selected_taxa()
    keep <- c(
      "scientificName", "taxonRank", "acceptedTaxonID", "order", "family",
      "is_ept", "order_classified", "n_count_eligible_samples",
      "n_density_eligible_samples", "n_samples_present", "support_pct",
      "total_estimated_count", "mean_sample_density_m2",
      "median_sample_density_m2"
    )
    taxa[, keep, drop = FALSE]
  })
  output$taxaTable <- DT::renderDT(dt(taxa_display(), page_length = 12L))
  output$taxaCsv <- downloadHandler(
    filename = function() inv_safe_filename(rv$site %||% "site", "taxon-stratum"),
    content = function(file) write.csv(taxa_display(), file, row.names = FALSE,
                                       na = "")
  )

  # ---- network effort and records ---------------------------------------
  network_data <- reactive({
    req(SITE_INDEX)
    x <- input$networkX %||% "n_opportunities"
    y <- input$networkY %||% "n_count_samples"
    if (!x %in% names(inv_comparison_choices)) x <- "n_opportunities"
    if (!y %in% names(inv_comparison_choices)) y <- "n_count_samples"
    data <- SITE_INDEX
    data$name <- site_name_vec(data$site)
    data$x_value <- num(data[[x]])
    data$y_value <- num(data[[y]])
    attr(data, "x_key") <- x
    attr(data, "y_key") <- y
    data
  })

  output$networkBoundary <- renderUI({
    data <- network_data()
    div(
      class = "denominator-note compact-note", bs_icon("shield-check"),
      sprintf(
        "%s versus %s. These are effort/record counts; position does not imply ecological condition.",
        inv_comparison_label(attr(data, "x_key")),
        inv_comparison_label(attr(data, "y_key"))
      )
    )
  })

  output$networkPlot <- renderPlotly({
    data <- network_data()
    x_key <- attr(data, "x_key")
    y_key <- attr(data, "y_key")
    sizes <- 10 + 14 * sqrt(pmax(0, data$n_opportunities) /
                            max(1, data$n_opportunities, na.rm = TRUE))
    plotly::plot_ly(
      data, x = ~x_value, y = ~y_value, type = "scatter", mode = "markers",
      color = ~aquaticSiteType, colors = TYPE_COL,
      marker = list(size = sizes, opacity = 0.82,
                    line = list(color = "#ffffff", width = 1)),
      text = ~paste0(
        "<b>", site, " · ", name, "</b><br>",
        inv_comparison_label(x_key), ": ", x_value, "<br>",
        inv_comparison_label(y_key), ": ", y_value, "<br>",
        "Water type: ", aquaticSiteType
      ),
      hovertemplate = "%{text}<extra></extra>"
    ) %>%
      plotly_theme() %>%
      plotly::layout(
        xaxis = list(title = inv_comparison_label(x_key), rangemode = "tozero"),
        yaxis = list(title = inv_comparison_label(y_key), rangemode = "tozero")
      )
  })

  network_display <- reactive({
    data <- SITE_INDEX
    data$name <- site_name_vec(data$site)
    data[, INV_NETWORK_EXPORT_COLUMNS, drop = FALSE]
  })
  output$networkTable <- DT::renderDT(dt(network_display(), page_length = 15L))
  output$networkCsv <- downloadHandler(
    filename = "neon-inverts-network-effort-records.csv",
    content = function(file) write.csv(network_display(), file, row.names = FALSE,
                                       na = "")
  )

  observe({
    updateSelectizeInput(
      session, "searchTaxon",
      choices = c(stats::setNames("", ""), search_taxon_choices()),
      selected = "", server = TRUE
    )
  })

  network_taxon <- reactive({
    name <- input$searchTaxon %||% ""
    if (!nzchar(name) || is.null(SEARCH_TAXA)) return(NULL)
    rows <- SEARCH_TAXA[SEARCH_TAXA$scientificName == name, , drop = FALSE]
    if (!nrow(rows)) return(rows)
    rows$site_name <- site_name_vec(rows$siteID)
    rows$taxon_label <- inv_taxon_label(rows$scientificName, rows$taxonRank,
                                        rows$is_ept)
    rows[order(rows$siteID, rows$eventID, rows$aquaticSiteType,
               rows$habitatType, rows$samplerType), , drop = FALSE]
  })

  output$networkTaxonNote <- renderUI({
    name <- input$searchTaxon %||% ""
    if (!nzchar(name)) return(div(
      class = "search-empty", bs_icon("search"),
      " Choose a taxon to see the exact strata where a positive count was recorded."
    ))
    rows <- network_taxon()
    if (is.null(rows) || !nrow(rows)) return(div(
      class = "search-empty", " No exact-stratum records are indexed for this name."
    ))
    div(
      class = "denominator-note compact-note", bs_icon("info-circle"),
      sprintf(
        "%s exact-stratum records across %s sites. Support denominators stay attached to each row; rows are not combined into a site ranking.",
        inv_value(nrow(rows)), inv_value(length(unique(rows$siteID)))
      )
    )
  })

  output$networkTaxonTable <- DT::renderDT({
    rows <- network_taxon()
    if (is.null(rows) || !nrow(rows)) return(dt(data.frame(
      Note = "Choose a taxon to inspect exact-stratum records.",
      stringsAsFactors = FALSE
    )))
    keep <- c(
      "siteID", "site_name", "eventID", "aquaticSiteType", "habitatType",
      "samplerType", "scientificName", "taxonRank", "order",
      "n_count_eligible_samples", "n_samples_present", "support_pct"
    )
    dt(rows[, keep, drop = FALSE], page_length = 15L)
  })

  # ---- QC and provenance -------------------------------------------------
  output$statusDefinitions <- DT::renderDT({
    req(rv$opportunities)
    ledger <- inv_status_ledger(rv$opportunities)
    dt(ledger[c("label", "n", "meaning", "count_denominator",
                "density_denominator")], page_length = 9L)
  })

  output$qcReconciliation <- renderUI({
    req(rv$bundle)
    reconciliation <- rv$bundle$qc$reconciliation %||% list()
    if (!length(reconciliation)) return(div(
      class = "qa-empty", "Reconciliation receipt unavailable."
    ))
    receipt_item <- function(label, value) {
      display <- if (is.logical(value) && length(value) == 1L) {
        if (isTRUE(value)) "Yes" else "No"
      } else inv_value(value)
      div(class = "qc-reconciliation-item", tags$b(display), span(label))
    }
    scalar_names <- setdiff(names(reconciliation), "source_qc_rows_retained")
    retained <- reconciliation$source_qc_rows_retained
    retained_labels <- c(
      field = "retained field QC rows",
      per_sample = "retained per-sample QC rows",
      taxonomy_processed = "retained taxonomy QC rows",
      issue_log = "retained issue-log rows"
    )
    source_rows <- rv$bundle$qc$source_rows
    source_labels <- c(
      collection_field_rows = "collection field rows",
      metabarcode_field_rows = "metabarcoding field rows",
      per_sample_rows = "per-sample rows",
      taxonomy_processed_rows = "taxonomy rows",
      issue_log_rows = "source issue-log rows"
    )
    div(
      class = "qc-reconciliation-wrap",
      div(
        class = "qc-reconciliation-grid",
        lapply(scalar_names, function(name) {
          receipt_item(gsub("_", " ", name), reconciliation[[name]])
        })
      ),
      h5(class = "qc-reconciliation-section-title", "Source-row receipt"),
      div(
        class = "qc-reconciliation-grid",
        lapply(names(source_labels), function(name) {
          receipt_item(source_labels[[name]], source_rows[[name]][[1L]])
        })
      ),
      h5(class = "qc-reconciliation-section-title",
         "Quality evidence retained verbatim"),
      div(
        class = "qc-reconciliation-grid",
        lapply(names(retained_labels), function(name) {
          receipt_item(retained_labels[[name]], retained[[name]])
        })
      )
    )
  })

  selected_qc_rows <- reactive({
    req(rv$bundle)
    layer <- input$qcLayer %||% "field"
    if (identical(layer, "issue_log")) {
      issues <- rv$bundle$qc$issue_log
      return(if (is.data.frame(issues)) issues else NULL)
    }
    source_quality <- rv$bundle$qc$source_quality
    if (!is.list(source_quality) || !layer %in% names(source_quality) ||
        !is.data.frame(source_quality[[layer]])) return(NULL)
    source_quality[[layer]]
  })

  output$qcSourceNote <- renderUI({
    req(rv$bundle)
    source_quality <- rv$bundle$qc$source_quality
    source_count <- if (is.list(source_quality)) {
      sum(vapply(source_quality, function(x) if (is.data.frame(x)) nrow(x) else 0L,
                 integer(1)))
    } else 0L
    issues <- rv$bundle$qc$issue_log
    issue_count <- if (is.data.frame(issues)) nrow(issues) else 0L
    div(
      class = "denominator-note", bs_icon("flag"),
      HTML(sprintf(
        paste0(
          "The source-quality inventory contains <b>%s</b> entries and the contextual issue log contains <b>%s</b> rows. ",
          "Field/per-sample <code>dataQF</code>, sorting checks, PDE/PTD, and taxonomy <code>qcChecked</code> are evidence for review—not automatic exclusion rules."
        ),
        inv_value(source_count), inv_value(issue_count)
      ))
    )
  })

  output$qcIssueTable <- DT::renderDT({
    rows <- selected_qc_rows()
    if (is.null(rows) || !nrow(rows)) return(dt(data.frame(
      Note = paste(
        "This quality evidence layer is absent or empty in the loaded bundle.",
        "No exclusion is inferred from that absence."
      ),
      stringsAsFactors = FALSE
    )))
    dt(rows, page_length = 12L)
  })

  output$opportunityTable <- DT::renderDT({
    req(rv$opportunities)
    dt(inv_opportunity_export(rv$opportunities), page_length = 15L)
  })

  output$metricContractTable <- DT::renderDT({
    req(rv$bundle)
    dt(rv$bundle$metric_contract, page_length = 14L)
  })

  output$provenanceTable <- DT::renderDT({
    req(rv$bundle)
    dt(inv_provenance_table(rv$bundle), page_length = 10L)
  })

  output$opportunityCsv <- downloadHandler(
    filename = function() inv_safe_filename(rv$site %||% "site", "opportunities"),
    content = function(file) write.csv(inv_opportunity_export(rv$opportunities),
                                       file, row.names = FALSE, na = "")
  )
  output$codebookCsv <- downloadHandler(
    filename = "neon-inverts-field-first-codebook.csv",
    content = function(file) write.csv(inv_codebook(), file, row.names = FALSE,
                                       na = "")
  )

  # ---- map ---------------------------------------------------------------
  output$nationalPicker <- leaflet::renderLeaflet({
    if (isTRUE(NO_DATA) || !nrow(site_table)) {
      return(leaflet::leaflet() %>%
        add_suite_basemap("CartoDB.Positron") %>%
        leaflet::setView(lng = -98, lat = 39, zoom = 3))
    }
    sizes <- 8 + 14 * sqrt(pmax(0, num(site_table$n_opportunities)) /
                           max(1, num(site_table$n_opportunities), na.rm = TRUE))
    popup <- vapply(seq_len(nrow(site_table)), function(i) {
      row <- site_table[i, , drop = FALSE]
      sprintf(
        paste0(
          "<div class='picker-popup'><b>%s · %s</b><br>",
          "%s · NEON %s · %s<br>",
          "<b>%s</b> field opportunities · <b>%s</b> count-eligible<br>",
          "<b>%s</b> events · <b>%s</b> exact strata<br>",
          "<button class='btn btn-sm btn-primary' onclick=\"smtLoadStart('%s · loading…');",
          "Shiny.setInputValue('siteExplore','%s',{priority:'event'});\">Explore</button></div>"
        ),
        row$site, row$name, TYPE_LAB[row$type] %||% row$type, row$domain,
        row$state, inv_value(row$n_opportunities), inv_value(row$n_count_samples),
        inv_value(row$n_events), inv_value(row$n_strata),
        gsub("'", "", row$name), row$site
      )
    }, character(1))
    leaflet::leaflet(site_table) %>%
      add_suite_basemap("CartoDB.Positron") %>%
      leaflet::addCircleMarkers(
        lng = ~lng, lat = ~lat, radius = sizes,
        color = ~type_col(type), fillColor = ~type_col(type),
        fillOpacity = 0.75, weight = 2, opacity = 0.95,
        popup = popup, label = ~paste(site, name),
        clusterOptions = leaflet::markerClusterOptions(
          showCoverageOnHover = FALSE, maxClusterRadius = 38
        )
      ) %>%
      leaflet::addLegend(
        position = "bottomright", colors = unname(TYPE_COL),
        labels = unname(TYPE_LAB[names(TYPE_COL)]), title = "Aquatic site type",
        opacity = 0.9
      ) %>%
      leaflet::fitBounds(lng1 = -170, lat1 = 17, lng2 = -64, lat2 = 72)
  })

  # ---- reports -----------------------------------------------------------
  output$reportPdf <- downloadHandler(
    filename = function() inv_safe_filename(rv$site %||% "site",
                                             "field-first-report", "pdf"),
    content = function(file) inv_report_pdf(file, rv$bundle, rv$site, rv$label)
  )

  output$reportCsv <- downloadHandler(
    filename = function() inv_safe_filename(rv$site %||% "site", "site-summary"),
    content = function(file) {
      req(rv$bundle)
      summary <- rv$bundle$site_summary
      provenance <- inv_provenance_table(rv$bundle)
      summary$source_release <- rv$bundle$provenance$source$release %||% NA_character_
      summary$source_sha256 <- rv$bundle$provenance$source$artifact_sha256 %||%
        NA_character_
      write.csv(summary, file, row.names = FALSE, na = "")
    }
  )

  # ---- about -------------------------------------------------------------
  output$aboutPanel <- renderUI({
    source <- if (!is.null(rv$bundle)) rv$bundle$provenance$source else
      SEARCH_INDEX$source %||% list()
    div(
      class = "about-wrap field-first-about",
      h3("My Little Inverts"),
      p(paste(
        "An unofficial field-first explorer for NEON Macroinvertebrate collection",
        "DP1.20120.001. It keeps field opportunities, processing states, exact",
        "collection strata, and mixed identification ranks visible."
      )),
      div(
        class = "honesty-box",
        h4(bs_icon("shield-check"), " Interpretation boundaries"),
        tags$ul(
          tags$li("A field opportunity is retained even when sampling is impractical or taxonomy is unavailable."),
          tags$li("A reported zero is a usable laboratory expanded total of zero; it is not a field-verified absence."),
          tags$li("Density is descriptive collection density within one exact event stratum, not a population estimate."),
          tags$li("Taxon support uses zero-fill only across count-valid processed samples in the same exact stratum."),
          tags$li("EPT composition is descriptive. Unknown-order counts stay in its denominator."),
          tags$li("Network views compare effort and records only; they do not rank ecological condition.")
        )
      ),
      h4("Source and release"),
      p(HTML(sprintf(
        paste0(
          "Public NEON <a href='https://data.neonscience.org/data-products/DP1.20120.001' ",
          "target='_blank' rel='noopener'>DP1.20120.001</a> · release <b>%s</b> · ",
          "provisional data <b>%s</b> · publication through <b>%s</b>."
        ),
        htmltools::htmlEscape(source$release %||% "Unavailable"),
        if (isTRUE(source$include_provisional)) "included" else "not included",
        htmltools::htmlEscape(source$publication_date_max %||% "Unavailable")
      ))),
      h4("Explore the NEON series"),
      div(class = "sibling-grid", lapply(SUITE_REGISTRY, function(item) {
        tags$a(
          class = paste("sib-card", if (identical(item$dpid, NEON_DPID)) "is-self" else ""),
          href = item$url, target = "_blank", rel = "noopener",
          div(class = "sib-emoji", item$emoji),
          div(div(class = "sib-name", item$name),
              div(class = "sib-tag", item$tag))
        )
      }))
    )
  })
}
