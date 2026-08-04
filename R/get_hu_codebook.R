#' Get the housing unit variable codebook
#'
#' Returns a data frame describing each variable available from
#' [get_housing_units()].
#'
#' @return A data frame with columns: `variable`, `raw_variable`, `label`,
#'   `unit`, `nominal`, `notes`.
#'   `raw_variable` is the original name stored in S3 parquet files.
#'
#' @seealso [get_housing_units()]
#'
#' @examples
#' get_hu_codebook()
#'
#' @export
get_hu_codebook <- function() {
  data.frame(
    stringsAsFactors = FALSE,

    variable = c(
      "housing_units",
      "housing_units_per_1k_people",
      "housing_unit_change"
    ),

    raw_variable = c(
      "housing_units",
      "housing_units_per_1k_people",
      "housing_unit_change"
    ),

    label = c(
      "Total housing units",
      "Housing units per 1,000 population",
      "Net change in housing units"
    ),

    unit = c(
      "units",
      "units per 1,000 persons",
      "units"
    ),

    nominal = c(FALSE, FALSE, FALSE),

    notes = c(
      paste0(
        "Annual July 1 estimate of total housing units (occupied + vacant). ",
        "Built from decennial Census baseline plus permitted construction, ",
        "non-permitted construction, mobile home shipments, and housing loss. ",
        "Coverage: 2000-present (2000-2009 intercensal, 2010-2019, 2020-present). ",
        "Geography: county (5-digit FIPS), state (2-digit FIPS), national ('00')."
      ),
      paste0(
        "Total housing units divided by population in thousands. ",
        "Population denominator from Census Population Estimates Program ",
        "via cori.data.pep. Coverage: 2000-present. ",
        "agg_var = population / 1,000, suitable for population-weighted averaging."
      ),
      paste0(
        "Year-over-year net change in total housing units. ",
        "NA for 2000, 2010, and 2020 \u2014 these boundary years span different ",
        "decade series with different Census baselines, so the arithmetic ",
        "difference reflects a methodological reset rather than real housing stock change. ",
        "Coverage: 2001-present (excluding decade boundary years)."
      )
    )
  )
}
