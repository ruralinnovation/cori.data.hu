#' Pull total housing unit estimates
#'
#' Reads raw Census housing unit Excel files and returns total housing unit
#' counts in the five-column tidy format.
#'
#' @param vintage_year Integer. Vintage year to download. Default: auto-detected
#'   from Census URLs.
#' @param staging_dir Character. Local staging directory. Default: \code{"data/hu"}.
#'
#' @return A data frame: \code{geoid}, \code{year}, \code{variable},
#'   \code{value}, \code{agg_var}.
#'
#' @keywords internal
#' @export
pull_housing_units <- function(vintage_year = NULL, staging_dir = "data/hu") {
  read_hu_raw(vintage_year = vintage_year, staging_dir = staging_dir) |>
    dplyr::mutate(
      variable = "housing_units",
      agg_var  = NA_real_
    ) |>
    dplyr::select(geoid, year, variable, value, agg_var)
}


#' Pull housing units per 1,000 population
#'
#' Reads raw Census housing unit data, joins with a population data frame, and
#' returns units per 1,000 population in the five-column tidy format.
#'
#' @param pop_df Data frame with columns \code{geoid}, \code{year}, \code{pop}.
#'   Obtain from \code{cori.data.pep::read_pep_from_s3(variables = "population")},
#'   then rename \code{value} to \code{pop} and drop \code{variable}/\code{agg_var}.
#' @param vintage_year Integer. Vintage year to download. Default: auto-detected.
#' @param staging_dir Character. Local staging directory. Default: \code{"data/hu"}.
#'
#' @return A data frame: \code{geoid}, \code{year}, \code{variable},
#'   \code{value}, \code{agg_var}.
#'
#' @keywords internal
#' @export
pull_housing_units_per_1k <- function(pop_df, vintage_year = NULL,
                                      staging_dir = "data/hu") {
  hu <- read_hu_raw(vintage_year = vintage_year, staging_dir = staging_dir)

  hu |>
    dplyr::left_join(pop_df, by = c("geoid", "year")) |>
    dplyr::mutate(
      agg_var  = pop / 1000,
      value    = value / agg_var,
      value    = dplyr::if_else(is.infinite(value), NA_real_, value),
      agg_var  = dplyr::if_else(is.na(value), NA_real_, agg_var),
      variable = "housing_units_per_1k_people"
    ) |>
    dplyr::select(geoid, year, variable, value, agg_var)
}


#' Pull net year-over-year change in housing units
#'
#' Reads raw Census housing unit data and computes the year-over-year change
#' in total units for each geography. Returns \code{NA} for 2000 (first year),
#' 2010, and 2020. The 2010 and 2020 boundary years span different decade
#' series with different Census baselines, so the arithmetic difference is a
#' methodological jump rather than a real change in housing stock.
#'
#' @param vintage_year Integer. Vintage year to download. Default: auto-detected.
#' @param staging_dir Character. Local staging directory. Default: \code{"data/hu"}.
#'
#' @return A data frame: \code{geoid}, \code{year}, \code{variable},
#'   \code{value}, \code{agg_var}.
#'
#' @keywords internal
#' @export
pull_housing_unit_change <- function(vintage_year = NULL, staging_dir = "data/hu") {
  read_hu_raw(vintage_year = vintage_year, staging_dir = staging_dir) |>
    dplyr::mutate(
      series = dplyr::case_when(
        year <= 2009L ~ "2000s",
        year <= 2019L ~ "2010s",
        TRUE          ~ "2020s"
      )
    ) |>
    dplyr::arrange(geoid, year) |>
    dplyr::group_by(geoid, series) |>
    dplyr::mutate(value = value - dplyr::lag(value)) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      variable = "housing_unit_change",
      agg_var  = NA_real_
    ) |>
    dplyr::select(geoid, year, variable, value, agg_var)
}
