-- ============================================================
--  SECTION 2 — WINDOW FUNCTION QUERIES
-- ============================================================
 
 
-- W1 — Running Total of Flights by Month
-- Concept: SUM() OVER with ROWS UNBOUNDED PRECEDING
-- Shows cumulative network activity across the year.
-- ─────────────────────────────────────────────────────────────
SELECT
    DATE_TRUNC('month', flight_date)                AS flight_month,
    COUNT(*)                                        AS monthly_flights,
    SUM(COUNT(*)) OVER (
        ORDER BY DATE_TRUNC('month', flight_date)
        ROWS UNBOUNDED PRECEDING
    )                                               AS cumulative_flights
FROM flights
WHERE cancelled = 0
GROUP BY DATE_TRUNC('month', flight_date)
ORDER BY flight_month;
 
 
-- W2 — DENSE_RANK Airports by Departure Volume
-- Concept: DENSE_RANK() — tied airports get same rank,
-- next rank is not skipped (unlike RANK).
-- ─────────────────────────────────────────────────────────────
SELECT
    f.origin                                        AS airport,
    a.city,
    a.state,
    COUNT(*)                                        AS total_departures,
    DENSE_RANK() OVER (
        ORDER BY COUNT(*) DESC
    )                                               AS volume_rank
FROM flights f
JOIN airports a ON f.origin = a.airport_code
WHERE f.cancelled = 0
GROUP BY f.origin, a.city, a.state
ORDER BY volume_rank
LIMIT 20;
 
 
-- W3 — Month-over-Month OTP Change per Carrier
-- Concept: LAG() with PARTITION BY
-- Shows if a carrier is improving or declining each month.
-- ─────────────────────────────────────────────────────────────
WITH monthly AS (
    SELECT
        carrier_code,
        DATE_TRUNC('month', flight_date)            AS flight_month,
        ROUND(
            SUM(CASE WHEN arr_delay_min <= 15 THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*)::numeric
        , 2)                                        AS otp_pct
    FROM flights
    WHERE cancelled = 0
    GROUP BY carrier_code, DATE_TRUNC('month', flight_date)
),
with_lag AS (
    SELECT
        carrier_code,
        flight_month,
        otp_pct,
        LAG(otp_pct) OVER (
            PARTITION BY carrier_code
            ORDER BY flight_month
        )                                           AS prev_month_otp
    FROM monthly
)
SELECT
    carrier_code,
    TO_CHAR(flight_month, 'YYYY-MM')                AS month,
    otp_pct,
    prev_month_otp,
    ROUND((otp_pct - prev_month_otp)::numeric, 2)   AS mom_change
FROM with_lag
ORDER BY carrier_code, flight_month;
 
 
-- W4 — Percentile Rank of Routes by Delay Severity
-- Concept: PERCENT_RANK() and NTILE(4)
-- Shows which delay quartile each route falls in.
-- Airlines use percentile benchmarking for SLA management.
-- ─────────────────────────────────────────────────────────────
SELECT
    origin,
    dest,
    COUNT(*)                                        AS total_flights,
    ROUND(AVG(arr_delay_min)::numeric, 2)           AS avg_arr_delay,
    ROUND(
        PERCENT_RANK() OVER (
            ORDER BY AVG(arr_delay_min)
        )::numeric * 100
    , 1)                                            AS delay_percentile,
    NTILE(4) OVER (
        ORDER BY AVG(arr_delay_min)
    )                                               AS delay_quartile
FROM flights
WHERE cancelled = 0
GROUP BY origin, dest
HAVING COUNT(*) >= 100
ORDER BY avg_arr_delay DESC
LIMIT 20;
 
 
-- W5 — 3-Month Rolling Average Delay per Carrier
-- Concept: AVG() OVER with ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
-- Smooths out one-off bad months to show true performance trend.
-- ─────────────────────────────────────────────────────────────
SELECT
    carrier_code,
    TO_CHAR(flight_month, 'YYYY-MM')                AS month,
    ROUND(avg_delay::numeric, 2)                    AS monthly_avg_delay,
    ROUND(
        AVG(avg_delay) OVER (
            PARTITION BY carrier_code
            ORDER BY flight_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )::numeric
    , 2)                                            AS rolling_3mo_avg_delay
FROM (
    SELECT
        carrier_code,
        DATE_TRUNC('month', flight_date)            AS flight_month,
        AVG(arr_delay_min)                          AS avg_delay
    FROM flights
    WHERE cancelled = 0
    GROUP BY carrier_code, DATE_TRUNC('month', flight_date)
) monthly
ORDER BY carrier_code, flight_month;