-- ============================================================
--  SECTION 1 — BASIC ANALYTICS QUERIES
-- ============================================================
 
 
-- B1 — Total Flights, Cancellations and Avg Delay by Carrier
-- Business question: Which carrier operates the most flights
-- and how delayed are they on average?
-- ─────────────────────────────────────────────────────────────
SELECT
    carrier_code,
    COUNT(*)                                        AS total_flights,
    SUM(cancelled)                                  AS total_cancelled,
    ROUND(AVG(arr_delay_min)::numeric, 2)           AS avg_arr_delay,
    ROUND(AVG(dep_delay_min)::numeric, 2)           AS avg_dep_delay
FROM flights
GROUP BY carrier_code
ORDER BY total_flights DESC;
 
 
-- B2 — Top 10 Busiest Routes by Flight Count
-- Business question: Which routes have the highest frequency?
-- These are the backbone routes of the US network.
-- ─────────────────────────────────────────────────────────────
SELECT
    origin,
    dest,
    COUNT(*)                                        AS total_flights,
    ROUND(AVG(distance)::numeric, 0)                AS avg_distance_miles,
    ROUND(AVG(arr_delay_min)::numeric, 2)           AS avg_arr_delay
FROM flights
WHERE cancelled = 0
GROUP BY origin, dest
ORDER BY total_flights DESC
LIMIT 10;
 
 
-- B3 — Cancellation Breakdown by Reason
-- Business question: Why are flights being cancelled?
-- A=Carrier, B=Weather, C=NAS/Air Traffic, D=Security
-- ─────────────────────────────────────────────────────────────
SELECT
    cancellation_code,
    CASE cancellation_code
        WHEN 'A' THEN 'Carrier'
        WHEN 'B' THEN 'Weather'
        WHEN 'C' THEN 'NAS / Air Traffic'
        WHEN 'D' THEN 'Security'
        ELSE          'Not Cancelled'
    END                                             AS reason,
    COUNT(*)                                        AS total_flights,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()::numeric
    , 2)                                            AS pct_of_total
FROM flights
WHERE cancelled = 1
GROUP BY cancellation_code
ORDER BY total_flights DESC;
 
 
-- B4 — Average Delay by Day of Week
-- Business question: Which day of the week is worst for delays?
-- 0=Sunday, 1=Monday ... 6=Saturday
-- ─────────────────────────────────────────────────────────────
SELECT
    EXTRACT(DOW FROM flight_date)                   AS day_number,
    TO_CHAR(flight_date, 'Day')                     AS day_name,
    COUNT(*)                                        AS total_flights,
    ROUND(AVG(arr_delay_min)::numeric, 2)           AS avg_arr_delay,
    ROUND(AVG(dep_delay_min)::numeric, 2)           AS avg_dep_delay
FROM flights
WHERE cancelled = 0
GROUP BY EXTRACT(DOW FROM flight_date), TO_CHAR(flight_date, 'Day')
ORDER BY day_number;
 
 
-- B5 — State-Level Departure Performance
-- Business question: Which US states have the most departure
-- delays? Useful for regional operations planning.
-- ─────────────────────────────────────────────────────────────
SELECT
    a.state,
    COUNT(*)                                        AS total_departures,
    ROUND(AVG(f.dep_delay_min)::numeric, 2)         AS avg_dep_delay,
    SUM(f.cancelled)                                AS total_cancelled,
    ROUND(
        SUM(f.cancelled) * 100.0 / COUNT(*)::numeric
    , 2)                                            AS cancel_rate_pct
FROM flights f
JOIN airports a ON f.origin = a.airport_code
WHERE a.state IS NOT NULL
GROUP BY a.state
ORDER BY avg_dep_delay DESC
LIMIT 15;