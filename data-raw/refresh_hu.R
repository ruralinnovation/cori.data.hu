# 1. Load the package (required — write_hu_to_s3.R calls latest_hu_vintage()
#    which lives in R/read_hu_from_s3.R)
devtools::load_all()

# 2. Set lates year an check vintage
latest_year = 2025

s3_vintageyr <- as.numeric(substr(latest_hu_vintage(), 9, 12))
if (latest_year <= s3_vintageyr) {
  message("Latest year does not reflect a new release of data")
} else {
  available_vintage_year <- .probe_latest_hu_year(latest_year)

  stopifnot(available_vintage_year >= latest_year)
  
  # 3. Test with a staging prefix before touching production
  write_hu_processed_to_s3(
    s3_path_prefix = "test/",
    sync_to_s3     = TRUE
  )

  # 4. Verify the roundtrip
  test <- read_hu_from_s3(s3_path_prefix = "test/")
  dplyr::glimpse(test)
  table(test$year)

  # 5. Write to production
  write_hu_processed_to_s3(overwrite = TRUE)
}

