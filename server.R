library(shinyjs)
library(shiny)
library(readxl)
library(data.table)
library(leaflet)
library(dplyr)
library(ggplot2)
library(sf)
library(RColorBrewer)
library(shinyalert)

# Define server logic required to draw the map and the table
function(input, output, session) {

  # Spatial summary areas
  subareas <- read_sf("summary_catch_data_areas_wOc.shp")

  # Read the original data
  xls_file1 <- "catches-postMoratorium_Zenodo_v1.0.xlsx"
  xls_file2 <- "catches-preMoratorium_Zenodo_v1.0.xlsx"
  
  orfile <- bind_rows(
    read_excel(xls_file1, sheet = "catches-postMoratorium") %>%
      mutate(Excode = stringr::str_pad(as.character(Excode), width = 4, side = "left", pad = "0")),
    read_excel(xls_file2, sheet = "catches-preMoratorium") %>%
      mutate(Excode = stringr::str_pad(as.character(Excode), width = 4, side = "left", pad = "0"))
  )
  
  #read the expeditions and format reference tables
  xls_file <- "catches-referencetables_Zenodo_v1.0.xlsx"
  expeditions <- read_excel(xls_file, sheet = "Expeditions") %>%
    mutate(
      Excode = stringr::str_pad(as.character(Excode), width = 4, side = "left", pad = "0")
    ) %>%
    mutate(across(everything(), as.character)) %>%
    select(Excode,Name,`Land Station / F.Factory`,Area,Company)
  
  Format <- read_excel(xls_file, sheet = "Format")
  
  # Reshape data to have species as a column
  MainCols <- c(
    'Yearfile','Season','Oc','Area','Excode','Admin_Reg','Land St. / Floating Factory', 'Smonth','Syear','Emonth','Eyear','Dat','Ty','N','Qu','Notes'
  )

  SpCols <- c(
'TBlue','PBlue','Fin','Spm','Hbk','Sei','Bryd','CMi','AMi','Gray','Bhd','Ri','Unsp','Total','Bot','Ki','Pi', 'BBk','Oth' ,'TotalLost'
  )

  orcatch <- orfile[, c(MainCols, SpCols)]
  catchlong <- melt(setDT(orcatch), id.vars = MainCols, variable.name = "Sp")
  c2 <- as.data.frame(catchlong)

  # Match species codes to full species names
  Species <- c(
    "True Blue whales", "Pugmy Blue whales", "Fin whales", "Sperm whales",
    "Humpback whales", "Sei whales", "Brydes whales", "Common Minke whales",
    "Antarctic Minke whales", "Gray whales", "Bowhead whales", "Right whales",
    "Unspecified Large whales", "Total Large whales", "Bottlenose whales",
    "Killer whales", "Pilot whales", "Baird's Beaked whales",
    "Other small cetaceans","Struck & Lost"
  )

  SPLookUp <- data.frame(SPFull = Species, SpName = SpCols)
  c3 <- merge(c2, SPLookUp, by.x = "Sp", by.y = "SpName", all.x = TRUE)

  # Administrative regions (previously Nation)
  c4 <- c3 %>% rename(`Admin Region` = Admin_Reg)
  c4$NtFull[is.na(c4$`Admin Region`)] <- "unknown"

  # Match operation type code to description
  sumTy <- c("AS", "C","Inf","M","N","NO","SP","SPicj","WO","WR","U")
  fullTy <- c("Aboriginal subsistence catches", "Commercial whaling", "Illegal catches by IWC member nations", "Non commercial catches by non-member nations", "Operation without catch data", "No operation", "Special permit whaling", "Special permit whaling (ICJ case)", "Whaling under objection","Whaling under reservation","Unconfirmed reports of catches")

  TyLookUp <- data.frame(TyFull = fullTy, TyName = sumTy)
  c5 <- merge(c4, TyLookUp, by.x = "Ty", by.y = "TyName", all.x = TRUE)
  c5$NtFull[is.na(c5$Ty)] <- " "

  # Keep and summarise the columns needed by the application
  c6 <- c5 %>%
    select(Yearfile,Season,Area,Excode,`Admin Region`,`Land St. / Floating Factory`, Smonth,Syear,Emonth,Eyear,TyFull,value,SPFull) %>%
    group_by(Yearfile,Season,Area,Excode,`Admin Region`,`Land St. / Floating Factory`, Smonth,Syear,Emonth,Eyear,TyFull,SPFull) %>%
    summarise(`Whale Numbers` = sum(value, na.rm = TRUE), .groups = "drop") %>%
    rename(`Reporting year` = Yearfile, `Whaling Type` = TyFull, Species = SPFull, Expedition = Excode, `start month` = Smonth, `start year` = Syear,`end month` = Emonth,`end year` = Eyear) %>%
    filter(`Whale Numbers` > 0)
  
  # Find first and last year available in the data
  first_year <- min(c6$`Reporting year`, na.rm = TRUE)
  last_year  <- max(c6$`Reporting year`, na.rm = TRUE)
  output$year_chip <- renderUI({
    span(
      class = "hero-chip",
      icon("calendar"),
      paste0(first_year, "–", last_year)
    )
  })
  
  # Update the slider to match the data
  updateSliderInput(
    session,
    "year",
    min = first_year,
    max = last_year,
    value = c(1990, 2020)
  )
  
  # Update outputs when filters change via the button.
  # ignoreNULL = FALSE also draws the default view when the app first opens.
  observeEvent(input$button, {

    df <- c6 %>%
      filter(
        `Reporting year` >= input$year[1],
        `Reporting year` <= input$year[2],
        Species %in% input$species
      ) %>%
      arrange(desc(`Reporting year`), desc(`start year`), Expedition) 

    if (nrow(df) == 0) {
      shinyalert(
        "No data returned",
        "There are no catches for the current selection. Try removing or relaxing one or more filters.",
        type = "warning"
      )

      output$table <- DT::renderDataTable({
        data.frame(Message = "No catches for the current selection.")
      }, options = list(dom = "t"), rownames = FALSE)

      output$mymap <- renderLeaflet({
        leaflet(options = leafletOptions(minZoom = 1)) %>%
          addProviderTiles("Esri.WorldGrayCanvas") %>%
          setView(lng = 0, lat = 10, zoom = 1)
      })

      return()
    }
    
    #tooltip to show expedition information
    expedition_tooltips <- expeditions %>%
      rowwise() %>%
      mutate(
        tooltip = paste(
          paste0(
            names(expeditions),
            ": ",
            as.character(c_across(everything()))
          ),
          collapse = "<br>"
        )
      ) %>%
      ungroup() %>%
      select(Excode, tooltip)
    #join to the displayed data
    df <- df %>%
      left_join(
        expedition_tooltips,
        by = c("Expedition" = "Excode")
      )
    #Replace the Expedition values with clickable-looking hover elements
    df <- df %>%
      select(-`Reporting year`,-Season, -`Land St. / Floating Factory`) %>%
      mutate(
        Expedition = ifelse(
          !is.na(tooltip),
          paste0(
            '<span class="expedition-tooltip" ',
            'data-toggle="tooltip" ',
            'data-html="true" ',
            'data-placement="right" ',
            'title="', tooltip, '">',
            Expedition,
            '</span>'
          ),
          Expedition
        )
      ) %>%
      select(-tooltip)
    # Detailed table
    output$table <- DT::renderDataTable(
      df,
      escape = FALSE,
      rownames = FALSE,
      class = "stripe hover compact",
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        autoWidth = TRUE,
        order = list(list(0, "desc")),
        language = list(search = "Search records:"),
        
        # Add an information icon beside the Expedition column heading
        initComplete = DT::JS(
          "function(settings, json) {

       var api = this.api();

       $(api.table().header()).find('th').each(function() {

         if ($(this).text().trim() === 'Expedition') {

           $(this).append(
             ' <i class=\"fa fa-info-circle expedition-header-info\" ' +
             'data-toggle=\"tooltip\" ' +
             'title=\"Hover over the expedition number to see more information about the expedition\"></i>'
           );

         }
       });

       $('.expedition-header-info').tooltip({
         container: 'body'
       });
     }"
        ),
        drawCallback = DT::JS(
          "function(settings) {
       $('[data-toggle=\"tooltip\"]').tooltip({
         container: 'body'
       });
     }"
        )
      )
)
    # Aggregate by spatial area for a clean choropleth
    area_totals <- df %>%
      group_by(Area) %>%
      summarise(`Whale Numbers` = sum(`Whale Numbers`, na.rm = TRUE), .groups = "drop")

    dfsubareas <- subareas %>%
      left_join(area_totals, by = c("AreaName" = "Area")) %>%
      filter(!is.na(`Whale Numbers`)) %>%
      mutate(.polygon_area = as.numeric(sf::st_area(geometry))) %>%
      arrange(desc(.polygon_area))

    breaks <- quantile(
      dfsubareas$`Whale Numbers`,
      probs = seq(0, 1, length.out = 7),
      na.rm = TRUE
    )
    
    breaks <- unique(breaks)
    
    pal <- colorBin(
      palette = c(
        "#E8F4FA",
        "#B9E0EF",
        "#78C1DA",
        "#3498BD",
        "#0A6FA8",
        "#073B5C"
      ),
      domain = dfsubareas$`Whale Numbers`,
      bins = breaks,
      pretty = FALSE,
      na.color = "transparent"
    )

    area_labels <- paste0(
      "<strong>", dfsubareas$AreaName, "</strong><br/>Total catches: ",
      format(dfsubareas$`Whale Numbers`, big.mark = ",", scientific = FALSE)
    ) %>% lapply(htmltools::HTML)

    output$mymap <- renderLeaflet({
      leaflet(dfsubareas, options = leafletOptions(minZoom = 1, worldCopyJump = TRUE)) %>%
        addProviderTiles("Esri.WorldGrayCanvas") %>%
        addPolygons(
          fillColor = ~pal(`Whale Numbers`),
          fillOpacity = 0.82,
          color = "#FFFFFF",
          weight = 1,
          smoothFactor = 0.25,
          label = area_labels,
          highlightOptions = highlightOptions(
            weight = 2,
            color = "#FFFFFF",
            fillOpacity = 0.95,
            bringToFront = FALSE
          ),
          labelOptions = labelOptions(
            style = list(
              "font-weight" = "normal",
              padding = "7px 9px",
              "border-radius" = "7px"
            ),
            textsize = "13px",
            direction = "auto"
          )
        ) %>%
        addLegend(
          pal = pal,
          values = ~`Whale Numbers`,
          title = input$species,
          position = "bottomright",
          opacity = 0.9
        )
    })
  }, ignoreNULL = FALSE)
}
