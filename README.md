---
editor_options: 
  markdown: 
    wrap: 72
---

# cori.data.hu

Access and analyze U.S. Census Bureau Housing Unit Estimates at the
county, state, and national level.

------------------------------------------------------------------------

## What Is This Data?

The U.S. Census Bureau's **National, State, and County Housing Unit
Totals** (also called the Housing Unit Estimates) are annual estimates
of the total number of housing units in existence. Published under the
Population Estimates Program, they measure the total housing stock — not
just new construction activity.

This package measures housing **stock** — the total number of units that
exist at a point in time — as opposed to construction activity or
permitting flow.

**Official source name:** National, State, and County Housing Unit
Totals

**Producer:** U.S. Census Bureau, Population Estimates Program

**Vintage designation:** e.g., "Vintage 2024" covers April 1, 2020 –
July 1, 2024

**Coverage:** Annual estimates from 1970 to present (anchored to each
decennial census)

**Geography:** National, state, county (5-digit FIPS); subcounty exists
but is not publicly released

**Release cadence:** Annually, typically May

**Dataset page:**
<https://www.census.gov/data/datasets/time-series/demo/popest/2020s-total-housing-units.html>

------------------------------------------------------------------------

## How the Estimates Are Built

The Census Bureau uses a **components-of-change model** anchored to the
most recent decennial census. The full series back to the census base is
revised each vintage.

```         
2020 Census Housing Units
  + New Residential Construction  (permitted × completion rate  +  non-permitted)
  + New Mobile Homes              (Manufactured Homes Survey)
  - Housing Units Lost            (AHS-based loss rates  +  FEMA disaster losses)
= July 1 Annual Housing Unit Estimate
```

### Component Data Sources

| Component | Source | Notes |
|------------------------|------------------------|------------------------|
| Census baseline | 2020 Decennial Census | Re-tabulated annually with boundary updates (BAS) |
| Permitted construction | Building Permits Survey (BPS) | \~20,000 jurisdictions; \~98% of all new units |
| Permit completion rate | Survey of Construction (SOC) | National rate, updated annually |
| Non-permitted construction | SOC (regional) | Distributed by each place's 2020 Census HU share; West region excluded |
| Mobile homes | Manufactured Homes Survey (MHS) | July–June shipment window; distributed using ACS 5-year structure type data |
| Housing loss (baseline) | 2009/2011 American Housing Survey (AHS) | Regional rates by structure type and age — static, not updated annually |
| Natural disaster loss | FEMA disaster assistance records | Complete losses geocoded to county |

### Six-Month Permit Lag

A six-month lag between permit issuance and unit completion is a
requisite function of the data. Calendar year N permits feed into the
July 1, Year N+1 estimate. For example, 2023 permits are reflected in
the July 1, 2024 estimates.

### Federal-State Review (FSCPE)

Preliminary estimates are reviewed by the Federal-State Cooperative for
Population Estimates. States may submit local permit data, demolition
records, certificates of occupancy, housing conversions, and
reconstructions. Accepted submissions are incorporated into the final
estimates.

------------------------------------------------------------------------

## Historical Depth and Vintage System

The entire series back to the decennial census baseline is revised with
each annual vintage release. Historical series are available back to
1970, anchored to their respective census:

| Series          | Coverage     |
|-----------------|--------------|
| 2020s (current) | 2020–present |
| 2010s           | 2010–2020    |
| 2000s           | 2000–2010    |
| 1990s           | 1990–2000    |
| 1980s           | 1980–1990    |
| 1970s           | 1970–1980    |

------------------------------------------------------------------------

## Vintage Gap Analysis: 2010s vs. 2020s

The methodology is highly stable across the decade break. Cross-decade
longitudinal joins are generally sound, with one notable caveat.

| Component | 2010s (Vintage 2020) | 2020s (Vintage 2024) | Gap |
|------------------|------------------|------------------|------------------|
| Census baseline | 2010 Decennial | 2020 Decennial | Expected — resets each decade |
| Permitted construction | BPS | BPS | No change |
| Non-permitted construction | SOC, regional; no West | SOC, regional; no West | No change |
| Mobile home distribution reference | **Census 2000 long form** | **ACS 5-year file** | Changed — modernized |
| Housing loss rates | 2009/2011 AHS (static) | 2009/2011 AHS (static) | Unchanged — rates are frozen |
| FSCPE review scope | Accepted data replaces original | Accepted data replaces or supplements (conversions + reconstructions now additive) | Modest expansion |

**Important note:** The mobile home sub-state distribution reference was
updated from the Census 2000 long form to the ACS 5-year file at the
2020 decade break. For counties with significant manufactured housing,
mobile home estimates are not perfectly comparable before and after
2020. For total stock analysis at the county level, the series is
otherwise consistent from 2010 through present.

**Persistent limitation:** Housing loss rates have not been updated
since the 2009/2011 AHS. Demolition patterns and disaster exposure have
changed meaningfully since then, meaning losses may be systematically
underestimated in markets with active redevelopment or elevated natural
disaster risk.

------------------------------------------------------------------------

## Known Limitations

-   **No structure type breakdown** in the public release —
    single-family vs. multifamily is not available at this level (use
    BPS for that distinction)
-   **No vacancy or occupancy status** — this is a count of total units
    regardless of occupancy; pair with ACS for vacancy rates
-   **Loss rates are static** — derived from 2009/2011 AHS, applied
    unchanged across all vintages
-   **Non-permitted construction not distributed to the West** —
    methodology gap for Western counties without permit offices
-   **County is the smallest public geography** — subcounty (city/town)
    estimates exist internally at Census but are not released
-   **Estimates, not counts** — all values are modeled; the decennial
    census is the only direct count

------------------------------------------------------------------------

## Caution: Do Not Compute Net Change Across Decade Series

> **Do not subtract housing unit values across the 2009→2010 or
> 2019→2020 boundaries.**

This dataset is assembled from three independent Census decade series
(2000s, 2010s, 2020s), each anchored to its own decennial Census
baseline. The 2010 and 2020 values are fresh Census counts — not
continuations of the prior series estimate. Subtracting across these
boundaries produces an arithmetic difference that reflects potential
**methodological inconsistencies**, not real changes in housing stock.

For example, if the 2020 Census counted fewer units in a county than the
2010s series projected for 2019, the difference will appear as a housing
loss — even if no demolitions occurred.

**For year-over-year change analysis:** restrict to a single decade
series (e.g., 2020–2024 only) or use permit data from `cori.data.bps` as
a proxy for net new construction within a series.

------------------------------------------------------------------------

## Methodology References

-   [Dataset landing
    page](https://www.census.gov/data/datasets/time-series/demo/popest/2020s-total-housing-units.html)
-   [Vintage 2024 methodology
    (PDF)](https://www2.census.gov/programs-surveys/popest/technical-documentation/methodology/2020-2024/2024-hu-meth.pdf)
-   [Vintage 2020 methodology
    (PDF)](https://www2.census.gov/programs-surveys/popest/technical-documentation/methodology/2010-2020/2020-hu-meth_final.pdf)
-   [Building Permits Survey](https://www.census.gov/construction/bps/)
-   [Survey of
    Construction](https://www.census.gov/construction/nrc/about_the_surveys/soc.html)
-   [Manufactured Homes
    Survey](https://www.census.gov/programs-surveys/mhs.html)
-   [American Housing
    Survey](https://www.census.gov/programs-surveys/ahs/)
