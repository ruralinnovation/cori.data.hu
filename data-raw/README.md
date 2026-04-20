# data-raw

Maintainer-only scripts for downloading Census source files, processing them,
and writing the output to S3. These files are excluded from the installed
package (`data-raw/` is listed in `.Rbuildignore`).

---

## When to Run

Run these scripts annually after the Census Bureau releases new Housing Unit
Estimates — typically **May each year**. Watch the release schedule at:
https://www.census.gov/programs-surveys/popest/about/schedule.html

---

## Prerequisites

- AWS credentials configured (env vars or `~/.aws/credentials`)
- R packages installed: `cori.data.pep`, `readxl`, `stringr`, `tidyr`, `tigris`, `dplyr`, `duckdb`, `DBI`
- Working directory set to the package root

---

## Scripts

| File | Purpose |
|---|---|
| `read_hu_raw.R` | Downloads per-state Census source files and parses them into a long-format data frame (`geoid`, `year`, `value`) |
| `process_hu.R` | Derives the two output variables from the raw data |
| `write_hu_to_s3.R` | Orchestrates the full pipeline and writes parquet files to S3 |
| `globals.R` | `globalVariables()` reference for R CMD CHECK — not sourced at runtime |

---

## How to Run

```r
# 1. Load the package (required — write_hu_to_s3.R calls latest_hu_vintage()
#    which lives in R/read_hu_from_s3.R)
devtools::load_all()

# 2. Source the maintainer scripts in order
source("data-raw/read_hu_raw.R")
source("data-raw/process_hu.R")
source("data-raw/write_hu_to_s3.R")

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
```

---

## After a Successful Write

1. Update the **Vintage Log** in `RELEASE_CALENDAR.md` with the new vintage,
   date captured, and S3 path.
2. Bump the package version in `DESCRIPTION` if warranted.
3. Commit and push.
