-- ============================================================
--  SECTION 5 — KPI CALCULATIONS
-- ============================================================
 
 
-- KPI 1 — On-Time Performance % (OTP)
-- Definition : % of non-cancelled flights arriving within
--              15 minutes of scheduled time (DOT standard).
-- ─────────────────────────────────────────────────────────────
SELECT
    carrier_code,
    COUNT(*)                                        AS total_flights,
    SUM(CASE WHEN arr_delay_min <= 15
             THEN 1 ELSE 0 END)                     AS on_time_count,
    ROUND(
        SUM(CASE WHEN arr_delay_min <= 15 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)::numeric
    , 2)                                            AS otp_pct
FROM flights
WHERE cancelled = 0
GROUP BY carrier_code
ORDER BY otp_pct DESC;
 
 
-- KPI 2 — Cancellation Rate %
-- Definition : % of all scheduled flights that did not operate.
-- ─────────────────────────────────────────────────────────────
SELECT
    carrier_code,
    COUNT(*)                                        AS scheduled_flights,
    SUM(cancelled)                                  AS cancelled_flights,
    ROUND(
        SUM(cancelled) * 100.0 / COUNT(*)::numeric
    , 2)                                            AS cancellation_rate_pct
FROM flights
GROUP BY carrier_code
ORDER BY cancellation_rate_pct DESC;
 
 
-- KPI 3 — Relative Load Factor (Proxy)
-- Definition : Real Load Factor = Passengers / Available Seats.
--              BTS data has no seat counts, so we use route
--              frequency relative to network average as proxy.
-- ─────────────────────────────────────────────────────────────
WITH route_volume AS (
    SELECT
        origin,
        dest,
        COUNT(*)                                    AS total_flights,
        AVG(distance)                               AS avg_distance
    FROM flights
    WHERE cancelled = 0
    GROUP BY origin, dest
),
network_avg AS (
    SELECT AVG(total_flights) AS avg_network_flights
    FROM route_volume
)
SELECT
    r.origin,
    r.dest,
    r.total_flights,
    ROUND(r.avg_distance::numeric, 0)               AS avg_distance_miles,
    ROUND(
        r.total_flights * 100.0 / n.avg_network_flights::numeric
    , 1)                                            AS relative_load_factor
FROM route_volume r
CROSS JOIN network_avg n
ORDER BY relative_load_factor DESC
LIMIT 20;
 
 
-- KPI 4 — Delay Cost Index (CASK Proxy)
-- Definition : CASK = Cost per Available Seat Kilometre.
--              Approximated as avg_delay × avg_distance / 1000.
--              Higher score = more costly delay burden per carrier.
-- ─────────────────────────────────────────────────────────────
SELECT
    carrier_code,
    COUNT(*)                                        AS total_flights,
    ROUND(AVG(arr_delay_min)::numeric, 2)           AS avg_arr_delay_min,
    ROUND(AVG(distance)::numeric, 0)                AS avg_distance_miles,
    ROUND(
        (AVG(arr_delay_min) * AVG(distance) / 1000.0)::numeric
    , 4)                                            AS delay_cost_index,
    RANK() OVER (
        ORDER BY AVG(arr_delay_min) * AVG(distance) DESC
    )                                               AS cost_rank
FROM flights
WHERE cancelled = 0
GROUP BY carrier_code
ORDER BY cost_rank;
 
 
-- KPI 5 — Network Efficiency Score (Composite KPI)
-- Definition : Weighted score combining OTP (50%), cancellation
--              rate (30%), and delay severity (20%).
--              LEAST(avg_delay, 100) caps extreme outliers.
--              Higher score = better overall network performance.
-- ─────────────────────────────────────────────────────────────
WITH base AS (
    SELECT
        carrier_code,
        COUNT(*)                                    AS total_flights,
        ROUND(
            SUM(CASE WHEN arr_delay_min <= 15 THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*)::numeric
        , 2)                                        AS otp_pct,
        ROUND(
            SUM(cancelled) * 100.0 / COUNT(*)::numeric
        , 2)                                        AS cancel_rate,
        ROUND(AVG(arr_delay_min)::numeric, 2)       AS avg_delay
    FROM flights
    GROUP BY carrier_code
)
SELECT
    carrier_code,
    total_flights,
    otp_pct,
    cancel_rate,
    avg_delay,
    ROUND((
        (otp_pct * 0.5)
        + ((100 - cancel_rate) * 0.3)
        + ((100 - LEAST(avg_delay, 100)) * 0.2)
    )::numeric, 2)                                  AS network_efficiency_score,
    RANK() OVER (
        ORDER BY (
            (otp_pct * 0.5)
            + ((100 - cancel_rate) * 0.3)
            + ((100 - LEAST(avg_delay, 100)) * 0.2)
        ) DESC
    )                                               AS efficiency_rank
FROM base
ORDER BY efficiency_rank;