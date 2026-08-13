# Read raw housing unit estimates from Census source files

Downloads (if needed) and parses Census housing unit files across all
available decades: 2000-2009 (intercensal CSV), 2010-2019 (Excel), and
2020-present (Excel). Returns a long-format data frame with one row per
geoid/year, including county, state, and national totals.

## Usage

``` r
read_hu_raw(vintage_year = NULL, staging_dir = "data/hu")
```

## Arguments

- vintage_year:

  Integer. Latest vintage year for the 2020s series. Default:
  auto-detected from Census URLs.

- staging_dir:

  Character. Local directory for cached source files. Default:
  `"data/hu"`.

## Value

A data frame with columns: `geoid`, `year`, `value` (total housing
units).
