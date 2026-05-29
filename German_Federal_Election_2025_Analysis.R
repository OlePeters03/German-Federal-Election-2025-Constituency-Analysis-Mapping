# =============================================================================
# German Federal Election 2025 – Constituency Analysis & Mapping
# =============================================================================
# Author:  Ole Peters
# Date:    May 2026
# Data:    Federal Returning Officer (kerg2.csv, constituency names, shapefiles)
# Goal:    Analyse party results at constituency level and produce choropleth
#          maps of the leading party by first and second vote
#          (focus: Lower Saxony, Schleswig-Holstein)
# =============================================================================


# 0. Load packages ------------------------------------------------------------

library(tidyverse)
library(sf)

# 1. Configure file paths -----------------------------------------------------
# Paths use ~ which expands to /Users/your-username on any Mac.
# Adjust Data_Seminar to match your local folder name if needed.

PATH_KERG      <- "~/Data_Seminar/kerg2.csv"
PATH_WK_NAMEN  <- "~/Data_Seminar/btw25_wahlkreisnamen_utf8.csv"
PATH_SHAPEFILE <- "~/Data_Seminar/btw Geodaten/btw25_geometrie_wahlkreise_vg250.shp"


# 2. Read raw data ------------------------------------------------------------

btw25_raw <- read_delim(
  PATH_KERG,
  delim          = ";",
  skip           = 9,
  locale         = locale(decimal_mark = ","),
  show_col_types = FALSE
)

# Constituency names with federal state abbreviations
wk_namen <- read_delim(
  PATH_WK_NAMEN,
  delim          = ";",
  comment        = "#",
  show_col_types = FALSE
) |>
  mutate(WKR_NR = as.integer(WKR_NR))

# Constituency geometries (shapefile)
wk_geo <- st_read(PATH_SHAPEFILE, quiet = TRUE)


# 3. Clean and prepare data ---------------------------------------------------

## 3a. Keep only constituency-level rows; cast ID to integer
btw25_wk <- btw25_raw |>
  filter(Gebietsart == "Wahlkreis") |>
  mutate(Gebietsnummer = as.integer(Gebietsnummer))

## 3b. Join constituency names (incl. federal state abbreviation)
btw25_wk <- btw25_wk |>
  left_join(wk_namen, by = c("Gebietsnummer" = "WKR_NR"))

## 3c. Keep only party results; select relevant columns
btw25_parteien <- btw25_wk |>
  filter(Gruppenart == "Partei") |>
  select(
    Gebietsnummer, Gebietsname, LAND_ABK,
    Gruppenname, Stimme,
    Anzahl, Prozent, VorpProzent, DiffProzentPkt
  )

## 3d. Derive new variables: relative change vs. 2021 and strength category
btw25_parteien <- btw25_parteien |>
  mutate(
    relative_change = (Prozent - VorpProzent) / VorpProzent * 100,
    strength = case_when(
      Prozent >= 30 ~ "dominant",
      Prozent >= 15 ~ "strong",
      Prozent >= 5  ~ "medium",
      .default      = "weak"
    )
  )


# 4. Descriptive summary ------------------------------------------------------

# Mean, min and max second-vote share per party across all constituencies
btw25_parteien |>
  filter(
    Stimme == 2,
    Gruppenname %in% c("CDU", "CSU", "SPD", "GRÜNE", "FDP", "AfD", "Die Linke", "BSW")
  ) |>
  group_by(Gruppenname) |>
  summarise(
    mean_share = mean(Prozent, na.rm = TRUE),
    min_share  = min(Prozent,  na.rm = TRUE),
    max_share  = max(Prozent,  na.rm = TRUE),
    .groups    = "drop"
  ) |>
  arrange(desc(mean_share))


# 5. Helper function: create electoral map 

#' Create a choropleth map of the leading party per constituency
#'
#' @param land_abk   Federal state abbreviation (e.g. "NI", "SH")
#' @param stimme     Vote type: 1 = first vote (Erststimme),
#'                              2 = second vote (Zweitstimme)
#' @param title      Map title
#' @param subtitle   Map subtitle
#' @return           A ggplot object

