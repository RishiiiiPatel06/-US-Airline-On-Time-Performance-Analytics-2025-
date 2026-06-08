-- ============================================================
--  SECTION 6 — QUERY OPTIMIZATION (EXPLAIN + INDEXES)
-- ============================================================
 
 
-- STEP 1: Run EXPLAIN ANALYZE before adding indexes
-- Look for "Seq Scan" — means PostgreSQL reads every row.
-- Save the Execution Time from the output.
-- ─────────────────────────────────────────────────────────────
EXPLAIN ANALYZE
SELECT
    f.origin,
    a.city,
    COUNT(*)                                        AS total_flights,
    ROUND(SUM(f.dep_delay_min)::numeric, 0)         AS total_delay
FROM flights f
JOIN airports a ON f.origin = a.airport_code
WHERE f.cancelled = 0
GROUP BY f.origin, a.city
ORDER BY total_delay DESC;
 
 
-- STEP 2: Create indexes on the most-used columns
-- ─────────────────────────────────────────────────────────────
 
-- Speeds up WHERE cancelled = 0 (used in every query)
CREATE INDEX IF NOT EXISTS idx_flights_cancelled
ON flights(cancelled);
 
-- Speeds up JOIN on origin and GROUP BY origin
CREATE INDEX IF NOT EXISTS idx_flights_origin
ON flights(origin);
 
-- Speeds up GROUP BY carrier_code
CREATE INDEX IF NOT EXISTS idx_flights_carrier
ON flights(carrier_code);
 
-- Speeds up DATE_TRUNC and WHERE on flight_date
CREATE INDEX IF NOT EXISTS idx_flights_date
ON flights(flight_date);
 
-- Composite index for OTP and MoM queries (carrier + date together)
CREATE INDEX IF NOT EXISTS idx_flights_carrier_date
ON flights(carrier_code, flight_date);
 
SELECT 'All 5 indexes created successfully' AS status;
 
 
-- STEP 3: Run EXPLAIN ANALYZE again after indexes
-- Compare Execution Time to STEP 1.
-- Look for "Seq Scan" changing to "Index Scan".
-- ─────────────────────────────────────────────────────────────
EXPLAIN ANALYZE
SELECT
    f.origin,
    a.city,
    COUNT(*)                                        AS total_flights,
    ROUND(SUM(f.dep_delay_min)::numeric, 0)         AS total_delay
FROM flights f
JOIN airports a ON f.origin = a.airport_code
WHERE f.cancelled = 0
GROUP BY f.origin, a.city
ORDER BY total_delay DESC;
 
-- Document findings in: docs/query_optimization_report.md