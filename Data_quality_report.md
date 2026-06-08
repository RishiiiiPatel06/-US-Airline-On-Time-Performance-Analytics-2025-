# Data Quality Report
**Project:** P1 Airline Analytics  
**Dataset:** BTS On-Time Performance 2025  
**Database:** Neon PostgreSQL (Cloud)  
**Checked:** Phase 1 — Data Setup

---

## Summary

All quality checks passed. The database is clean and ready for analytics.

| Check | Result |
|---|---|
| Row counts match across tables | ✅ Pass |
| Null values in critical columns | ✅ 0 nulls |
| Duplicate flights | ✅ 0 duplicates |
| Outlier detection | ✅ Reviewed |
| All 12 months present | ✅ Pass |
| Referential integrity | ✅ Pass |

---

## 1. Row Counts

| Table | Rows |
|---|---|
| flights | 480,000 |
| delays | 480,000 |
| airports | 351 |
| carriers | 14 |

Flights and delays tables have identical row counts — every flight
has exactly one delay breakdown record. ✅

---

## 2. Null Check

All critical columns checked for missing values:

| Column | Null Count | Status |
|---|---|---|
| carrier_code | 0 | ✅ Clean |
| origin | 0 | ✅ Clean |
| dest | 0 | ✅ Clean |
| flight_date | 0 | ✅ Clean |
| arr_delay_min | 0 | ✅ Clean |
| dep_delay_min | 0 | ✅ Clean |
| distance | 0 | ✅ Clean |
| air_time | 0 | ✅ Clean |

> **Note:** Delay columns (carrier_delay, weather_delay etc.) had NaN
> in the raw BTS file for non-delayed flights. These were filled with 0
> during ETL — a flight with no delay has 0 delay minutes, not NULL.

---

## 3. Duplicate Check

```sql
SELECT COUNT(*) FROM (
    SELECT carrier_code, flight_number, flight_date, origin, dest,
           COUNT(*) AS cnt
    FROM flights
    GROUP BY carrier_code, flight_number, flight_date, origin, dest
    HAVING COUNT(*) > 1
) t;
```

**Result: 0 duplicate flight combinations found.** ✅

---

## 4. Outlier Detection

| Check | Count | Action |
|---|---|---|
| Arrival delay > 500 min | Small number | Retained — verified as real BTS edge cases |
| Arrival delay < -120 min | Small number | Retained — early arrivals are valid |
| Distance = 0 or NULL | 0 | ✅ No issue |
| Air time = 0 or NULL | 0 | ✅ No issue |
| Cancelled flight with delay > 0 | 0 | ✅ No issue |

**Max arrival delay: 3,275 minutes (~54 hours)**  
This is an extreme but real edge case in BTS data — a flight
significantly diverted or grounded. Retained in dataset.
Flagged in analysis where relevant.

---

## 5. Date Range and Monthly Coverage

**Full range:** 2025-01-01 → 2025-12-31

| Month | Flights | Cancelled |
|---|---|---|
| 2025-01 | 40,000 | ~600 |
| 2025-02 | 40,000 | ~560 |
| 2025-03 | 40,000 | ~590 |
| 2025-04 | 40,000 | ~570 |
| 2025-05 | 40,000 | ~580 |
| 2025-06 | 40,000 | ~620 |
| 2025-07 | 40,000 | ~640 |
| 2025-08 | 40,000 | ~600 |
| 2025-09 | 40,000 | ~550 |
| 2025-10 | 40,000 | ~540 |
| 2025-11 | 40,000 | ~570 |
| 2025-12 | 40,000 | ~700 |

All 12 months present. Balanced sampling (40,000/month) ensures
no month is over or under-represented in analysis. ✅

---

## 6. Referential Integrity

| Check | Count | Status |
|---|---|---|
| Flights missing delay record | 0 | ✅ Pass |
| Flights with unknown carrier | 0 | ✅ Pass |
| Flights with unknown origin airport | 0 | ✅ Pass |
| Flights with unknown dest airport | 0 | ✅ Pass |

All foreign key relationships are intact across all 4 tables. ✅

---

## ETL Cleaning Steps Applied

1. Selected 23 of 38 raw columns — only columns needed for analysis
2. Renamed all columns to snake_case for consistency
3. Converted `FlightDate` to proper `DATE` type
4. Filled NaN in all delay columns with `0`
5. Filled NaN in `cancelled` and `diverted` with `0`, cast to `INT`
6. Filled NaN in `cancellation_code` with `'N'` (not cancelled)
7. Dropped rows with null `origin`, `dest`, or `carrier_code`
8. Applied balanced monthly sampling (40K rows/month, random_state=42)
9. Assigned sequential `flight_id` primary key

---

*Quality checks performed using: `notebooks/02_data_quality.ipynb`*
