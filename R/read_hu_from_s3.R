#' Read processed housing unit data from S3
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' `read_hu_from_s3()` is deprecated. Use [get_housing_units()] instead.
#'
#' @param vintage Passed to [get_housing_units()].
#' @param variables Passed to [get_housing_units()].
#' @param years Passed to [get_housing_units()].
#' @param geoids Passed to [get_housing_units()].
#' @param s3_bucket Ignored. No longer configurable in the public API.
#' @param s3_path_prefix Ignored. No longer configurable in the public API.
#'
#' @return A data frame. See [get_housing_units()] for details.
#'
#' @seealso [get_housing_units()]
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
  .Deprecated(
    new     = "get_housing_units",
    package = "cori.data.hu",
    msg     = paste0(
      "`read_hu_from_s3()` is deprecated. Use `get_housing_units()` instead.\n",
      "  Note: `s3_bucket` and `s3_path_prefix` are no longer configurable in the public API."
    )
  )
  get_housing_units(
    years     = years,
    geoids    = geoids,
    variables = variables,
    vintage   = vintage
  )
}


#' @keywords internal
latest_hu_vintage <- function(s3_bucket = "cori.data.hu", s3_path_prefix = "") {
  .latest_hu_vintage(s3_bucket, s3_path_prefix)
}
