-- ============================================================
--  P1 AIRLINE ANALYTICS — DATABASE SCHEMA
--  Dataset   : BTS On-Time Performance 2025
--  Database  : PostgreSQL (Neon Cloud)
--  Author    : Rishi Patel
-- ============================================================
--  Run this file FIRST before any other SQL file.
--  Creates all 4 tables in correct order (dimensions first,
--  fact table second, sub-fact table last).
-- ============================================================
 
 
-- Drop tables if they exist (safe re-run)
DROP TABLE IF EXISTS delays   CASCADE;
DROP TABLE IF EXISTS flights  CASCADE;
DROP TABLE IF EXISTS airports CASCADE;
DROP TABLE IF EXISTS carriers CASCADE;
 
 
-- ─────────────────────────────────────────────────────────────
--  TABLE 1 — CARRIERS (dimension)
--  One row per airline. Referenced by flights.carrier_code.
-- ─────────────────────────────────────────────────────────────
CREATE TABLE carriers (
    carrier_code    VARCHAR(10)     PRIMARY KEY,
    carrier_name    VARCHAR(100)
);
 
 
-- ─────────────────────────────────────────────────────────────
--  TABLE 2 — AIRPORTS (dimension)
--  One row per airport. Referenced by flights.origin / dest.
-- ─────────────────────────────────────────────────────────────
CREATE TABLE airports (
    airport_code    VARCHAR(10)     PRIMARY KEY,
    city            VARCHAR(100),
    state           VARCHAR(50)
);
 
 
-- ─────────────────────────────────────────────────────────────
--  TABLE 3 — FLIGHTS (fact table)
--  One row per flight. Core table for all analytics.
--  Foreign keys reference carriers and airports.
-- ─────────────────────────────────────────────────────────────
CREATE TABLE flights (
    flight_id           SERIAL          PRIMARY KEY,
    carrier_code        VARCHAR(10)     REFERENCES carriers(carrier_code),
    flight_number       INT,
    flight_date         DATE,
    origin              VARCHAR(10)     REFERENCES airports(airport_code),
    dest                VARCHAR(10)     REFERENCES airports(airport_code),
    dep_delay_min       FLOAT,
    arr_delay_min       FLOAT,
    cancelled           SMALLINT,
    cancellation_code   VARCHAR(5),
    diverted            SMALLINT,
    air_time            FLOAT,
    distance            FLOAT
);
 
 
-- ─────────────────────────────────────────────────────────────
--  TABLE 4 — DELAYS (sub-fact table)
--  One row per flight. Breaks down delay minutes by cause.
--  A=Carrier, B=Weather, C=NAS, D=Security, E=Late Aircraft
-- ─────────────────────────────────────────────────────────────
CREATE TABLE delays (
    delay_id            SERIAL          PRIMARY KEY,
    flight_id           INT             REFERENCES flights(flight_id),
    carrier_delay       FLOAT,
    weather_delay       FLOAT,
    nas_delay           FLOAT,
    security_delay      FLOAT,
    late_aircraft_delay FLOAT
);
 
 
-- ─────────────────────────────────────────────────────────────
--  VERIFY: Check all 4 tables were created
-- ─────────────────────────────────────────────────────────────
SELECT
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_name = t.table_name
     AND table_schema = 'public')      AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
AND table_name IN ('carriers', 'airports', 'flights', 'delays')
ORDER BY table_name;