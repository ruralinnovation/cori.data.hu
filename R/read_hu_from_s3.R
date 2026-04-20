#' Return the current latest HU vintage from S3
#'
#' Reads the \code{_LATEST} pointer written by the package maintainer and
#' returns the vintage string (e.g., \code{"vintage_2024"}).
#'
#' @param s3_bucket Character. S3 bucket name. Default: \code{"cori.data.hu"}.
#' @param s3_path_prefix Character. Optional prefix. Default: \code{""}.
#'
#' @return Character. Current vintage tag (e.g., \code{"vintage_2024"}).
#'
#' @export
latest_hu_vintage <- function(s3_bucket = "cori.data.hu", s3_path_prefix = "") {
  url <- sprintf(
    "https://s3.us-east-1.amazonaws.com/%s/%sdata_processed/_LATEST",
    s3_bucket, s3_path_prefix
  )
  tryCatch(
    readLines(url, n = 1L, warn = FALSE),
    error = function(e) stop(sprintf(
      "Could not read _LATEST from s3://%s/%sdata_processed/_LATEST. Has the data been written to S3?",
      s3_bucket, s3_path_prefix
    ))
  )
}


#' Read processed housing unit data from S3
#'
#' Queries CORI's processed housing unit estimate parquet files from S3 using
#' DuckDB. Returns long-format data — one row per geoid/year/variable.
#'
#' @param vintage Character. Vintage to read, e.g. \code{"2024"}.
#'   Default: \code{"latest"}.
#' @param variables Character vector. Variables to return. Default: all.
#'   See \code{\link{get_hu_codebook}} for names.
#' @param years Integer vector. Years to return. Default: all.
#' @param geoids Character vector. FIPS codes to return. Default: all.
#' @param s3_bucket Character. S3 bucket name. Default: \code{"cori.data.hu"}.
#' @param s3_path_prefix Character. Optional prefix. Default: \code{""}.
#'
#' @return A data frame with columns: \code{geoid}, \code{year},
#'   \code{variable}, \code{value}, \code{agg_var}.
#'
#' @seealso \code{\link{latest_hu_vintage}}, \code{\link{get_hu_codebook}}
#'
#' @examples
#' \dontrun{
#' # All data, latest vintage
#' df <- read_hu_from_s3()
#'
#' # Specific years and geoids
#' df <- read_hu_from_s3(years = 2020:2024, geoids = c("33009", "33", "00"))
#' }
#'
#' @export
read_hu_from_s3 <- function(
    vintage        = "latest",
    variables      = NULL,
    years          = NULL,
    geoids         = NULL,
    s3_bucket      = "cori.data.hu",
    s3_path_prefix = ""
) {

  vintage_tag <- if (vintage == "latest") {
    latest_hu_vintage(s3_bucket, s3_path_prefix)
  } else {
    if (!startsWith(vintage, "vintage_")) sprintf("vintage_%s", vintage) else vintage
  }

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  DBI::dbExecute(con, "INSTALL httpfs; LOAD httpfs;")
  DBI::dbExecute(con, "INSTALL aws;   LOAD aws;")
  DBI::dbExecute(con, sprintf("SET temp_directory = '%s';", tempdir()))
  DBI::dbExecute(con, "CREATE OR REPLACE SECRET s3_secret (
    TYPE S3,
    PROVIDER CREDENTIAL_CHAIN,
    CHAIN 'env;config',
    REGION 'us-east-1',
    URL_STYLE 'path'
  );")

  glob <- sprintf(
    "s3://%s/%sdata_processed/%s/**/*.parquet",
    s3_bucket, s3_path_prefix, vintage_tag
  )
  query <- sprintf(
    "SELECT geoid, year, variable, value, agg_var FROM read_parquet('%s', hive_partitioning = true)",
    glob
  )

  where <- character(0)
  if (!is.null(geoids)) {
    where <- c(where, sprintf("geoid IN (%s)", paste0("'", geoids, "'", collapse = ", ")))
  }
  if (!is.null(years)) {
    where <- c(where, sprintf("year IN (%s)", paste(years, collapse = ", ")))
  }
  if (!is.null(variables)) {
    where <- c(where, sprintf("variable IN (%s)", paste0("'", variables, "'", collapse = ", ")))
  }
  if (length(where) > 0) {
    query <- paste(query, "WHERE", paste(where, collapse = " AND "))
  }

  DBI::dbGetQuery(con, query) |>
    dplyr::mutate(
      geoid   = as.character(geoid),
      year    = as.integer(year),
      value   = as.numeric(value),
      agg_var = as.numeric(agg_var)
    )
}
