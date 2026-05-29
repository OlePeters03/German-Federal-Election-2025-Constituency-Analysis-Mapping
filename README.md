# German Federal Election 2025 – Constituency Analysis & Mapping

An exploratory data analysis of the 2025 German federal election (*Bundestagswahl*) at constituency level, built in R. The project cleans and processes the official results published by the Federal Returning Officer, calculates descriptive statistics per party, and produces choropleth maps of the leading party by first and second vote — for Lower Saxony, Schleswig-Holstein, and all 299 constituencies nationwide.

-----

## Example Maps

|Lower Saxony – Second Vote                     |Schleswig-Holstein – Second Vote               |Germany – Second Vote                          |
|-----------------------------------------------|-----------------------------------------------|-----------------------------------------------|
|*(saved to `output/` after running the script)*|*(saved to `output/` after running the script)*|*(saved to `output/` after running the script)*|

-----

## Project Structure

1. `data/` — raw data files (not tracked by git, download manually)
- 1.1 `kerg2.csv`
- 1.2 `btw25_wahlkreisnamen_utf8.csv`
- 1.3 `btw Geodaten/`
  - 1.3.1 `btw25_geometrie_wahlkreise_vg250.shp` (+ `.dbf`, `.prj`, `.shx`)
1. `output/` — exported maps, auto-created when saving
1. `btw25_analyse.R` — main analysis script
1. `README.md`

-----

## Data Sources

All data are published by the **Federal Returning Officer** (*Bundeswahlleiterin*) and freely available:

|File                           |Description                                       |Link                                                                                                               |
|-------------------------------|--------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
|`kerg2.csv`                    |Official constituency-level results (kerg2 format)|[bundeswahlleiterin.de](https://www.bundeswahlleiterin.de/bundestagswahlen/2025/ergebnisse.html)                   |
|`btw25_wahlkreisnamen_utf8.csv`|Constituency numbers with federal state codes     |[bundeswahlleiterin.de](https://www.bundeswahlleiterin.de/bundestagswahlen/2025/wahlkreiseinteilung.html)          |
|Shapefiles                     |Constituency geometries (VG250)                   |[bundeswahlleiterin.de](https://www.bundeswahlleiterin.de/bundestagswahlen/2025/wahlkreiseinteilung/downloads.html)|


> Download the files manually and place them in the `data/` folder as shown in the project structure above.

-----

## Requirements

**R ≥ 4.2** and the following packages:

```r
install.packages(c("tidyverse", "sf"))
```

-----

## Usage

1. Clone the repository:
   
   ```bash
   git clone https://github.com/YOUR-USERNAME/btw25-analysis.git
   ```
1. Download the data files (see above) and place them in `data/` as shown in the project structure.
1. Open `btw25_analyse.R` and adjust the file paths at the top of the script to match your local directory.
1. Run the script:
   
   ```r
   source("btw25_analyse.R")
   ```
1. Maps are displayed in the plot viewer. To export them as PNG files, uncomment the `ggsave()` block at the bottom of the script.

-----

## What the Script Does

|Step                       |Description                                                                                                                                              |
|---------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
|**0 – Load packages**      |Loads `tidyverse` (data wrangling & plotting) and `sf` (geodata)                                                                                         |
|**1 – File paths**         |Defines all input paths in one place for easy adjustment                                                                                                 |
|**2 – Read data**          |Loads the results CSV, constituency names, and shapefile                                                                                                 |
|**3 – Clean & prepare**    |Filters to constituency level, joins federal state codes, selects relevant columns, calculates relative change vs. 2021 and a strength category per party|
|**4 – Descriptive summary**|Mean, min and max second-vote share per party across all constituencies                                                                                  |
|**5 – Helper function**    |`create_electoral_map()` takes a state code and vote type and returns a ready-to-use ggplot map — keeps the code DRY                                     |
|**6 – Generate maps**      |Calls the function for Lower Saxony and Schleswig-Holstein (first & second vote); separate block for the national map across all 299 constituencies      |
|**7 – Export (optional)**  |Uncomment the `ggsave()` block to save all maps as high-resolution PNGs                                                                                  |

-----

## Methodology

### Data Wrangling

- Raw results loaded from `kerg2.csv` (semicolon-separated, German decimal format; first 9 rows skipped as they contain metadata)
- Filtered to constituency level and joined with federal state codes via `left_join()`
- **Relative change** vs. the 2021 result calculated; parties categorised by vote share (*dominant ≥ 30% / strong ≥ 15% / medium ≥ 5% / weak*)

### Mapping

- Constituency geometries read from a VG250 shapefile using `{sf}`
- Leading party per constituency identified with `slice_max()`
- Filled with official party colours; separate maps for first and second vote
- A reusable helper function (`create_electoral_map()`) generates maps for any individual federal state
- A dedicated block produces a **national map across all 299 constituencies** without any state filter

-----

## Possible Extensions

- [x] National map covering all 299 constituencies
- [ ] Interactive map with `{leaflet}` or `{tmap}`
- [ ] Swing map: visualise vote-share change vs. 2021
- [ ] Shiny app for dynamic state and party selection

-----

## License

**Data** are subject to the Federal Returning Officer’s terms of use (dl-de/by-2-0).  
**Code** is released under the MIT License – see <LICENSE>.
