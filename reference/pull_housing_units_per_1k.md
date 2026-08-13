# Pull housing units per 1,000 population

Reads raw Census housing unit data, joins with a population data frame,
and returns units per 1,000 population in the five-column tidy format.

## Usage

``` r
pull_housing_units_per_1k(pop_df, vintage_year = NULL, staging_dir = "data/hu")
```

## Arguments

- pop_df:

  Data frame with columns `geoid`, `year`, `pop`. Obtain from
  `cori.data.pep::read_pep_from_s3(variables = "population")`, then
  rename `value` to `pop` and drop `variable`/`agg_var`.

- vintage_year:

  Integer. Vintage year to download. Default: auto-detected.

- staging_dir:

  Character. Local staging directory. Default: `"data/hu"`.

## Value

A data frame: `geoid`, `year`, `variable`, `value`, `agg_var`.
