library(shinydashboard)
library(shiny)
library(leaflet)
library(shinyalert)
library(shinyjs)

currentyear <- as.integer(format(Sys.Date(), "%Y"))

species_choices <- c(
  "True Blue whales", "Pugmy Blue whales", "Fin whales", "Sperm whales",
  "Humpback whales", "Sei whales", "Brydes whales", "Common Minke whales",
  "Antarctic Minke whales", "Gray whales", "Bowhead whales", "Right whales",
  "Unspecified Large whales", "Total Large whales", "Bottlenose whales",
  "Killer whales", "Pilot whales", "Baird's Beaked whales",
  "Other small cetaceans","Struck & Lost"
)

whale_photo <- "humpback-whale.jpg"
hero_style <- paste(
  "background-image:",
  "linear-gradient(90deg, rgba(4,31,51,0.94) 0%, rgba(5,55,82,0.78) 46%, rgba(4,50,75,0.18) 100%),",
  paste0("url('", whale_photo, "');")
)

dashboardPage(
  skin = "blue",

  dashboardHeader(
    titleWidth = 330,
    title = tags$span(
      icon("anchor"),
      tags$span("Whaling Catches Explorer", class = "header-title-text")
    )
  ),

  dashboardSidebar(
    width = 330,

    div(
      class = "sidebar-brand",
      div(class = "sidebar-brand-icon", icon("globe")),
      div(
        tags$div("IWC CATCH DATABASE", class = "sidebar-eyebrow"),
        tags$div("Explore catches by species and year", class = "sidebar-subtitle")
      )
    ),

    div(
      class = "filter-panel",
      tags$div(icon("filter"), " FILTERS", class = "filter-heading"),
      
      selectizeInput(
        "species",
        label = tagList(
          tags$img(
            src = "whale-tail.svg",
            style = "height:18px; width:18px; margin-right:6px;"
          ),
          "Species"
        ),
        choices = species_choices,
        multiple = FALSE,
        selected = "Total Large whales",
        options = list(
          placeholder = "Choose a species...",
          plugins = list("remove_button"),
          closeAfterSelect = FALSE,
          maxOptions = 50
        )
      ),
      tags$div("Click the field to open the species list. One species can be selected.",
               class = "field-help"),

      sliderInput(
        "year",
        label = tagList(icon("calendar"), " Year range"),
        min = 1800,
        max = currentyear,
        value = c(1990, 2020),
        sep = ""
      ),

      actionButton(
        "button",
        "Update view",
        icon = icon("refresh"),
        class = "update-button"
      )
    ),
    div(
      class = "sidebar-note",
      
      tags$div(
        class = "info-title",
        icon("info-circle"),
        tags$strong(" About this app")
      ),
      
      tags$p(
        "Select a species and year range, then click Update view to refresh the map and table."
      ),
      tags$div(
        class = "info-item",
        tags$strong("Struck & Lost: "),
        "values represent totals across all species."
      ),
      
      tags$div(
        class = "info-item",
        tags$strong("More detailed data: "),
        "A more advanced web application ",
        tags$a(
          "WhaleVis",
          href = "https://whalevis.ameyapatil249.workers.dev/",
          target = "_blank"
        )," developed by A.Patil provides access to disaggregated catch data. ",
        "Because these data are sensitive, access is restricted. To request access, contact ",
        tags$a(
          "statistics@iwc.int",
          href = "mailto:statistics@iwc.int"
        ),
        "."
      ),
      
      tags$div(
        class = "info-item",
        tags$strong("Feedback: "),
        "For comments or feedback on this web application, contact ",
        tags$a(
          "isidora.katara@iwc.int",
          href = "mailto:isidora.katara@iwc.int"
        ),
        "."
      )
    )
  ),

  dashboardBody(
    tags$head(
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
    ),

    div(
      class = "hero-panel",
      style = hero_style,
      div(
        class = "hero-content",
        tags$div("GLOBAL WHALING CATCHES", class = "hero-kicker"),
        tags$h1("Explore whaling catches through space and time"),
        tags$p(
          "Use the filters to examine reported catches by species and year, then explore their geographic distribution and underlying records."
        ),
        div(
          class = "hero-chips",
          span(class = "hero-chip", icon("map-marker"), "Spatial overview"),
          uiOutput("year_chip"),
          span(class = "hero-chip", icon("table"), "Detailed records")
        )
      ),
      tags$div("Photo: Robert Schwemmer / NOAA", class = "hero-credit")
    ),

    fluidRow(
      box(
        title = tagList(icon("globe"), " Geographic distribution"),
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        leafletOutput("mymap", height = 500)
      )
    ),

    fluidRow(
      box(
        title = tagList(icon("table"), " Catch records"),
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        DT::dataTableOutput("table")
      )
    ),
    div(
      class = "app-footer",
      
      tags$span(
        "Data available in "
      ),
      
      tags$a(
        "Zenodo",
        href = "https://doi.org/10.5281/zenodo.19204891",
        target = "_blank"
      ),
      
      tags$span(
        " · Web application developed by I. Katara - IWC Secretariat"
      )
    ),
    useShinyjs(),
    useShinyalert()
  )
)
