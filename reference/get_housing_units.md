# Get Census Bureau housing unit estimates

Returns housing unit estimates from the U.S. Census Bureau's National,
State, and County Housing Unit Totals. Data cover 2000–present at annual
frequency for county, state, and national geographies.

## Usage

``` r
get_housing_units(
  geography = c("all", "county", "state", "nation"),
  years = NULL,
  geoids = NULL,
  variables = NULL,
  vintage = "latest"
)
```

## Arguments

- geography:

  Character. Geographic level to return: `"all"`, `"county"`, `"state"`,
  or `"nation"`. Ignored when `geoids` is provided. Default: `"all"`.

- years:

  Integer vector. Years to return. Default: all available.

- geoids:

  Character vector. FIPS codes to return (5-digit county, 2-digit state,
  or `"00"` for national). When provided, takes precedence over
  `geography`. Default: `NULL` (all geographies).

- variables:

  Character vector. Variables to return: `"housing_units"`,
  `"housing_units_per_1k_people"`, and/or `"housing_unit_change"`.
  Default: all. See
  [`get_hu_codebook()`](https://ruralinnovation.github.io/cori.data.hu/reference/get_hu_codebook.md)
  for details.

- vintage:

  Character. Vintage to read, e.g. `"2024"`. Default: `"latest"`.

## Value

A data frame with columns: `geoid`, `year`, `variable`, `value`,
`agg_var`. `agg_var` is population / 1,000 for
`housing_units_per_1k_people` (suitable for population-weighted
averaging) and `NA` for count variables.

## See also

[`get_hu_codebook()`](https://ruralinnovation.github.io/cori.data.hu/reference/get_hu_codebook.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# All county-level housing unit estimates
get_housing_units(geography = "county", years = 2010:2024)

# Specific county — Grafton County, NH
get_housing_units(geoids = "33009")

# Housing units per 1,000 population, state level
get_housing_units(geography = "state", variables = "housing_units_per_1k_people")
} # }
```
