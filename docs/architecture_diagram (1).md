# Architecture Diagram — Data Flow

This document describes the end-to-end data flow for the US Airline On-Time Performance Analytics project, from raw source data to the final dashboard and machine learning model.

## High-Level Flow

```
┌─────────────────────┐
│   BTS Open Data      │
│   (US DOT)            │
│   ~1.3 GB raw CSV     │
│   38 columns           │
│   Full year 2025       │
└──────────┬────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│   ETL — Python (Google Colab)         │
│   • Chunked read (100K rows/chunk)     │
│   • Select 23 relevant columns          │
│   • Clean & rename columns                │
│   • Parse dates, fill delay nulls with 0    │
│   • Stratified sample: 40K flights/month      │
│     → 480,000 total rows                        │
│   • Split into 4 normalized tables                │
└──────────┬──────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│   PostgreSQL — Neon (Cloud, Serverless) │
│                                          │
│   carriers   airports   flights   delays │
│   (4 normalized tables, FK relationships)  │
└──────────┬───────────────────┬──────────┘
           │                   │
           ▼                   ▼
┌─────────────────────┐  ┌─────────────────────────┐
│  SQL Analytics         │  │  Python — EDA & ML          │
│  • KPI queries           │  │  (Google Colab)                │
│  • Window functions        │  │  • Deep EDA: distributions,        │
│  • CTEs                      │  │    correlation, seasonality,       │
│  • Query optimization          │  │    carrier/route/airport analysis    │
└──────────┬──────────────────┘  │  • Feature engineering                  │
           │                       │  • Random Forest delay classifier         │
           │                       │  • GridSearchCV tuning                       │
           │                       └──────────┬────────────────────────────────┘
           │                                  │
           ▼                                  ▼
┌─────────────────────────────────────────────────────┐
│            Power BI Dashboard (5 pages)                  │
│                                                              │
│  1. Executive Overview      4. Airport Network Map            │
│  2. Route P&L Analysis       5. Demand Trend Analysis           │
│  3. Flight Delay Intelligence                                      │
│                                                                        │
│  Connected live to Neon PostgreSQL via DirectQuery/Import               │
└─────────────────────────────────────────────────────────────────────┘
```

## Layer-by-Layer Description

### 1. Source — BTS Open Data
Raw monthly on-time performance data published by the US Bureau of Transportation Statistics. Contains 38 columns per flight record, including scheduled/actual times, delay-cause breakdowns, cancellation codes, and route information.

### 2. ETL — Python (Google Colab)
A single notebook (`01_etl_pipeline.ipynb`) handles:
- Memory-safe chunked ingestion of the ~1.3 GB raw file
- Column selection (23 of 38 fields needed for this analysis)
- Cleaning (date parsing, null handling, type fixes)
- Stratified sampling to fit within Neon's free-tier storage limit while preserving full seasonal coverage
- Reshaping the flat file into 4 normalized relational tables

### 3. Storage — PostgreSQL (Neon)
A serverless, cloud-hosted Postgres database storing the cleaned data in a star-like schema: `flights` as the fact table, with `carriers`, `airports` (joined twice, for origin and destination), and `delays` as supporting tables.

### 4. Analytics Layer (parallel paths)
- **SQL path:** direct querying for KPI calculation, window functions, and query optimization exercises, run against the live database
- **Python path:** a separate notebook performs deep exploratory data analysis (distribution shape, correlation, seasonality, carrier/route/airport breakdowns) and a machine learning notebook trains a delay-prediction classifier on leakage-free, pre-departure features

### 5. Presentation — Power BI
A 5-page interactive dashboard connects directly to the Neon database, giving stakeholders a live, filterable view of operational performance — from headline KPIs down to route-level P&L and geographic delay patterns.

---

*For the full database schema (table/column detail), see the main [README.md](../README.md#%EF%B8%8F-database-schema).*
