library(readr)
library(sf)

set.seed(2024-08-28)

wa_counties <- read_sf("wa-counties.geojson")

data.frame(Partner = replicate(250, paste(paste(sample(LETTERS, 3), collapse = ""), sample(c("Corporation", "Group"), 1))),
           County = sample(wa_counties$JURISDICT_LABEL_NM, 250, replace = TRUE)) %>%
  write_csv("partners.csv")

data.frame(County = wa_counties$JURISDICT_LABEL_NM, Visits = sample(1:100, length(wa_counties$JURISDICT_LABEL_NM))) %>%
  write_csv("visits.csv")

