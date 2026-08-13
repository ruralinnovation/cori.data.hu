# Pull total housing unit estimates

Reads raw Census housing unit Excel files and returns total housing unit
counts in the five-column tidy format.

## Usage

``` r
pull_housing_units(vintage_year = NULL, staging_dir = "data/hu")
```

## Arguments

- vintage_year:

  Integer. Vintage year to download. Default: auto-detected from Census
  URLs.

- staging_dir:

  Character. Local staging directory. Default: `"data/hu"`.

## Value

A data frame: `geoid`, `year`, `variable`, `value`, `agg_var`.
