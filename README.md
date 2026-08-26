# IWC Whaling Catches Explorer

A simple R Shiny application for exploring the aggregated whaling catch data currently held by the International Whaling Commission (IWC).

The application was developed as a lightweight way of showing what data are currently available. Users can select a species and reporting-year range, view catch totals spatially, and inspect the corresponding records.

## Live application

A deployed version of the application is available at:

https://isidorakatara.shinyapps.io/Whaling-Summary_Catch_Data_visualisation_app/

## What the app shows

The application allows users to:

- select a species;
- select a reporting-year range;
- view reported catches by IWC catch area on an interactive map;
- inspect the corresponding records in a searchable table; and
- view additional information for whaling expeditions where available.

**Note:** *Struck & Lost* values represent totals across all species.

The application is intended primarily to provide an overview of the data currently available in the IWC catch database rather than to provide a comprehensive analytical platform.

## Data

The data used by the application are publicly available through Zenodo:

https://zenodo.org/records/19204891

The Zenodo record is the authoritative source for the datasets used by the application. Users should refer to that record for the applicable data licence and citation information.

The application currently uses:

- `catches-preMoratorium_Zenodo_v1.0.xlsx`
- `catches-postMoratorium_Zenodo_v1.0.xlsx`
- `catches-referencetables_Zenodo_v1.0.xlsx`

The reference tables provide additional metadata used by the application, including information on whaling expeditions.

Spatial catch-area boundaries are provided through the `summary_catch_data_areas_wOc` shapefile.

## Repository structure

```text
.
├── ui.R
├── server.R
├── README.md
├── LICENSE
│
├── catches-preMoratorium_Zenodo_v1.0.xlsx
├── catches-postMoratorium_Zenodo_v1.0.xlsx
├── catches-referencetables_Zenodo_v1.0.xlsx
│
├── summary_catch_data_areas_wOc.shp
├── summary_catch_data_areas_wOc.dbf
├── summary_catch_data_areas_wOc.shx
├── summary_catch_data_areas_wOc.prj
│
└── www/
    ├── custom.css
    ├── humpback-whale.jpg
    └── whale-tail.svg
```

Additional shapefile component files should be kept together with the `.shp` file.

## Running the application

### Requirements

The application requires R and the following R packages:

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "shinyjs",
  "shinyalert",
  "readxl",
  "data.table",
  "leaflet",
  "dplyr",
  "sf",
  "DT",
  "stringr",
  "htmltools"
))
```

### Run locally

Clone or download this repository and ensure the required data and spatial files are present.

From the repository directory, run:

```r
shiny::runApp()
```

The application will open in your default web browser.

## Extending the application

The application has deliberately been kept simple and can be used as a basis for further development.

For example, it could be extended to include:

- additional filters;
- alternative spatial summaries;
- different visualisations;
- downloadable outputs;
- additional reference information; or
- links to other IWC data products.

The repository is intended to provide a practical starting point for scientists and developers who wish to build on the application for other research or data-visualisation purposes.

## Development

Web application developed by:

**I. Katara**  
IWC Secretariat

For comments, corrections, or feedback on this web application, contact:

**isidora.katara@iwc.int** or **isidora10@yahoo.com**

## Acknowledgements

The application uses R Shiny for the user interface and Leaflet for interactive spatial visualisation.

## Licence

## Code

The source code for this application is released under the **PolyForm Noncommercial License 1.0.0** and may be reused, modified, and further developed.

See the `LICENSE` file in this repository for details.

## Data

The data used by this application are available through Zenodo:

https://zenodo.org/records/19204891

The data are subject to the licence and conditions specified in the Zenodo record. Users should refer to the Zenodo record for the applicable licence and citation information.
