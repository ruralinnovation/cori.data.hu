# Introduction to cori.data.hu

`cori.data.hu` provides annual housing unit estimates from the U.S.
Census Bureau’s National, State, and County Housing Unit Totals,
processed and stored in CORI’s S3 data lake. Data cover 2000–present and
measure the total housing stock — occupied and vacant units combined —
built from the decennial Census baseline plus annual permitted
construction, non-permitted construction, mobile home shipments, and
estimated housing loss.

**Source:** U.S. Census Bureau, Population Estimates Program
**Coverage:** 2000–present, updated annually (release typically May)
**Geography:** County (5-digit FIPS), state (2-digit FIPS), national
(`"00"`)

## Variables

``` r

library(cori.data.hu)

get_hu_codebook() |>
  dplyr::select(variable, label, unit, notes) |>
  knitr::kable()
```

| variable | label | unit | notes |
|:---|:---|:---|:---|
| housing_units | Total housing units | units | Annual July 1 estimate of total housing units (occupied + vacant). Built from decennial Census baseline plus permitted construction, non-permitted construction, mobile home shipments, and housing loss. Coverage: 2000-present (2000-2009 intercensal, 2010-2019, 2020-present). Geography: county (5-digit FIPS), state (2-digit FIPS), national (‘00’). |
| housing_units_per_1k_people | Housing units per 1,000 population | units per 1,000 persons | Total housing units divided by population in thousands. Population denominator from Census Population Estimates Program via cori.data.pep. Coverage: 2000-present. agg_var = population / 1,000, suitable for population-weighted averaging. |
| housing_unit_change | Net change in housing units | units | Year-over-year net change in total housing units. NA for 2000, 2010, and 2020 — these boundary years span different decade series with different Census baselines, so the arithmetic difference reflects a methodological reset rather than real housing stock change. Coverage: 2001-present (excluding decade boundary years). |

## Reading data

All data are returned in long format: one row per
`geoid / year / variable`.

``` r

df <- get_housing_units(geography = "county")

dplyr::glimpse(df)
```

Filter to specific variables, years, or counties:

``` r

# Housing units per 1,000 population for New Hampshire counties
nh_hu <- get_housing_units(
  variables = "housing_units_per_1k_people",
  geoids    = grep("^33", unique(df$geoid), value = TRUE),
  years     = 2010:2024
)

dplyr::glimpse(nh_hu)
```

## Rural vs. Nonrural

Housing stock per capita diverges between rural and nonrural counties.
The chart below shows population-weighted average housing units per
1,000 population by rural status using the CBSA 2023 rural definition.

``` r

library(cori.charts)
library(ggplot2)
library(ruraldefinitions)
library(dplyr)

load_fonts()

df <- get_housing_units(
  geography = "county",
  variables = "housing_units_per_1k_people"
)

rural_avg <- df |>
  left_join(select(cbsa_2023, geoid, is_rural), by = "geoid") |>
  filter(!is.na(is_rural), !is.na(value), !is.na(agg_var)) |>
  group_by(year, is_rural) |>
  summarise(
    value = sum(value * agg_var, na.rm = TRUE) / sum(agg_var, na.rm = TRUE),
    .groups = "drop"
  )

ggplot(rural_avg, aes(x = year, y = value, color = is_rural)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  scale_color_manual(
    values = c("Rural" = "#2F6E9B", "Nonrural" = "#7EBDC2"),
    labels = c("Rural" = "Rural counties", "Nonrural" = "Nonrural counties")
  ) +
  scale_x_continuous(breaks = seq(2000, 2024, by = 5)) +
  scale_y_continuous(labels = scales::label_number(accuracy = 0.1)) +
  theme_cori() +
  theme(legend.position = "bottom") +
  labs(
    title    = "Rural counties carry more housing units per capita than nonrural",
    subtitle = "Population-weighted average housing units per 1,000 population, 2000\u20132024",
    x        = NULL,
    y        = NULL,
    color    = NULL,
    caption  = "Source: CORI analysis of U.S. Census Bureau Housing Unit Estimates."
  )
```

## County Spotlight: Grafton County, NH

``` r

grafton <- get_housing_units(
  variables = "housing_units_per_1k_people",
  geoids    = c("33009", "33", "00")
) |>
  mutate(
    group = case_when(
      geoid == "33009" ~ "Grafton County, NH",
      geoid == "33"    ~ "New Hampshire",
      geoid == "00"    ~ "United States"
    ),
    group = factor(group, levels = c("Grafton County, NH", "New Hampshire", "United States"))
  )

ggplot(grafton, aes(x = year, y = value, color = group, linetype = group, linewidth = group)) +
  geom_line(na.rm = TRUE) +
  geom_point(size = 2.5, na.rm = TRUE) +
  scale_color_manual(values = c(
    "Grafton County, NH" = "#2F6E9B",
    "New Hampshire"      = "#7EBDC2",
    "United States"      = "#9DA7B0"
  )) +
  scale_linetype_manual(values = c(
    "Grafton County, NH" = "solid",
    "New Hampshire"      = "dashed",
    "United States"      = "dotted"
  )) +
  scale_linewidth_manual(values = c(
    "Grafton County, NH" = 1.2,
    "New Hampshire"      = 0.8,
    "United States"      = 0.8
  )) +
  scale_x_continuous(breaks = seq(2000, 2024, by = 5)) +
  scale_y_continuous(labels = scales::label_number(accuracy = 0.1)) +
  theme_cori() +
  theme(legend.position = "bottom") +
  labs(
    title    = "Housing units per 1,000 residents — Grafton County, NH",
    subtitle = "Compared to New Hampshire and the United States, 2000\u20132024",
    x        = NULL,
    y        = NULL,
    color    = NULL,
    linetype = NULL,
    linewidth = NULL,
    caption  = paste0(
      "Source: CORI analysis of U.S. Census Bureau Housing Unit Estimates.\n",
      "Population denominator from Census Population Estimates Program via cori.data.pep."
    )
  )
```
