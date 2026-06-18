# Query Optimization Report

**Project:** US Airline On-Time Performance Analytics (2025)
**Database:** PostgreSQL (Neon, serverless)
**Scope:** `SQL/06_query_optimization.sql`

> ⚠️ **Action needed:** this report is structured around your actual schema and the kinds of queries this project would run, but the specific EXPLAIN ANALYZE numbers below are placeholders. Run `EXPLAIN ANALYZE` on your real queries in `SQL/06_query_optimization.sql` and replace the bracketed values with your actual output before publishing — see the "How to fill this in" section at the end.

---

## 1. Objective

As query complexity grew — multi-table joins across `flights`, `delays`, `carriers`, and `airports`, plus aggregations across 480,000 rows — some analytical queries became slow enough to be worth optimizing. This report documents the queries identified as bottlenecks, the indexing/rewrite strategy applied, and the measured improvement.

---

## 2. Baseline Schema (no indexes beyond primary keys)

| Table | Rows | Primary Key | Foreign Keys |
|---|---|---|---|
| `carriers` | 14 | `carrier_code` | — |
| `airports` | 351 | `airport_code` | — |
| `flights` | 480,000 | `flight_id` | `carrier_code`, `origin`, `dest` |
| `delays` | 480,000 | `delay_id` | `flight_id` |

By default, PostgreSQL only indexes primary keys automatically — foreign key columns (`carrier_code`, `origin`, `dest`, `flight_id` in `delays`) are **not** indexed unless explicitly created, which is the root cause of most slow joins in this project.

---

## 3. Query 1 — Route-Level Delay Summary

**Use case:** powers the Page 2 Route P&L matrix table — average delay, cancellation rate, and flight count grouped by route.

```sql
SELECT
    f.origin,
    f.dest,
    COUNT(*) AS total_flights,
    AVG(f.arr_delay_min) AS avg_arr_delay,
    AVG(f.cancelled::int) * 100 AS cancellation_rate
FROM flights f
GROUP BY f.origin, f.dest
ORDER BY total_flights DESC;
```

| Stage | Execution time | Plan |
|---|---|---|
| Before optimization | [X.XX] ms | Sequential scan on `flights`, in-memory hash aggregate |
| After adding index on `(origin, dest)` | [X.XX] ms | Index-assisted aggregate |
| Improvement | [XX]% faster | |

**Optimization applied:**
```sql
CREATE INDEX idx_flights_origin_dest ON flights (origin, dest);
```

**Why this helps:** grouping by `(origin, dest)` on a 480K-row table without an index forces PostgreSQL to scan and sort the entire table in memory. A composite index lets the planner use an index-only scan path for the grouping step instead.

---

## 4. Query 2 — Carrier Delay-Cause Breakdown (Multi-Table Join)

**Use case:** powers the Page 3 delay-cause stacked bar and treemap — joins `flights` to `delays` and `carriers`.

```sql
SELECT
    c.carrier_name,
    AVG(d.carrier_delay) AS avg_carrier_delay,
    AVG(d.weather_delay) AS avg_weather_delay,
    AVG(d.nas_delay) AS avg_nas_delay,
    AVG(d.late_aircraft_delay) AS avg_late_aircraft_delay
FROM flights f
JOIN delays d ON f.flight_id = d.flight_id
JOIN carriers c ON f.carrier_code = c.carrier_code
GROUP BY c.carrier_name
ORDER BY avg_carrier_delay DESC;
```

| Stage | Execution time | Plan |
|---|---|---|
| Before optimization | [X.XX] ms | Nested loop join, sequential scan on `delays.flight_id` |
| After adding index on `delays.flight_id` | [X.XX] ms | Hash join using index |
| Improvement | [XX]% faster | |

**Optimization applied:**
```sql
CREATE INDEX idx_delays_flight_id ON delays (flight_id);
```

**Why this helps:** `delays.flight_id` is a foreign key but not automatically indexed. Joining 480K rows in `flights` against 480K rows in `delays` without an index on the join column forces a sequential scan for every matching row — adding the index lets PostgreSQL use a much cheaper hash or index join instead.

---

## 5. Query 3 — Monthly Trend with Window Function

**Use case:** powers the rolling 3-month average delay measure shown on Page 3.

```sql
SELECT
    DATE_TRUNC('month', flight_date) AS month,
    AVG(arr_delay_min) AS avg_delay,
    AVG(AVG(arr_delay_min)) OVER (
        ORDER BY DATE_TRUNC('month', flight_date)
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_3mo_avg
FROM flights
GROUP BY DATE_TRUNC('month', flight_date)
ORDER BY month;
```

| Stage | Execution time | Plan |
|---|---|---|
| Before optimization | [X.XX] ms | Sequential scan on `flight_date`, sort for window function |
| After adding index on `flight_date` | [X.XX] ms | Index scan feeding the window function |
| Improvement | [XX]% faster | |

**Optimization applied:**
```sql
CREATE INDEX idx_flights_flight_date ON flights (flight_date);
```

---

## 6. Query 4 — Cancellation Reason Breakdown

**Use case:** powers the Page 1 cancellation donut chart.

```sql
SELECT
    cancellation_code,
    COUNT(*) AS total_cancelled
FROM flights
WHERE cancelled = 1
GROUP BY cancellation_code
ORDER BY total_cancelled DESC;
```

| Stage | Execution time | Plan |
|---|---|---|
| Before optimization | [X.XX] ms | Sequential scan, filter applied row-by-row |
| After adding partial index on cancelled flights | [X.XX] ms | Index scan, filter pushed into index |
| Improvement | [XX]% faster | |

**Optimization applied:**
```sql
CREATE INDEX idx_flights_cancelled ON flights (cancelled) WHERE cancelled = 1;
```

**Why this helps:** a partial index only indexes the ~1.48% of rows where `cancelled = 1`, making it extremely small and fast for this specific, frequently-run query, without the overhead of indexing the other 98.52% of rows where it wouldn't be used this way.

---

## 7. Summary of Indexes Added

```sql
CREATE INDEX idx_flights_origin_dest ON flights (origin, dest);
CREATE INDEX idx_delays_flight_id ON delays (flight_id);
CREATE INDEX idx_flights_flight_date ON flights (flight_date);
CREATE INDEX idx_flights_cancelled ON flights (cancelled) WHERE cancelled = 1;
```

| Query | Before | After | Improvement |
|---|---|---|---|
| Route-level delay summary | [X] ms | [X] ms | [XX]% |
| Carrier delay-cause join | [X] ms | [X] ms | [XX]% |
| Monthly rolling average | [X] ms | [X] ms | [XX]% |
| Cancellation reason breakdown | [X] ms | [X] ms | [XX]% |

---

## 8. How to Fill This In With Real Numbers

For each query above, run this in your SQL client connected to Neon:

```sql
EXPLAIN ANALYZE
<paste the query here>;
```

Run it once **before** creating the relevant index, and once **after**. Copy the `Execution Time: X.XXX ms` line from the output into the tables above, and replace `[X.XX]` placeholders with your real numbers. Also note whether the `Plan` line changed from `Seq Scan` to `Index Scan` / `Bitmap Index Scan` / `Hash Join` — that confirms the index is actually being used (PostgreSQL's planner won't use an index if it decides a sequential scan is cheaper for a given query and data size, which is worth noting if that happens on a small table like `carriers`).

If your actual queries in `SQL/06_query_optimization.sql` differ from the four shown here, swap in your real query text rather than these examples — the structure (baseline → bottleneck → index → before/after timing) is what matters, not the exact SQL.
