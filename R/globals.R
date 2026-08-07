utils::globalVariables(c(
  # Identifiers
  "geoid", "year",

  # Raw Excel column names (before processing)
  "area_name", "base_2020",

  # Intermediate wide-format year columns
  "hu_year", "hu_value",

  # tigris fips_codes columns
  "state_code", "county_code", "county", "state_name",

  # Crosswalk intermediates
  "clean_name", "state_fips", "is_county",

  # Population join
  "pop",

  # Five-column tidy contract
  "variable", "value", "agg_var",

  # Derived
  "lag_value",

  # pull_housing_unit_change
  "series"
))
