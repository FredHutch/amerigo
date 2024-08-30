library(shiny)
library(bslib)
library(sf)
library(leaflet)
library(RColorBrewer)
library(readr)
library(dplyr)
library(stringr)
library(htmltools)
library(desc)

# from https://github.com/rstudio/leaflet/issues/615
css_fix <- "div.info.legend.leaflet-control br {clear: both;}"
html_fix <- as.character(htmltools::tags$style(type = "text/css", css_fix))

wa_counties <- read_sf("wa-counties.geojson")

ui <- page_sidebar(
  HTML(html_fix),
  title = paste0("Amerigo v", desc("DESCRIPTION")$get_version()),
  sidebar = sidebar(
    fileInput("CSV", "Choose CSV File", accept = c(
      "text/csv",
      "text/comma-separated-values,text/plain",
      ".csv")),
    selectInput("PAL", "Color Palette", choices = c("viridis", "magma", "inferno", "plasma", rownames(RColorBrewer::brewer.pal.info)), selected = "viridis"),
    checkboxInput("rev_col_pal", "Reverse Color Palette", value = FALSE),
    checkboxInput("grey_map", "Grey Background Map", value = TRUE),
    sliderInput("fill_opacity", "Fill Opacity", min = 0, max = 1, value = 1, step = 0.2),
    textInput("border_color", "Border Color", "black"),
    sliderInput("border_opacity", "Border Opacity", min = 0, max = 1, value = 1, step = 0.2),
    sliderInput("border_weight", "Border Weight", min = 0, max = 5, value = 1, step = 1),
    textInput("legend_title", "Legend Title", "Legend Title"),
    selectInput("legend_position", "Legend Position", choices = c("topright", "bottomright", "bottomleft", "topleft"))
  ),
  card(
    leafletOutput("mainleaflet")
  )
)

server <- function(input, output) {
  # reactive_fill_data <- reactive({
  #   req(input$CSV)
  #   uploaded_data <- read_csv(input$CSV$datapath)
  #   
  #   county_index <- sapply(uploaded_data, function(x) {all(tolower(x) %in% tolower(wa_counties$JURISDICT_LABEL_NM))})
  #   result <- data.frame(uploaded_data[county_index], uploaded_data[!county_index]) %>%
  #     setNames(c("County", "Value")) %>% 
  #     group_by(County) %>% 
  #     count() %>% 
  #     ungroup() %>% 
  #     setNames(c("JURISDICT_LABEL_NM", "Count"))
  #   
  #   return(result)
  # })
  
  # observe({
  #   fill_data <- reactive_fill_data()
  #   if (is.null(fill_data)) return()
  #   
  #   pal <- colorNumeric(input$PAL, NULL)
  #   leafletProxy("mainleaflet") %>%
  #     addPolygons(stroke = TRUE, layerId = "COUNTIES",
  #               opacity = input$border_opacity, 
  #               weight = input$border_weight,
  #               color = input$border_color,
  #               smoothFactor = 0.3, 
  #               fillOpacity = input$fill_opacity,
  #               fillColor = ~pal(Count),
  #               label = ~paste0(JURISDICT_LABEL_NM, ": ", Count)
  #     ) %>%
  #       addLegend(pal = pal, values = ~Count, opacity = 1.0,
  #               title = input$legend_title, 
  #               position = input$legend_position)
  # })
  
  output$mainleaflet <- renderLeaflet({
    pal <- colorNumeric(input$PAL, NULL, reverse = input$rev_col_pal)
    
      req(input$CSV)
      uploaded_data <- read_csv(input$CSV$datapath)
      uploaded_data_types <- uploaded_data %>% sapply(class) %>% unname()
      
      if ("numeric" %in% uploaded_data_types) {
        county_index <- sapply(uploaded_data, function(x) {all(tolower(x) %in% tolower(wa_counties$JURISDICT_LABEL_NM))})
        fill_data <- data.frame(uploaded_data[county_index], uploaded_data[!county_index]) %>%
          setNames(c("JURISDICT_LABEL_NM", "Count")) %>%
          mutate(JURISDICT_LABEL_NM = str_to_title(JURISDICT_LABEL_NM))
      } else {
        county_index <- sapply(uploaded_data, function(x) {all(tolower(x) %in% tolower(wa_counties$JURISDICT_LABEL_NM))})
        fill_data <- data.frame(uploaded_data[county_index], uploaded_data[!county_index]) %>%
          setNames(c("County", "Value")) %>%
          group_by(County) %>%
          count() %>%
          ungroup() %>%
          setNames(c("JURISDICT_LABEL_NM", "Count")) %>%
          mutate(JURISDICT_LABEL_NM = str_to_title(JURISDICT_LABEL_NM))
      }
    
    output_map <- leaflet(wa_counties %>% left_join(fill_data), 
                          options = leafletOptions(attributionControl=FALSE)) %>%
      addTiles()
    
    if (input$grey_map) {
      output_map <- output_map %>% addProviderTiles("Esri.WorldGrayCanvas")
    }
    
    output_map %>%  
      addPolygons(stroke = TRUE,
                  opacity = input$border_opacity, 
                  weight = input$border_weight,
                  color = input$border_color,
                  smoothFactor = 0.3, 
                  fillOpacity = input$fill_opacity,
                  fillColor = ~pal(Count),
                  label = ~paste0(JURISDICT_LABEL_NM, ": ", Count)
                  ) %>%
      addLegend(pal = pal, values = ~Count, opacity = 1.0,
                title = input$legend_title, 
                position = input$legend_position)
  })
}

options <- list()
if (!interactive()) {
  options$launch.browser <- FALSE
  options$host <- "0.0.0.0"
  options$port <- 3838
}
shinyApp(ui = ui, server = server, options = options)
