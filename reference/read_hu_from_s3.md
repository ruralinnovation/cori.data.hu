# Read processed housing unit data from S3

**\[deprecated\]**

`read_hu_from_s3()` is deprecated. Use
[`get_housing_units()`](https://ruralinnovation.github.io/cori.data.hu/reference/get_housing_units.md)
instead.

## Usage

``` r
read_hu_from_s3(
  vintage = "latest",
  variables = NULL,
  years = NULL,
  geoids = NULL,
  s3_bucket = "cori.data.hu",
  s3_path_prefix = ""
)
```

## Arguments

- vintage:

  Passed to
  [`get_housing_units()`](https://ruralinnovation.github.io/cori.data.hu/reference/get_housing_units.md).

- variables:

  Passed to
  [`get_housing_units()`](https://ruralinnovation.github.io/cori.data.hu/reference/get_housing_units.md).

- years:

  Passed to
  [`get_housing_units()`](https://ruralinnovation.github.io/cori.data.hu/reference/get_housing_units.md).

- geoids:

  Passed to
  [`get_housing_units()`](https://ruralinnovation.github.io/cori.data.hu/reference/get_housing_units.md).

- s3_bucket:

  Ignored. No longer configurable in the public API.

- s3_path_prefix:

  Ignored. No longer configurable in the public API.

## Value

A data frame. See
[`get_housing_units()`](https://ruralinnovation.github.io/cori.data.hu/reference/get_housing_units.md)
for details.

## See also

[`get_housing_units()`](https://ruralinnovation.github.io/cori.data.hu/reference/get_housing_units.md)
