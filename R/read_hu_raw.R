# Valid state FIPS codes: 50 states + DC
.HU_STATE_FIPS <- c(
  "01","02","04","05","06","08","09","10","11","12","13","15","16","17","18",
  "19","20","21","22","23","24","25","26","27","28","29","30","31","32","33",
  "34","35","36","37","38","39","40","41","42","44","45","46","47","48","49",
  "50","51","53","54","55","56"
)


# Detect the latest available 2020s vintage year by probing Census URLs.
.probe_latest_hu_year <- function(year = as.integer(format(Sys.Date(), "%Y"))) {
  current_yr <- year
  for (yr in (current_yr - 1):2021) {
    url <- sprintf(
      "https://www2.census.gov/programs-surveys/popest/tables/2020-%d/housing/totals/CO-EST%d-HU-01.xlsx",
      yr, yr
    )
    ok <- tryCatch({
      con <- url(url, open = "r")
      close(con)
      TRUE
    }, error = function(e) FALSE)
    if (ok) return(yr)
  }
  stop("Could not detect latest HU vintage year from Census URL.")
}


# Generic cached download. Skips if dest already exists.
.download_cached <- function(url, dest) {
  if (file.exists(dest)) {
    message(sprintf("Already cached: %s", basename(dest)))
    return(invisible(dest))
  }
  message(sprintf("Downloading %s...", basename(dest)))
  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout), add = TRUE)
  options(timeout = 300)
  utils::download.file(url, dest, mode = "wb", quiet = TRUE)
  invisible(dest)
}


.download_hu_2020s <- function(state_fips, vintage_year, staging_dir) {
  .download_cached(
    url  = sprintf(
      "https://www2.census.gov/programs-surveys/popest/tables/2020-%d/housing/totals/CO-EST%d-HU-%s.xlsx",
      vintage_year, vintage_year, state_fips
    ),
    dest = file.path(staging_dir, sprintf("CO-EST%d-HU-%s.xlsx", vintage_year, state_fips))
  )
}

.download_hu_2010s <- function(state_fips, staging_dir) {
  .download_cached(
    url  = sprintf(
      "https://www2.census.gov/programs-surveys/popest/tables/2010-2019/housing/totals/CO-EST2019-ANNHU-%s.xlsx",
      state_fips
    ),
    dest = file.path(staging_dir, sprintf("CO-EST2019-ANNHU-%s.xlsx", state_fips))
  )
}

.download_hu_2000s <- function(state_fips, staging_dir) {
  .download_cached(
    url  = sprintf(
      "https://www2.census.gov/programs-surveys/popest/tables/2000-2010/intercensal/housing/hu-est00int-02-%s.csv",
      state_fips
    ),
    dest = file.path(staging_dir, sprintf("hu-est00int-02-%s.csv", state_fips))
  )
}


# Build a county name -> GEOID crosswalk using tigris::fips_codes.
# Returns a data frame with columns: state_code, clean_name, geoid.
.hu_county_xwalk <- function() {
  if (!requireNamespace("tigris", quietly = TRUE)) {
    stop(
      "tigris is required to build the county crosswalk. ",
      "Install with: install.packages('tigris')"
    )
  }
  tigris::fips_codes |>
    dplyr::mutate(
      geoid      = paste0(state_code, county_code),
      clean_name = county
    ) |>
    dplyr::select(state_code, clean_name, geoid)
}


# Shared parser for 2010s and 2020s Excel files.
# n_prefix_cols: number of non-year columns after area_name to skip
#   (1 for 2020s: base_2020; 2 for 2010s: census_2010 + est_base_2010)
.parse_hu_excel_state <- function(path, year_range, n_prefix_cols, state_fips, xwalk) {
  col_names <- c(
    "area_name",
    paste0("skip_", seq_len(n_prefix_cols)),
    paste0("hu_", year_range)
  )

  raw <- tryCatch(
    readxl::read_excel(
      path, skip = 4, col_names = col_names,
      col_types = c("text", rep("numeric", n_prefix_cols + length(year_range)))
    ),
    error = function(e) {
      warning(sprintf("Could not read %s: %s", basename(path), e$message))
      return(NULL)
    }
  )
  if (is.null(raw)) return(NULL)

  .parse_hu_state_rows(raw, year_range, state_fips, xwalk)
}


# Parser for 2000s intercensal CSV files.
# Structure (after skip=4): area_name, base_2000, hu_2000..hu_2009, base_2010, hu_2010_july
# Values are comma-formatted strings (e.g. "546,973") — must strip commas.
.parse_hu_2000s_csv_state <- function(path, state_fips, xwalk) {
  year_range <- 2000:2009

  col_names <- c(
    "area_name", "base_2000",
    paste0("hu_", year_range),
    "base_2010", "skip_jul_2010"
  )

  raw <- tryCatch({
    df <- utils::read.csv(path, skip = 4, header = FALSE, stringsAsFactors = FALSE,
                          col.names = col_names, check.names = FALSE,
                          na.strings = c("", "NA"), fill = TRUE)
    # Strip commas from numeric columns and coerce
    for (col in col_names[-1]) {
      if (col %in% names(df)) {
        df[[col]] <- as.numeric(gsub(",", "", df[[col]]))
      }
    }
    df
  }, error = function(e) {
    warning(sprintf("Could not read %s: %s", basename(path), e$message))
    return(NULL)
  })
  if (is.null(raw)) return(NULL)

  .parse_hu_state_rows(raw, year_range, state_fips, xwalk)
}


