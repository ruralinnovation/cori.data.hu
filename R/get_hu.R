#' Get Census Bureau housing unit estimates
#'
#' Returns housing unit estimates from the U.S. Census Bureau's National,
#' State, and County Housing Unit Totals. Data cover 2000–present at annual
#' frequency for county, state, and national geographies.
#'
#' @param geography Character. Geographic level to return: `"all"`, `"county"`,
#'   `"state"`, or `"nation"`. Ignored when `geoids` is provided. Default: `"all"`.
#' @param years Integer vector. Years to return. Default: all available.
#' @param geoids Character vector. FIPS codes to return (5-digit county,
#'   2-digit state, or `"00"` for national). When provided, takes precedence
#'   over `geography`. Default: `NULL` (all geographies).
#' @param variables Character vector. Variables to return: `"housing_units"`,
#'   `"housing_units_per_1k_people"`, and/or `"housing_unit_change"`.
#'   Default: all. See [get_hu_codebook()] for details.
#' @param vintage Character. Vintage to read, e.g. `"2024"`. Default: `"latest"`.
#'
#' @return A data frame with columns: `geoid`, `year`, `variable`, `value`,
#'   `agg_var`. `agg_var` is population / 1,000 for `housing_units_per_1k_people`
#'   (suitable for population-weighted averaging) and `NA` for count variables.
#'
#' @seealso [get_hu_codebook()]
#'
#' @examples
#' \dontrun{
#' # All county-level housing unit estimates
#' get_housing_units(geography = "county", years = 2010:2024)
#'
#' # Specific county — Grafton County, NH
#' get_housing_units(geoids = "33009")
#'
#' # Housing units per 1,000 population, state level
#' get_housing_units(geography = "state", variables = "housing_units_per_1k_people")
#' }
#'
#' @export
get_housing_units <- function(
    geography = c("all", "county", "state", "nation"),
    years     = NULL,
    geoids    = NULL,
    variables = NULL,
    vintage   = "latest"
) {
  geography <- match.arg(geography)

  valid_vars <- c("housing_units", "housing_units_per_1k_people", "housing_unit_change")
  if (!is.null(variables)) {
    unknown <- setdiff(variables, valid_vars)
    if (length(unknown) > 0) {
      stop(sprintf(
        "Unknown variable(s): %s\nValid options: %s",
        paste(unknown, collapse = ", "),
        paste(valid_vars, collapse = ", ")
      ))
    }
  }

  vintage_tag <- if (vintage == "latest") {
    .latest_hu_vintage()
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

  glob  <- sprintf(
    "s3://cori.data.hu/data_processed/%s/**/*.parquet",
    vintage_tag
  )
  query <- sprintf(
    "SELECT geoid, year, variable, value, agg_var FROM read_parquet('%s', hive_partitioning = true)",
    glob
  )

  where <- character(0)
  if (!is.null(variables)) {
    where <- c(where, sprintf("variable IN (%s)", paste0("'", variables, "'", collapse = ", ")))
  }
  if (!is.null(geoids)) {
    where <- c(where, sprintf("geoid IN (%s)", paste0("'", geoids, "'", collapse = ", ")))
  }
  if (!is.null(years)) {
    where <- c(where, sprintf("year IN (%s)", paste(years, collapse = ", ")))
  }
  if (length(where) > 0) {
    query <- paste(query, "WHERE", paste(where, collapse = " AND "))
  }

  df <- DBI::dbGetQuery(con, query) |>
    dplyr::mutate(
      geoid   = as.character(geoid),
      year    = as.integer(year),
      value   = as.numeric(value),
      agg_var = as.numeric(agg_var)
    )

  # Geography filter — only applied when geoids not provided
  if (is.null(geoids) && geography != "all") {
    df <- switch(geography,
      county = df[nchar(df$geoid) == 5, ],
      state  = df[nchar(df$geoid) == 2, ],
      nation = df[df$geoid == "00", ]
    )
  }

  # User-facing message
  geo_label <- if (!is.null(geoids)) {
    n <- length(unique(geoids))
    sprintf("%d specific geograph%s", n, ifelse(n == 1, "y", "ies"))
  } else {
    switch(geography,
      all    = "All geographies",
      county = "County-level",
      state  = "State-level",
      nation = "National"
    )
  }

  yr_range <- sprintf(
    "%d\u2013%d",
    min(df$year, na.rm = TRUE),
    max(df$year, na.rm = TRUE)
  )

  message(sprintf(
    "\u2713 %s housing unit data pulled into your environment\n  Years: %s | Rows: %s | Source: Census HU Estimates (%s)",
    geo_label, yr_range, format(nrow(df), big.mark = ","), vintage_tag
  ))

  df
}


# Internal: resolve the latest vintage tag from the S3 _LATEST pointer.
.latest_hu_vintage <- function(s3_bucket = "cori.data.hu", s3_path_prefix = "") {
  url <- sprintf(
    "https://s3.us-east-1.amazonaws.com/%s/%sdata_processed/_LATEST",
    s3_bucket, s3_path_prefix
  )
  tryCatch(
    readLines(url, n = 1L, warn = FALSE),
    error = function(e) stop(sprintf(
      "Could not read _LATEST from s3://%s. Has write_hu_processed_to_s3() been run?",
      s3_bucket
    ))
  )
}
