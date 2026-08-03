# ===========================================================================
# NEON My Little Inverts — field-first loaded experience
# ===========================================================================

inverts_poster <- function() {
  tags$section(
    class = "inverts-poster",
    `aria-labelledby` = "inverts-poster-title",
    div(class = "inv-poster-copy",
      div(class = "inv-poster-topline",
        div(class = "inv-poster-brand", "Desert Data Labs"),
        tags$nav(class = "inv-poster-nav", `aria-label` = "NEON Explorer Suite",
          tags$a(class = "inv-poster-suite-link",
            href = "https://tgilbert14.github.io/NEON-Driver-Cascade/",
            "Whole suite: ", tags$strong("Driver Cascade"),
            tags$span(`aria-hidden` = "true", "↗")))),
      div(class = "inv-poster-app", "NEON My Little Inverts · unofficial"),
      h1(id = "inverts-poster-title", `aria-label` = "What lives below the surface?",
        tags$span("What lives"), tags$em("below the surface?")),
      p(class = "inv-poster-promise",
        "Explore the aquatic invertebrates NEON recorded in stream, river, and lake-bottom samples."),
      tags$a(class = "inv-poster-cta", href = "#site-picker-start",
        onclick = "window.setTimeout(function(){var target=document.getElementById('site-picker-start');if(target){target.focus({preventScroll:true});}},0)",
        "Choose an aquatic site", tags$span(`aria-hidden` = "true", " ↓")),
      p(class = "inv-poster-note",
        "Public NEON DP1.20120.001 · collection records—not verified zeros, population counts, or water-quality scores.")),
    tags$figure(class = "inv-poster-art",
      tags$picture(
        tags$source(
          type = "image/webp",
          srcset = paste(
            paste0(asset_url("assets/inverts-living-poster-v2-840.webp"), " 840w,"),
            paste0(asset_url("assets/inverts-living-poster-v2.webp"), " 1672w")
          ),
          sizes = "(max-width: 700px) 100vw, 58vw"
        ),
        tags$img(
          src = asset_url("assets/inverts-living-poster-v2.png"),
          alt = paste(
            "Editorial screenprint of a mayfly nymph, a case-bearing caddisfly larva,",
            "a freshwater snail, and an aquatic crustacean among submerged stones",
            "and leaves beside field tags."
          ),
          width = "1672", height = "941", fetchpriority = "high",
          decoding = "async"
        )
      ),
      tags$figcaption(
        "Editorial illustration—not a field photograph or data record."
      )
    )
  )
}

