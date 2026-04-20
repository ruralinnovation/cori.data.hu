# latest_hu_vintage() lives in the package (R/read_hu_from_s3.R).
# Run devtools::load_all() before executing this script.

#' Write processed housing unit data to S3
#'
#' Downloads Census per-state housing unit Excel files, computes two variables
#' (\code{housing_units}, \code{housing_units_per_1k_people}), and writes
#' vintage-tagged parquet files to S3.
#'
#' Requires the \code{cori.data.pep} package and AWS credentials in the
#' environment (via \code{AWS_ACCESS_KEY_ID}/\code{AWS_SECRET_ACCESS_KEY} or
#' an AWS config profile).
#'
#' @param vintage_year Integer. Vintage year to download. Default: auto-detected
#'   from Census URLs.
#' @param staging_dir Character. Local directory for cached Excel files and
#'   intermediate parquet output. Default: \code{"data/hu"}.
#' @param s3_bucket Character. S3 bucket name. Default: \code{"cori.data.hu"}.
#' @param s3_path_prefix Character. Optional prefix for all S3 keys, e.g.
#'   \code{"test/"} during development. Default: \code{""}.
#' @param overwrite Logical. If \code{TRUE}, delete the existing S3 prefix
#'   before uploading. Default: \code{FALSE}.
#' @param sync_to_s3 Logical. Upload to S3. Set \code{FALSE} to write locally
#'   only. Default: \code{TRUE}.
#'
#' @return Invisibly, a list with \code{vintage} and \code{n_rows}.
#'
#' @keywords internal
#' @export
write_hu_processed_to_s3 <- function(
    vintage_year   = NULL,
    staging_dir    = "data/hu",
    s3_bucket      = "cori.data.hu",
    s3_path_prefix = "",
    overwrite      = FALSE,
    sync_to_s3     = TRUE
) {

  if (!requireNamespace("cori.data.pep", quietly = TRUE)) {
    stop(
      "cori.data.pep is required to compute housing_units_per_1k_people. ",
      "Install with: remotes::install_github('ruralinnovation/cori.data.pep')"
    )
  }

  if (is.null(vintage_year)) vintage_year <- .probe_latest_hu_year()
  message(sprintf("Vintage year: %d", vintage_year))

  # --- Population denominator from cori.data.pep ---
  message("Pulling population from cori.data.pep...")
  pop_raw <- cori.data.pep::read_pep_from_s3(
    variables = "population",
    years     = 2000:vintage_year
  )

  pop_county <- pop_raw |>
    dplyr::filter(nchar(geoid) == 5) |>
    dplyr::select(geoid, year, pop = value)

  pop_state <- pop_county |>
    dplyr::mutate(geoid = substr(geoid, 1, 2)) |>
    dplyr::group_by(geoid, year) |>
    dplyr::summarise(pop = sum(pop, na.rm = TRUE), .groups = "drop")

  pop_national <- pop_county |>
    dplyr::group_by(year) |>
    dplyr::summarise(pop = sum(pop, na.rm = TRUE), .groups = "drop") |>
    dplyr::mutate(geoid = "00")

  pop_df <- dplyr::bind_rows(pop_county, pop_state, pop_national)

  # --- Pull two metrics ---
  message("Pulling housing_units...")
  hu <- pull_housing_units(vintage_year = vintage_year, staging_dir = staging_dir)

  message("Computing housing_units_per_1k_people...")
  per_1k <- pull_housing_units_per_1k(pop_df = pop_df,
                                       vintage_year = vintage_year,
                                       staging_dir = staging_dir)

  processed   <- dplyr::bind_rows(hu, per_1k)
  vintage_tag <- sprintf("vintage_%d", vintage_year)

  message(sprintf("Vintage: %s | Rows: %s", vintage_tag,
                  format(nrow(processed), big.mark = ",")))

  # --- Write parquet locally, partitioned by year ---
  out_dir <- file.path(staging_dir, "s3_processed", vintage_tag)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  DBI::dbWriteTable(con, "processed", processed, overwrite = TRUE)
  DBI::dbExecute(con, sprintf(
    "COPY processed TO '%s' (FORMAT 'parquet', PARTITION_BY (year), OVERWRITE_OR_IGNORE)",
    out_dir
  ))

  # --- _LATEST pointer ---
  latest_dir  <- file.path(staging_dir, "s3_processed")
  latest_file <- file.path(latest_dir, "_LATEST")
  writeLines(vintage_tag, latest_file)

  # --- Upload to S3 ---
  if (sync_to_s3) {
    s3_prefix <- sprintf("%sdata_processed/%s/", s3_path_prefix, vintage_tag)

    if (overwrite) {
      s3_uri <- sprintf("s3://%s/%s", s3_bucket, s3_prefix)
      message(sprintf("Deleting existing S3 prefix: %s", s3_uri))
      base::system2("aws", args = c("s3", "rm", s3_uri, "--recursive"))
    }

    .upload_to_s3(s3_bucket, s3_prefix, out_dir)
    .upload_to_s3(
      s3_bucket,
      sprintf("%sdata_processed/_LATEST", s3_path_prefix),
      latest_file
    )
    message(sprintf("_LATEST updated to: %s", vintage_tag))
  }

  invisible(list(vintage = vintage_tag, n_rows = nrow(processed)))
}


# Internal: upload a directory or single file to S3 via AWS CLI.
.upload_to_s3 <- function(s3_bucket, s3_prefix, local_path) {
  s3_uri <- sprintf("s3://%s/%s", s3_bucket, s3_prefix)
  message(sprintf("Uploading to %s...", s3_uri))

  if (isTRUE(file.info(local_path)$isdir)) {
    exit_code <- base::system2("aws", args = c("s3", "sync", local_path, s3_uri))
  } else {
    exit_code <- base::system2("aws", args = c("s3", "cp", local_path, s3_uri))
  }

  if (exit_code != 0) stop(sprintf("AWS CLI upload failed: %s -> %s", local_path, s3_uri))
}
