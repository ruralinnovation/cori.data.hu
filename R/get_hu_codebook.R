#' Get the housing unit variable codebook
#'
#' Returns a data frame describing each variable available from
#' \code{\link{read_hu_from_s3}}.
#'
#' @return A data frame with columns: \code{variable}, \code{label},
#'   \code{unit}, \code{nominal}, \code{notes}.
#'
#' @seealso \code{\link{read_hu_from_s3}}
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
      "housing_units_per_1k_people"
    ),
    label = c(
      "Total housing units",
      "Housing units per 1,000 population"
    ),
    unit = c(
      "units",
      "units per 1,000 persons"
    ),
    nominal = c(
      FALSE,
      FALSE
    ),
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
      )
    )
  )
}