ui <- bslib::page_fillable(
  theme = app_theme,
  title = NULL,
  window_title = "NEON My Little Inverts",
  fillable = FALSE,
  tags$head(
    tags$meta(name = "ddl-app-ready", content = APP_RELEASE_MARKER),
    tags$meta(name = "ddl-release-instance", content = RELEASE_INSTANCE_ID),
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(rel = "preconnect", href = "https://fonts.gstatic.com",
              crossorigin = NA),
    tags$link(
      rel = "stylesheet",
      href = paste0(
        "https://fonts.googleapis.com/css2?family=Rubik:",
        "wght@400;500;600;700;800&display=swap"
      )
    ),
    tags$link(rel = "stylesheet", href = asset_url("styles.css")),
    tags$link(rel = "stylesheet", href = asset_url("inverts.css")),
    tags$link(rel = "stylesheet", href = asset_url("poster.css")),
    tags$script(src = asset_url("app.js"))
  ),
  useShinyjs(),
  tags$a(class = "app-skip", href = "#site-picker-start",
         "Skip to aquatic site picker"),

  div(
    class = "top-bar",
    div(class = "top-bar-brand",
        tags$span(class = "tb-mark", "\U0001F990"),
        tags$span(class = "tb-title", "My Little Inverts")),
    div(class = "top-bar-actions",
        actionButton(
          "help", tagList(bs_icon("question-circle"), " How to read it"),
          class = "btn-outline-dark btn-sm tb-help"
        ),
        div(class = "tb-theme",
            tags$span(class = "tb-theme-lab", bs_icon("circle-half")),
            input_dark_mode(id = "colorMode", mode = "light")))
  ),

  div(
    id = "loadOverlay", class = "load-overlay",
    div(
      class = "load-card",
      div(class = "load-spin mascot-spin", MASCOT_CRITTER),
      div(class = "load-title", "Loading site records"),
      div(id = "loadSite", class = "load-site"),
      div(class = "load-bar"),
      div(class = "load-note",
          "Reading the opportunity ledger, exact strata, and taxon records.")
    )
  ),

  if (isTRUE(NO_DATA)) div(
    class = "synth-banner", bs_icon("exclamation-octagon-fill"),
    tags$span(HTML(paste0(
      "<b>No reviewed Pass-9 data bundle is available.</b> ",
      "The app remains closed to legacy bundle shapes."
    )))
  ),

  uiOutput("heroStats"),

  div(
    id = "splash",
    div(
      class = "splash splash-map",
      inverts_poster(),
      div(
        id = "site-picker-start", class = "picker-map-wrap", tabindex = "-1",
        `aria-label` = "Aquatic site picker",
        leafletOutput("nationalPicker", height = "440px")
      ),
      uiOutput("recentsStrip"),
      div(
        class = "select-panel",
        div(class = "sp-head", bs_icon("sliders"), " Or pick a site by name"),
        div(
          class = "sp-row",
          div(class = "sp-field",
              selectInput("stateSel", tagList(bs_icon("geo-alt-fill"), " State"),
                          choices = NULL, width = "100%")),
          div(class = "sp-field",
              selectInput("site", tagList(bs_icon("pin-map-fill"), " Site"),
                          choices = NULL, width = "100%"))
        ),
        uiOutput("siteBio"),
        actionButton(
          "loadBtn", tagList(bs_icon("water"), " Explore this site"),
          class = "btn-primary btn-lg load-btn sp-load",
          onclick = "smtLoadStart()"
        )
      ),
      tags$details(
        class = "site-browse",
        tags$summary(
          class = "site-browse-summary",
          tags$span(class = "sbs-label", bs_icon("list-ul"),
                    " Browse all 34 sites as a list"),
          tags$span(class = "sbs-chevron", bs_icon("chevron-down"))
        ),
        div(class = "site-browse-body", uiOutput("siteCards"))
      )
    )
  ),

  div(
    id = "mainTabsWrap", class = "main-tabs-wrap",
    div(
      class = "hero-caveat exact-grain-caveat", bs_icon("layers-half"),
      tags$span(HTML(paste0(
        "Every quantitative view keeps the exact <b>site × event × water type × ",
        "habitat × sampler</b> stratum visible. Missing, unknown, and reported ",
        "zero are separate. Density appears only with usable benthic area and is ",
        "never pooled into a cross-site biological ranking."
      )))
    ),
    navset_card_tab(
      id = "tabs",
      nav_panel(
        title = tagList(bs_icon("compass"), " Overview"), value = "overview",
        div(
          class = "home-nav field-first-nav",
          actionButton("goStrata", tagList(bs_icon("layers"),
            div("Event strata"), tags$small("same habitat + sampler")),
            class = "home-btn home-btn-star"),
          actionButton("goTaxa", tagList(bs_icon("bug-fill"),
            div("Taxon records"), tags$small("support + mixed rank")),
            class = "home-btn"),
          actionButton("goNetwork", tagList(bs_icon("globe-americas"),
            div("Network effort"), tags$small("opportunities + records")),
            class = "home-btn"),
          actionButton("goQA", tagList(bs_icon("clipboard-data"),
            div("QC + provenance"), tags$small("nothing silently dropped")),
            class = "home-btn")
        ),
        layout_columns(
          col_widths = breakpoints(sm = 12, lg = c(5, 7)),
          card(
            full_screen = TRUE,
            card_head("diagram-3", "Primary processing-status ledger",
              info_pop("One field row, one primary status",
                p("Every non-metabarcoding field row remains visible in exactly one dominant processing state."),
                p("Support flags can overlap that status. For example, a usable laboratory zero without benthic area has an area-unavailable primary status and a reported-zero support flag."),
                p("Processed samples without taxonomy remain unknown; they are never converted to zero."))),
            spin(plotlyOutput("overviewStatusPlot", height = "410px"))
          ),
          card(
            full_screen = TRUE,
            card_head("calendar3", "Opportunities through time"),
            uiOutput("overviewTimelineNote"),
            spin(plotlyOutput("overviewTimeline", height = "360px"))
          )
        ),
        card(card_head("journal-text", "What this site record contains"),
             uiOutput("siteNarrative"))
      ),

      nav_panel(
        title = tagList(bs_icon("layers"), " Event strata"), value = "strata",
        div(class = "tab-head",
            div(class = "tab-head-text",
                h4("Compare like with like"),
                p(paste(
                  "Choose one water type, habitat, and sampler family.",
                  "Points then vary by event only; no modal-method or pooled-site shortcut is used."
                )),
                span(class = "scope-chip scope-site", bs_icon("geo-alt-fill"),
                     " One site · one method family"))),
        div(
          class = "stratum-filter-grid",
          selectInput("stratumAquaticType", "Water type", choices = NULL),
          selectInput("stratumHabitat", "Habitat", choices = NULL),
          selectInput("stratumSampler", "Sampler", choices = NULL)
        ),
        uiOutput("stratumDenominators"),
        layout_columns(
          col_widths = breakpoints(sm = 12, lg = c(6, 6)),
          card(
            full_screen = TRUE,
            card_head("rulers", "Collection density by event",
              info_pop("Density denominator",
                p("Each point is the arithmetic mean of density-eligible samples in one exact stratum."),
                p("The interval is the sample standard error when at least two density-eligible samples exist; it is not population uncertainty."))),
            spin(plotlyOutput("stratumDensityPlot", height = "390px"))
          ),
          card(
            full_screen = TRUE,
            card_head("pie-chart", "Descriptive EPT composition by event",
              info_pop("Composition denominator",
                p("The EPT share is averaged across positive-total count-eligible samples."),
                p("Counts with unknown order stay in the denominator. Order-classified share is shown beside EPT as support for interpretation."))),
            spin(plotlyOutput("stratumCompositionPlot", height = "390px"))
          )
        ),
        card(
          full_screen = TRUE,
          card_head("table", "Exact event-stratum rows"),
          div(class = "download-row",
              downloadButton("strataCsv", "Download selected strata (CSV)",
                             class = "btn-outline-dark btn-sm")),
          DT::DTOutput("strataTable")
        )
      ),

      nav_panel(
        title = tagList(bs_icon("bug-fill"), " Taxon records"), value = "taxa",
        div(class = "tab-head",
            div(class = "tab-head-text",
                h4("Taxa inside one exact stratum"),
                p(paste(
                  "Support is zero-filled only across count-eligible processed samples.",
                  "Identification rank stays attached to every name."
                )),
                span(class = "scope-chip scope-site", bs_icon("layers"),
                     " No site-wide density pooling"))),
        selectizeInput(
          "taxonStratum", "Event · water type · habitat · sampler",
          choices = NULL, width = "100%",
          options = list(placeholder = "Choose an exact stratum")
        ),
        uiOutput("taxonDenominators"),
        layout_columns(
          col_widths = breakpoints(sm = 12, lg = c(6, 6)),
          card(
            full_screen = TRUE,
            card_head("record-circle", "Sample support"),
            spin(plotlyOutput("taxonSupportPlot", height = "440px"))
          ),
          card(
            full_screen = TRUE,
            card_head("123", "Expanded laboratory counts"),
            spin(plotlyOutput("taxonCountPlot", height = "440px"))
          )
        ),
        card(
          full_screen = TRUE,
          card_head("table", "Taxon-stratum records"),
          div(class = "download-row",
              downloadButton("taxaCsv", "Download this stratum (CSV)",
                             class = "btn-outline-dark btn-sm")),
          DT::DTOutput("taxaTable")
        )
      ),

      nav_panel(
        title = tagList(bs_icon("globe-americas"), " Network effort"),
        value = "network",
        div(class = "tab-head",
            div(class = "tab-head-text",
                h4("Across NEON: effort and records only"),
                p(paste(
                  "Compare how much was attempted and processed.",
                  "No raw density or condition ranking is available in this view."
                )),
                span(class = "scope-chip scope-net", bs_icon("shield-check"),
                     " 34-site descriptive inventory"))),
        div(
          class = "network-axis-grid",
          selectInput("networkX", "Horizontal axis",
                      choices = stats::setNames(names(inv_comparison_choices),
                                                unname(inv_comparison_choices)),
                      selected = "n_opportunities"),
          selectInput("networkY", "Vertical axis",
                      choices = stats::setNames(names(inv_comparison_choices),
                                                unname(inv_comparison_choices)),
                      selected = "n_count_samples")
        ),
        card(
          full_screen = TRUE,
          card_head("scatter-chart", "Site effort and record counts"),
          uiOutput("networkBoundary"),
          spin(plotlyOutput("networkPlot", height = "500px"))
        ),
        card(
          full_screen = TRUE,
          card_head("table", "Network effort table"),
          div(class = "download-row",
              downloadButton("networkCsv", "Download network table (CSV)",
                             class = "btn-outline-dark btn-sm")),
          DT::DTOutput("networkTable")
        ),
        card(
          full_screen = TRUE,
          card_head("search", "Find a recorded taxon across exact strata"),
          selectizeInput("searchTaxon", "Taxon name", choices = NULL, width = "100%",
                         options = list(placeholder = "Type a taxon name")),
          uiOutput("networkTaxonNote"),
          DT::DTOutput("networkTaxonTable")
        )
      ),

      nav_panel(
        title = tagList(bs_icon("clipboard-data"), " QC + provenance"),
        value = "qa",
        div(class = "tab-head",
            div(class = "tab-head-text",
                h4("Audit the record behind every chart"),
                p(paste(
                  "Quality fields and processing states are contextual evidence.",
                  "They are displayed and retained; the app does not silently filter a row because a flag exists."
                )),
                span(class = "scope-chip scope-site", bs_icon("eye"),
                     " Display, retain, explain"))),
        layout_columns(
          col_widths = breakpoints(sm = 12, lg = c(6, 6)),
          card(card_head("diagram-3", "Primary-status definitions"),
               DT::DTOutput("statusDefinitions")),
          card(card_head("check2-square", "Bundle reconciliation"),
               uiOutput("qcReconciliation"))
        ),
        card(
          full_screen = TRUE,
          card_head("flag", "Source quality context"),
          uiOutput("qcSourceNote"),
          selectInput(
            "qcLayer", "Quality evidence layer",
            choices = c(
              "Field quality fields" = "field",
              "Per-sample sorting and comparison fields" = "per_sample",
              "Taxonomy quality fields" = "taxonomy_processed",
              "Product issue log (contextual annotations)" = "issue_log"
            ),
            selected = "field", width = "100%"
          ),
          DT::DTOutput("qcIssueTable")
        ),
        card(
          full_screen = TRUE,
          card_head("list-check", "Complete opportunity ledger"),
          div(class = "download-row",
              downloadButton("opportunityCsv", "Download opportunities (CSV)",
                             class = "btn-outline-dark btn-sm"),
              downloadButton("codebookCsv", "Download codebook (CSV)",
                             class = "btn-outline-dark btn-sm")),
          DT::DTOutput("opportunityTable")
        ),
        layout_columns(
          col_widths = breakpoints(sm = 12, lg = c(7, 5)),
          card(card_head("braces", "Metric contract"),
               DT::DTOutput("metricContractTable")),
          card(card_head("fingerprint", "Source + build provenance"),
               DT::DTOutput("provenanceTable"))
        )
      ),

      nav_panel(
        title = tagList(bs_icon("info-circle"), " About"), value = "about",
        uiOutput("aboutPanel")
      )
    )
  ),

  div(
    class = "ddl-footer",
    div(tags$a(
      class = "custom-cta",
      href = paste0(
        "mailto:desertdatalabs@gmail.com?subject=",
        "NEON%20My%20Little%20Inverts"
      ),
      span(class = "hand", "\U0001F44B"),
      "Questions or feedback? Get in touch with Desert Data Labs."
    )),
    p(style = "margin-top:12px",
      HTML("Built by <strong>Desert Data Labs</strong> · Tucson, AZ · get in touch "),
      tags$a(
        href = paste0(
          "mailto:desertdatalabs@gmail.com?subject=",
          "NEON%20My%20Little%20Inverts"
        ),
        "desertdatalabs@gmail.com"
      )),
    p(style = "font-size:12px;opacity:.85",
      paste(
        "Data: NEON Macroinvertebrate collection (DP1.20120.001).",
        "Not affiliated with NEON, Battelle, or the NSF.",
        "An educational data-exploration tool."
      ))
  )
)
