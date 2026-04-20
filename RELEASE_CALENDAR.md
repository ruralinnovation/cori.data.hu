# Release Calendar — cori.data.hu

## Source Information

| Field | Detail |
|---|---|
| **Full name** | National, State, and County Housing Unit Totals |
| **Producer** | U.S. Census Bureau, Population Estimates Program |
| **Program page** | https://www.census.gov/data/datasets/time-series/demo/popest/2020s-total-housing-units.html |
| **Methodology** | https://www2.census.gov/programs-surveys/popest/technical-documentation/methodology/2020-2024/2024-hu-meth.pdf |
| **Coverage** | Nation, state, county · 2000–present · Annual July 1 estimates |
| **Release cadence** | Annually, typically May |
| **Source files** | 2000–2009: per-state CSV `hu-est00int-02-{fips}.csv` · 2010–2019: per-state Excel `CO-EST2019-ANNHU-{fips}.xlsx` · 2020–present: per-state Excel `CO-EST{YYYY}-HU-{fips}.xlsx` |
| **S3 bucket** | `cori.data.hu` |

## Vintage Log

| Vintage | Data covers | Captured | By | S3 path |
|---|---|---|---|---|
| vintage_2024 | 2000–2024 | 2026-04-20 | Drew Rosebush | `s3://cori.data.hu/data_processed/vintage_2024/` · 2 variables: `housing_units`, `housing_units_per_1k_people` |

## Next Capture

| Field | Detail |
|---|---|
| **Expected release** | May 2026 (for 2025 annual data) |
| **Responsible** | Drew Rosebush |
| **Task** | Run `write_hu_processed_to_s3()` after Census release |
| **Watch** | https://www.census.gov/programs-surveys/popest/about/schedule.html |

## Vintage Gap Notes

The methodology is consistent across the 2020s series. Key caveats when
extending to earlier decades:

- **Mobile home distribution** changed at the 2020 decade break: the 2010s
  series used the Census 2000 long form; the 2020s series uses the ACS 5-year
  file. Sub-state mobile home estimates are not perfectly comparable before and
  after 2020.
- **Housing loss rates** are static across all vintages, derived from the
  2009/2011 American Housing Survey. They have not been updated since.
- The full series back to the decennial census baseline is revised with each
  annual vintage release.
