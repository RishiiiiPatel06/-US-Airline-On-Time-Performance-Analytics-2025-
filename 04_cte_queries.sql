-- ============================================================
--  SECTION 3 — CTE QUERIES (Common Table Expressions)
-- ============================================================
 
 
-- C1 — OTP by Carrier and Month
-- Business question: Which airline is most reliable,
-- and does performance drop in winter vs summer?
-- ─────────────────────────────────────────────────────────────
WITH monthly_otp AS (
    SELECT
        carrier_code,
        DATE_TRUNC('month', flight_date)            AS flight_month,
        COUNT(*)                                    AS total_flights,
        SUM(CASE WHEN arr_delay_min <= 15
                 THEN 1 ELSE 0 END)                 AS on_time_flights
    FROM flights
    WHERE cancelled = 0
    GROUP BY carrier_code, DATE_TRUNC('month', flight_date)
)
SELECT
    carrier_code,
    TO_CHAR(flight_month, 'YYYY-MM')                AS month,
    total_flights,
    on_time_flights,
    ROUND(
        on_time_flights * 100.0 / total_flights::numeric
    , 2)                                            AS otp_pct
FROM monthly_otp
ORDER BY carrier_code, flight_month;
 
 
-- C2 — Delay Attribution by Carrier
-- Business question: Are delays the airline's fault or
-- caused by weather and air traffic control (NAS)?
-- NULLIF prevents division by zero.
-- ─────────────────────────────────────────────────────────────
WITH delay_breakdown AS (
    SELECT
        f.carrier_code,
        AVG(d.carrier_delay)                        AS avg_carrier,
        AVG(d.weather_delay)                        AS avg_weather,
        AVG(d.nas_delay)                            AS avg_nas,
        AVG(d.security_delay)                       AS avg_security,
        AVG(d.late_aircraft_delay)                  AS avg_late_aircraft
    FROM flights f
    JOIN delays d ON f.flight_id = d.flight_id
    WHERE f.cancelled = 0
    GROUP BY f.carrier_code
)
SELECT
    carrier_code,
    ROUND(avg_carrier::numeric, 2)                  AS carrier_delay,
    ROUND(avg_weather::numeric, 2)                  AS weather_delay,
    ROUND(avg_nas::numeric, 2)                      AS nas_delay,
    ROUND(avg_late_aircraft::numeric, 2)            AS late_aircraft_delay,
    ROUND(
        avg_carrier * 100.0 / NULLIF(
            avg_carrier + avg_weather + avg_nas + avg_late_aircraft, 0
        )::numeric
    , 2)                                            AS carrier_fault_pct
FROM delay_breakdown
ORDER BY carrier_fault_pct DESC;
 
 
-- C3 — Route Profitability Tiering (Multi-Step CTE)
-- Business question: Which routes are high volume AND low delay —
-- the most operationally profitable combination?
-- Tiers: GOLD / SILVER / BRONZE / WATCH
-- ─────────────────────────────────────────────────────────────
WITH route_stats AS (
    SELECT
        origin,
        dest,
        COUNT(*)                                    AS total_flights,
        ROUND(AVG(arr_delay_min)::numeric, 2)       AS avg_delay,
        ROUND(AVG(distance)::numeric, 0)            AS avg_distance
    FROM flights
    WHERE cancelled = 0
    GROUP BY origin, dest
    HAVING COUNT(*) >= 50
),
route_tiers AS (
    SELECT *,
        CASE
            WHEN total_flights >= 500 AND avg_delay <= 15
                THEN 'GOLD — High Volume Low Delay'
            WHEN total_flights >= 500 AND avg_delay > 15
                THEN 'SILVER — High Volume High Delay'
            WHEN total_flights < 500  AND avg_delay <= 15
                THEN 'BRONZE — Low Volume Low Delay'
            ELSE
                'WATCH — Low Volume High Delay'
        END                                         AS profitability_tier
    FROM route_stats
)
SELECT
    profitability_tier,
    COUNT(*)                                        AS route_count,
    ROUND(AVG(total_flights)::numeric, 0)           AS avg_flights_per_route,
    ROUND(AVG(avg_delay)::numeric, 2)               AS avg_delay_min
FROM route_tiers
GROUP BY profitability_tier
ORDER BY route_count DESC;
 
 
-- C4 — Carrier Consistency Score
-- Business question: Which carrier is most consistent month
-- to month? Low standard deviation = more reliable service.
-- A carrier with low avg but also low stddev beats a carrier
-- with high avg but wild swings.
-- ─────────────────────────────────────────────────────────────
WITH monthly_otp AS (
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
consistency AS (
    SELECT
        carrier_code,
        ROUND(AVG(otp_pct)::numeric, 2)             AS avg_otp,
        ROUND(STDDEV(otp_pct)::numeric, 2)          AS otp_stddev,
        MAX(otp_pct)                                AS best_month_otp,
        MIN(otp_pct)                                AS worst_month_otp,
        ROUND((MAX(otp_pct) - MIN(otp_pct))::numeric, 2) AS otp_range
    FROM monthly_otp
    GROUP BY carrier_code
)
SELECT
    carrier_code,
    avg_otp,
    otp_stddev,
    best_month_otp,
    worst_month_otp,
    otp_range,
    RANK() OVER (ORDER BY otp_stddev ASC)           AS consistency_rank
FROM consistency
ORDER BY consistency_rank;
 
 
-- C5 — Airport Delay Contribution Analysis
-- Business question: Which airports contribute most to TOTAL
-- system delay? An airport with 100K flights × 10 min avg =
-- more system impact than 1K flights × 50 min avg.
-- ─────────────────────────────────────────────────────────────
WITH airport_delay AS (
    SELECT
        f.origin                                    AS airport,
        a.city,
        a.state,
        COUNT(*)                                    AS total_flights,
        ROUND(SUM(f.dep_delay_min)::numeric, 0)     AS total_delay_minutes,
        ROUND(AVG(f.dep_delay_min)::numeric, 2)     AS avg_delay_min
    FROM flights f
    JOIN airports a ON f.origin = a.airport_code
    WHERE f.cancelled = 0
    GROUP BY f.origin, a.city, a.state
),
with_share AS (
    SELECT *,
        ROUND(
            total_delay_minutes * 100.0
            / SUM(total_delay_minutes) OVER ()::numeric
        , 2)                                        AS pct_of_system_delay
    FROM airport_delay
)
SELECT
    airport,
    city,
    state,
    total_flights,
    total_delay_minutes,
    avg_delay_min,
    pct_of_system_delay,
    RANK() OVER (
        ORDER BY total_delay_minutes DESC
    )                                               AS delay_contribution_rank
FROM with_share
ORDER BY delay_contribution_rank
LIMIT 15;