create_electoral_map <- function(land_abk, stimme, title, subtitle) {
  
  # Leading party per constituency in the selected federal state
  leading_party <- btw25_parteien |>
    filter(LAND_ABK == land_abk, Stimme == stimme) |>
    group_by(Gebietsnummer) |>
    slice_max(Prozent, n = 1, with_ties = FALSE) |>
    ungroup()
  
  # Clip geodata to federal state and join results
  map_data <- wk_geo |>
    filter(WKR_NR %in% leading_party$Gebietsnummer) |>
    left_join(leading_party, by = c("WKR_NR" = "Gebietsnummer"))
  
  # Official party colours
  party_colours <- c(
    "CDU"       = "#000000",
    "CSU"       = "#0A192F",
    "SPD"       = "#E3000F",
    "GRÜNE"     = "#46962B",
    "AfD"       = "#009EE0",
    "FDP"       = "#FFED00",
    "Die Linke" = "#BE3075",
    "BSW"       = "#722B6E"
  )
  
  ggplot(map_data) +
    geom_sf(aes(fill = Gruppenname), color = "white", linewidth = 0.3) +
    scale_fill_manual(values = party_colours, name = "Leading party") +
    labs(
      title    = title,
      subtitle = subtitle,
      caption  = "Data: Federal Returning Officer (Bundeswahlleiterin)"
    ) +
    theme_void() +
    theme(
      plot.title      = element_text(size = 14, face = "bold"),
      plot.subtitle   = element_text(size = 11, color = "grey40"),
      legend.position = "bottom"
    )
}


# 6. Generate maps ------------------------------------------------------------

## Lower Saxony (Niedersachsen)
map_ni_second <- create_electoral_map(
  land_abk = "NI",
  stimme   = 2,
  title    = "German Federal Election 2025 – Lower Saxony",
  subtitle = "Leading party by second-vote share per constituency"
)

map_ni_first <- create_electoral_map(
  land_abk = "NI",
  stimme   = 1,
  title    = "German Federal Election 2025 – Lower Saxony",
  subtitle = "Leading party by first-vote share per constituency"
)

## Schleswig-Holstein
map_sh_second <- create_electoral_map(
  land_abk = "SH",
  stimme   = 2,
  title    = "German Federal Election 2025 – Schleswig-Holstein",
  subtitle = "Leading party by second-vote share per constituency"
)

map_sh_first <- create_electoral_map(
  land_abk = "SH",
  stimme   = 1,
  title    = "German Federal Election 2025 – Schleswig-Holstein",
  subtitle = "Leading party by first-vote share per constituency"
)

## Germany-wide map (all 299 constituencies)
# Uses the full dataset – no federal state filter applied

## 6a. Leading party per constituency across all of Germany
de_leading_party <- btw25_parteien |>
  filter(Stimme == 2) |>
  group_by(Gebietsnummer) |>
  slice_max(Prozent, n = 1, with_ties = FALSE) |>
  ungroup()

## 6b. Join geodata with results
wk_karte_de <- wk_geo |>
  left_join(de_leading_party, by = c("WKR_NR" = "Gebietsnummer"))

## 6c. Plot
party_colours <- c(
  "CDU"       = "#000000",
  "CSU"       = "#0A192F",
  "SPD"       = "#E3000F",
  "GRÜNE"     = "#46962B",
  "AfD"       = "#009EE0",
  "FDP"       = "#FFED00",
  "Die Linke" = "#BE3075",
  "BSW"       = "#722B6E"
)

map_de_second <- ggplot(wk_karte_de) +
  geom_sf(aes(fill = Gruppenname), color = "white", linewidth = 0.2) +
  scale_fill_manual(values = party_colours, name = "Leading party") +
  labs(
    title    = "German Federal Election 2025 – All Constituencies",
    subtitle = "Leading party by second-vote share per constituency",
    caption  = "Data: Federal Returning Officer (Bundeswahlleiterin)"
  ) +
  theme_void() +
  theme(
    plot.title      = element_text(size = 14, face = "bold"),
    plot.subtitle   = element_text(size = 11, color = "grey40"),
    legend.position = "bottom"
  )

## Display maps
map_ni_second
map_ni_first
map_sh_second
map_sh_first
map_de_second


# 7. Optional: Save maps to disk ----------------------------------------------
# dir.create("output", showWarnings = FALSE)
#
# ggsave("output/map_ni_second_vote.png", map_ni_second,  width = 8,  height = 6, dpi = 300)
# ggsave("output/map_ni_first_vote.png",  map_ni_first,   width = 8,  height = 6, dpi = 300)
# ggsave("output/map_sh_second_vote.png", map_sh_second,  width = 8,  height = 6, dpi = 300)
# ggsave("output/map_sh_first_vote.png",  map_sh_first,   width = 8,  height = 6, dpi = 300)
# ggsave("output/map_de_second_vote.png", map_de_second,  width = 10, height = 12, dpi = 300)