# Shared row-processing logic: identify state/county rows, assign GEOIDs,
# pivot to long format. Returns a data frame with columns: geoid, year, value.
.parse_hu_state_rows <- function(raw, year_range, state_fips, xwalk) {
  # Drop NA and footnote rows
  raw <- raw[
    !is.na(raw$area_name) &
    !grepl("^[[:digit:]]|^Note|^Suggested|^Source", raw$area_name),
  ]
  if (nrow(raw) == 0) return(NULL)

  raw$is_county <- startsWith(raw$area_name, ".")

  # State row
  state_row        <- raw[!raw$is_county, ][1, ]
  state_row$geoid  <- state_fips

  # County rows
  county_rows <- raw[raw$is_county, ]
  if (nrow(county_rows) > 0) {
    county_rows$clean_name <- stringr::str_remove(county_rows$area_name, "^\\.") |>
      stringr::str_remove(",\\s+[^,]+$")
    county_rows <- dplyr::left_join(
      county_rows,
      xwalk[xwalk$state_code == state_fips, c("clean_name", "geoid")],
      by = "clean_name"
    )
  }

  hu_cols <- paste0("hu_", year_range)

  dplyr::bind_rows(state_row, county_rows) |>
    dplyr::select(geoid, dplyr::all_of(hu_cols)) |>
    dplyr::filter(!is.na(geoid)) |>
    tidyr::pivot_longer(
      cols      = dplyr::all_of(hu_cols),
      names_to  = "hu_year",
      values_to = "value"
    ) |>
    dplyr::mutate(
      year  = as.integer(stringr::str_remove(hu_year, "^hu_")),
      value = as.numeric(value),
      geoid = as.character(geoid)
    ) |>
    dplyr::select(geoid, year, value) |>
    dplyr::filter(!is.na(value))
}


# Read all 51 state files for each decade series.
.read_hu_2020s <- function(vintage_year, staging_dir, xwalk) {
  message(sprintf("  Reading 2020s series (2020\u2013%d)...", vintage_year))
  lapply(.HU_STATE_FIPS, function(sfips) {
    path <- .download_hu_2020s(sfips, vintage_year, staging_dir)
    .parse_hu_excel_state(path, 2020:vintage_year, n_prefix_cols = 1, sfips, xwalk)
  }) |> dplyr::bind_rows()
}

.read_hu_2010s <- function(staging_dir, xwalk) {
  message("  Reading 2010s series (2010\u20132019)...")
  lapply(.HU_STATE_FIPS, function(sfips) {
    path <- .download_hu_2010s(sfips, staging_dir)
    .parse_hu_excel_state(path, 2010:2019, n_prefix_cols = 2, sfips, xwalk)
  }) |> dplyr::bind_rows()
}

.read_hu_2000s <- function(staging_dir, xwalk) {
  message("  Reading 2000s series (2000\u20132009)...")
  lapply(.HU_STATE_FIPS, function(sfips) {
    path <- .download_hu_2000s(sfips, staging_dir)
    .parse_hu_2000s_csv_state(path, sfips, xwalk)
  }) |> dplyr::bind_rows()
}


#' Read raw housing unit estimates from Census source files
#'
#' Downloads (if needed) and parses Census housing unit files across all
#' available decades: 2000-2009 (intercensal CSV), 2010-2019 (Excel), and
#' 2020-present (Excel). Returns a long-format data frame with one row per
#' geoid/year, including county, state, and national totals.
#'
#' @param vintage_year Integer. Latest vintage year for the 2020s series.
#'   Default: auto-detected from Census URLs.
#' @param staging_dir Character. Local directory for cached source files.
#'   Default: \code{"data/hu"}.
#'
#' @return A data frame with columns: \code{geoid}, \code{year}, \code{value}
#'   (total housing units).
#'
#' @keywords internal
read_hu_raw <- function(vintage_year = NULL, staging_dir = "data/hu") {

  if (is.null(vintage_year)) vintage_year <- .probe_latest_hu_year()
  dir.create(staging_dir, recursive = TRUE, showWarnings = FALSE)
  xwalk <- .hu_county_xwalk()

  message("Downloading and parsing housing unit source files...")
  s2000 <- .read_hu_2000s(staging_dir, xwalk)
  s2010 <- .read_hu_2010s(staging_dir, xwalk)
  s2020 <- .read_hu_2020s(vintage_year, staging_dir, xwalk)

  county_state <- dplyr::bind_rows(s2000, s2010, s2020)

  # National total: sum of state rows (2-digit geoids) per year
  national <- county_state |>
    dplyr::filter(nchar(geoid) == 2) |>
    dplyr::group_by(year) |>
    dplyr::summarise(value = sum(value, na.rm = TRUE), .groups = "drop") |>
    dplyr::mutate(geoid = "00")

  dplyr::bind_rows(county_state, national)
}
