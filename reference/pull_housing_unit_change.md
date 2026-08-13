# Pull net year-over-year change in housing units

Reads raw Census housing unit data and computes the year-over-year
change in total units for each geography. Returns `NA` for 2000 (first
year), 2010, and 2020. The 2010 and 2020 boundary years span different
decade series with different Census baselines, so the arithmetic
difference is a methodological jump rather than a real change in housing
stock.

## Usage

``` r
pull_housing_unit_change(vintage_year = NULL, staging_dir = "data/hu")
```

## Arguments

- vintage_year:

  Integer. Vintage year to download. Default: auto-detected.

- staging_dir:

  Character. Local staging directory. Default: `"data/hu"`.

## Value

A data frame: `geoid`, `year`, `variable`, `value`, `agg_var`.
