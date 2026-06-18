# Data Quality Report

**Project:** US Airline On-Time Performance Analytics (2025)
**Dataset:** BTS On-Time Performance Reporting, full year 2025, stratified sample
**Pipeline stage:** Post-ETL, pre-analysis validation

---

## 1. Scope of the Check

After the ETL pipeline loaded data into the 4 normalized PostgreSQL tables (`carriers`, `airports`, `flights`, `delays`), a dedicated validation notebook (`notebooks/02_data_quality.ipynb`) ran a structured set of checks before any analysis or dashboard work began. The goal was to confirm the dataset was complete, internally consistent, and safe to build on — not just "loaded without errors."

---

## 2. Volume & Coverage Checks

| Check | Result | Pass/Fail |
|---|---|---|
| Total flights loaded | 480,000 | ✅ |
| Expected rows (40,000 × 12 months) | 480,000 | ✅ Match |
| All 12 months present | Jan–Dec 2025, all represented | ✅ |
| Date range | 2025-01-01 → 2025-12-31 | ✅ |
| Unique carriers | 14 | ✅ |
| Unique airports | 351 | ✅ |
| Unique routes (origin–dest pairs) | ~6,489–7,000 | ✅ |

The stratified sampling approach (40,000 flights per month) was verified to hold exactly — every month contributes an equal share, which preserves seasonal patterns for downstream analysis without over- or under-representing any time period.

---

## 3. Completeness Checks (Nulls)

| Column | Expected nulls | Observed nulls | Notes |
|---|---|---|---|
| `flight_id`, `carrier_code`, `flight_date`, `origin`, `dest` | 0 | 0 | Core identifiers — must never be null |
| `dep_delay_min`, `arr_delay_min` | 0 | 0 | Filled/validated during ETL |
| `cancellation_code` | High, for non-cancelled flights | Expected — stored as `'N'` for non-cancelled flights rather than null | Verified consistent — not a data quality issue |
| `carrier_delay`, `weather_delay`, `nas_delay`, `security_delay`, `late_aircraft_delay` | High (only populated when a flight is delayed ≥15 min) | Matches expectation | Nulls here mean "not a contributing cause," not missing data — filled with 0 during ETL rather than dropped |

No nulls were found in any column where a null would indicate a genuine data problem (IDs, dates, route fields). The high null rate in delay-cause columns is expected behavior per BTS's own reporting standard, not a defect.

---

## 4. Uniqueness & Duplication Checks

| Check | Result | Pass/Fail |
|---|---|---|
| Duplicate `flight_id` values | 0 | ✅ |
| Fully duplicate rows | 0 | ✅ |
| Flights missing a corresponding `delays` record | 0 | ✅ |

Every flight has exactly one matching delay record, confirming the 1-to-1 join between `flights` and `delays` is clean.

---

## 5. Referential Integrity

| Relationship | Check | Result |
|---|---|---|
| `flights.carrier_code` → `carriers.carrier_code` | All values resolve | ✅ Pass |
| `flights.origin` → `airports.airport_code` | All values resolve | ✅ Pass |
| `flights.dest` → `airports.airport_code` | All values resolve | ✅ Pass |
| `delays.flight_id` → `flights.flight_id` | All values resolve | ✅ Pass |

No orphaned foreign keys were found in either direction (no flight referencing a non-existent carrier/airport, and no delay record referencing a non-existent flight).

---

## 6. Outlier & Range Checks

| Column | Min | Max | Notes |
|---|---|---|---|
| `arr_delay_min` | (negative values = early arrivals, valid) | 3,275 min (~54 hours) | Extreme but genuine BTS edge case — not a data entry error. Retained; flagged in analysis whenever it materially skews an average. |
| `distance` | — | — | Cross-validated against `air_time`: 0.98 correlation, confirming physically consistent values |
| `cancelled`, `diverted` | 0/1 | 0/1 | Binary flags, no invalid values found |

Using the IQR method during EDA, the delay columns showed a heavy right-skew (skewness ≈ 11.2, kurtosis ≈ 233) — a large share of outlier-flagged values, but on inspection these reflect a real, known characteristic of flight delay data (most flights on-time, a thin tail of severely delayed flights) rather than data entry errors. No outlier rows were removed; they were retained and explicitly accounted for in summary statistics (e.g., reporting both mean and median delay).

---

## 7. Cross-Table Consistency

| Check | Result |
|---|---|
| Cancellation rate from `flights.cancelled` matches cancellation reason breakdown in `flights.cancellation_code` | ✅ Consistent — 7,124 cancelled flights (1.48%), all carrying a valid reason code (A/B/C/D) |
| Carrier names in `carriers` table match all `carrier_code` values used in `flights` | ✅ All 14 carriers accounted for |

---

## 8. Summary

| Metric | Value |
|---|---|
| Total flights | 480,000 |
| Cancelled flights | 7,124 (1.48%) |
| Diverted flights | 1,317 (0.27%) |
| Average arrival delay | 16.81 min (median 0 min) |
| Null values in critical columns | 0 |
| Duplicate flights | 0 |
| Referential integrity | 100% pass |

**Conclusion:** the dataset passed all structural and consistency checks with no critical issues. The one notable characteristic — a small number of extreme delay outliers (max 3,275 min) — was investigated and confirmed to be a genuine, retained edge case rather than a defect, and is explicitly called out wherever it could otherwise mislead an average-based metric (e.g., presenting both mean and median delay rather than mean alone).
