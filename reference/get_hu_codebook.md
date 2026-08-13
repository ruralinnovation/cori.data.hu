# Get the housing unit variable codebook

Returns a data frame describing each variable available from
[`get_housing_units()`](https://ruralinnovation.github.io/cori.data.hu/reference/get_housing_units.md).

## Usage

``` r
get_hu_codebook()
```

## Value

A data frame with columns: `variable`, `raw_variable`, `label`, `unit`,
`nominal`, `notes`. `raw_variable` is the original name stored in S3
parquet files.

## See also

[`get_housing_units()`](https://ruralinnovation.github.io/cori.data.hu/reference/get_housing_units.md)

## Examples

``` r
get_hu_codebook()
#>                      variable                raw_variable
#> 1               housing_units               housing_units
#> 2 housing_units_per_1k_people housing_units_per_1k_people
#> 3         housing_unit_change         housing_unit_change
#>                                label                    unit nominal
#> 1                Total housing units                   units   FALSE
#> 2 Housing units per 1,000 population units per 1,000 persons   FALSE
#> 3        Net change in housing units                   units   FALSE
#>                                                                                                                                                                                                                                                                                                                                                         notes
#> 1 Annual July 1 estimate of total housing units (occupied + vacant). Built from decennial Census baseline plus permitted construction, non-permitted construction, mobile home shipments, and housing loss. Coverage: 2000-present (2000-2009 intercensal, 2010-2019, 2020-present). Geography: county (5-digit FIPS), state (2-digit FIPS), national ('00').
#> 2                                                                                                                Total housing units divided by population in thousands. Population denominator from Census Population Estimates Program via cori.data.pep. Coverage: 2000-present. agg_var = population / 1,000, suitable for population-weighted averaging.
#> 3                            Year-over-year net change in total housing units. NA for 2000, 2010, and 2020 — these boundary years span different decade series with different Census baselines, so the arithmetic difference reflects a methodological reset rather than real housing stock change. Coverage: 2001-present (excluding decade boundary years).
```
