# Write processed housing unit data to S3

Downloads Census per-state housing unit Excel files, computes three
variables (`housing_units`, `housing_units_per_1k_people`,
`housing_unit_change`), and writes vintage-tagged parquet files to S3.

## Usage

``` r
write_hu_processed_to_s3(
  vintage_year = NULL,
  staging_dir = "data/hu",
  s3_bucket = "cori.data.hu",
  s3_path_prefix = "",
  overwrite = FALSE,
  sync_to_s3 = TRUE
)
```

## Arguments

- vintage_year:

  Integer. Vintage year to download. Default: auto-detected from Census
  URLs.

- staging_dir:

  Character. Local directory for cached Excel files and intermediate
  parquet output. Default: `"data/hu"`.

- s3_bucket:

  Character. S3 bucket name. Default: `"cori.data.hu"`.

- s3_path_prefix:

  Character. Optional prefix for all S3 keys, e.g. `"test/"` during
  development. Default: `""`.

- overwrite:

  Logical. If `TRUE`, delete the existing S3 prefix before uploading.
  Default: `FALSE`.

- sync_to_s3:

  Logical. Upload to S3. Set `FALSE` to write locally only. Default:
  `TRUE`.

## Value

Invisibly, a list with `vintage` and `n_rows`.

## Details

Requires the `cori.data.pep` package and AWS credentials in the
environment (via `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` or an AWS
config profile).
