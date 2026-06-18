# ✈️ US Airline On-Time Performance Analytics (2025)

End-to-end data analytics project on 480,000+ US domestic flight records — from raw CSV ingestion to a cloud PostgreSQL database, a 5-page Power BI dashboard, deep exploratory analysis in Python, and a delay-prediction machine learning model.

## 📌 Project Status

| Phase | Description | Status |
|---|---|---|
| Phase 1 | Data Setup & ETL | ✅ Complete |
| Phase 2 | SQL Analytics | ✅ Complete |
| Phase 3 | Power BI Dashboard | ✅ Complete |
| Phase 4 | ML Delay Prediction | ✅ Complete|
| Phase 5 | GitHub Portfolio | ✅ Complete|

---
## 🎯 Business Problem

Flight delays cost airlines, airports, and passengers billions of dollars every year, but the causes are rarely a single factor — weather, air traffic congestion, carrier operations, and aircraft turnaround all interact differently depending on the route, carrier, and time of year. This project asks three practical questions a real airline operations or analytics team would care about:


Where and when do delays and cancellations actually happen, and which routes/carriers/airports are the biggest outliers?
What causes them — is it weather, air traffic control, the carrier itself, or a knock-on effect from a previous late flight?
Can delay be predicted before departure using only information available ahead of time, and if so, how reliably?


The project answers all three through a full pipeline: raw data → cloud database → interactive dashboard → statistical analysis → predictive model.

## 🗂️ Data Source

Provider: Bureau of Transportation Statistics (BTS), US Department of Transportation
Dataset: On-Time Performance Reporting
URL: https://www.transtats.bts.gov/DL_SelectFields.aspx
Coverage: Full year 2025 (January–December)
Raw file size: ~1.3 GB CSV
Final rows loaded: 480,000 (stratified sample — 40,000 per month, all 12 months represented)

Why sampled? Neon's free tier has a 512 MB storage limit. A balanced monthly sample preserves seasonal patterns and carrier representation while fitting cloud constraints — a standard, defensible real-world tradeoff rather than a shortcut.

---

## 🗄️ Database Schema

Four normalized tables in cloud PostgreSQL (Neon):

```
CARRIERS ──────────────────────────────┐
  carrier_code (PK)                    │
  carrier_name                         │
                                       ▼
AIRPORTS ──────────────────────── FLIGHTS (fact table)
  airport_code (PK)                flight_id (PK)
  city                             carrier_code (FK)
  state                            flight_number
                                   flight_date
                                   origin (FK → airports)
                                   dest   (FK → airports)
                                   dep_delay_min
                                   arr_delay_min
                                   cancelled
                                   cancellation_code
                                   diverted
                                   air_time
                                   distance
                                       │
                                       ▼
                                   DELAYS
                                   delay_id (PK)
                                   flight_id (FK)
                                   carrier_delay
                                   weather_delay
                                   nas_delay
                                   security_delay
                                   late_aircraft_delay
```

---

## ⚙️ Tech Stack

| Tool | Purpose |
|---|---|
| Python 3.12 (pandas, scikit-learn, SHAP) | ETL, EDA, Machine learning |
| SQLAlchemy + psycopg2 | Database connection & writes |
| PostgreSQL (Neon, serverless) | Cloud data warehouse |
| SQL | Querying, KPI calculation, optimization |
| Power BI | 5-page interactive dashboard, DAX measures |
| Google Colab | Notebook environment |
| BTS Open Data | Source dataset |

---

## 🔄 ETL Pipeline

File: notebooks/01_etl_pipeline.ipynb

Mount Google Drive and connect to Neon PostgreSQL
Select 23 of 38 raw BTS columns needed for analysis
Chunked CSV reading (100K rows at a time) to avoid RAM overflow on a 1.3 GB file
Clean — rename columns, parse dates, fill missing delay-cause values with 0 (no delay ≠ missing data), drop true nulls
Transform flat CSV into 4 normalized tables (carriers, airports, flights, delays)
Push to PostgreSQL in chunks of 10K rows


Key decisions:

random_state=42 for reproducible monthly stratified sampling
Credentials handled via getpass / Colab Secrets — never hardcoded
NaN delay-cause columns filled with 0, since a null there means "not a contributing cause," not missing data

---

| Check | Result |
|---|---|
| Total flights loaded | 480,000 |
| Cancelled flights | 7,124 (1.48%) |
| Diverted flights | 1,317 (0.27%) |
| Unique carriers | 14 |
| Unique airports | 351 |
| Average arrival delay | 16.81 min (median 0 min) |
| Max arrival delay | 3,275 min |
| Date range | 2025-01-01 → 2025-12-31 |
| Null values in critical columns | 0 |
| Duplicate flights | 0 |
| Foreign key integrity | ✅ Pass |

---

## 📊 Power BI Dashboard (5 Pages)

| Page | Focus |
|---|---|
| 1. Executive Overview | Headline KPIs — Total Flights, OTP%, Cancellation Rate, Avg Arrival Delay |
| 2. Route P&L Analysis | Route-level efficiency, delay cost breakdown, quarterly comparison |
| 3. Flight Delay Intelligence | Delay-cause drivers, rolling trend, geographic delay distribution |
| 4. Airport Network Performance Map | Busiest airports/states, geographic delay map |
| 5. Flight Demand Trend Analysis | Seasonal demand, carrier market share, on-time funnel |

Screenshots: [`dashboard/screenshots/`](dashboard/screenshots/)

### Headline Metrics (Page 1 — Executive Overview)

| Metric | Value |
|---|---|
| Total Flights | 480K |
| On-Time Performance (OTP%) | 78.57% |
| Cancellation Rate | 1.48% |
| Avg Arrival Delay | 17.06 min |

---

## 🔍 Exploratory Data Analysis (Python)

**File:** `notebooks/03_deep_eda.ipynb`

Key findings from statistical and visual analysis:

- **Delay distribution is extremely right-skewed** (skew ≈ 11.2, kurtosis ≈ 233): median arrival delay is 0 minutes, but the mean (16.8 min) is pulled up by a small tail of severe delays. 63% of flights are on-time/early; only 7.8% are severely delayed (60+ min) — that minority drives most of the total delay cost.
- **Departure delay and arrival delay correlate at 0.97** — arrival delay is almost entirely inherited from departure delay; aircraft rarely "make up time" in flight.
- **Carrier delay (0.68 correlation) and late-aircraft delay (0.61) are the two dominant delay drivers** — weather (0.31) and NAS/ATC delay (0.37) matter less, and security delay (0.03) is statistically negligible.
- **Seasonality is clear in delay and cancellation, even though flight volume is flat:** delays peak in July (summer storms/congestion) and dip in September; cancellations spike in January and November (winter storms, holiday travel).
- **Weekly pattern:** Sunday has the highest average delay (~21 min); Tuesday the lowest (~13.3 min) — roughly a 60% gap between the best and worst day to fly.
- **Cancellation causes differ from delay causes:** weather alone accounts for 62.5% of all cancellations, even though it's only a moderate driver of delay minutes — when weather is bad enough, airlines tend to cancel outright rather than absorb the delay.
- **Carrier "fingerprints" vary:** Hawaiian Airlines' delays are almost entirely self-inflicted (carrier delay), while Spirit's are dominated by air traffic congestion (NAS delay) — likely reflecting differences in route networks.

Full notebook with all visualizations: [`notebooks/03_deep_eda.ipynb`](notebooks/03_deep_eda.ipynb)

---

## 🤖 Machine Learning — Delay Prediction

**File:** `notebooks/04_delay_prediction_model.ipynb`

**Goal:** predict whether a flight will be delayed ≥15 minutes (DOT standard definition), using only features known **before departure** — no departure delay, no actual air time, no delay-cause breakdown. This constraint was deliberate, to avoid data leakage and produce a model that could genuinely be used ahead of a flight.

| Feature | Type |
|---|---|
| Carrier, origin, dest | Categorical (encoded) |
| Distance | Numeric |
| Month, quarter, day of week, day of month | Time-based |
| Is_weekend | Engineered |
| Route / carrier historical delay rate (Bayesian-smoothed) | Engineered |

**Model:** Random Forest Classifier, tuned via `GridSearchCV` (`max_depth=20`, `n_estimators=200`)

| Metric | Result |
|---|---|
| Test Accuracy | 74.18% |
| Precision (Delayed) | 0.39 |
| Recall (Delayed) | 0.29 |
| Baseline (predict majority class only) | 77.87% |

**Honest takeaway:** with a strictly leakage-free feature set, accuracy plateaus around 74%, regardless of hyperparameter tuning or additional engineered features (historical delay rates, weekend flag). This indicates that **pre-flight contextual features explain a meaningful but limited share of delay variance** — the remaining variance is likely driven by same-day operational conditions (real-time weather, ATC congestion, aircraft turnaround status) that aren't available as pre-departure signals in this dataset. This is a deliberate, defensible modeling decision rather than a shortfall: a model that used `dep_delay_min` or actual delay-cause columns could trivially exceed 95% accuracy, but would be useless for real-world prediction, since those values aren't known until after the flight is already delayed.

---

## 📁 Repository Structure

```
US-Airline-On-Time-Performance-Analytics-2025/
│
├── README.md
├── data_source.md
├── Data_quality_report.md
│
├── SQL/
│   ├── 01_create_tables.sql
│   ├── 02_basic_queries.sql
│   ├── 03_window_functions.sql
│   ├── 04_cte_queries.sql
│   ├── 05_kpi_calculations.sql
│   └── 06_query_optimization.sql
│
├── notebooks/
│   ├── 01_etl_pipeline.ipynb
│   ├── 02_data_quality.ipynb
│   ├── 03_deep_eda.ipynb
│   └── 04_delay_prediction_model.ipynb
│
├── Dashboard/
│   └── screenshots/
│       ├── 01_executive_overview.png
│       ├── 02_route_pl_analysis.png
│       ├── 03_flight_delay_intelligence.png
│       ├── 04_airport_network_map.png
│       └── 05_demand_trend_analysis.png
│
├── docs/
│   ├── architecture_diagram.md
│   ├── data_quality_report.md
│   └── query_optimization_report.md
│
└── results/
    ├── key_insights.md
```

---

## 🚀 How to Reproduce

### 1. Get the data
Download the BTS On-Time Performance dataset for 2025 from https://www.transtats.bts.gov and save it as `bts_ontime_2025.csv` in a Google Drive folder.

### 2. Set up Neon PostgreSQL
Create a free project at https://neon.tech and copy your connection string.

### 3. Run the ETL notebook
Open `notebooks/01_etl_pipeline.ipynb` in Google Colab, mount Drive, enter your Neon connection string (via Colab Secrets), and run all cells. Expected runtime: 15–25 minutes.

### 4. Run data quality checks
Open `notebooks/02_data_quality.ipynb` and run all cells — all checks should pass with 0 nulls, 0 duplicates, full referential integrity.

### 5. Run SQL analytics
Connect any SQL client to your Neon database and run the files in `SQL/` in numbered order.

### 6. Run EDA and ML notebooks
Open `notebooks/03_deep_eda.ipynb` and `notebooks/04_delay_prediction_model.ipynb` and run top to bottom.

### 7. Open the Power BI dashboard
Open the `.pbix` file in Power BI Desktop, point it at your Neon connection string, and refresh.

> ⚠️ Never commit your Neon connection string or password to GitHub. Notebooks use `getpass`/Colab Secrets so credentials are never stored in code.

---

## 👤 Author

**Rishi Patel**
Aspiring Data Analyst | SQL • Python • Power BI
📧 codewithrishi01@gmail.com
🔗 [LinkedIn](https://linkedin.com/in/rishipatel01)
🔗 [GitHub](https://github.com/RishiiiiPatel06)

---

*Dataset: Bureau of Transportation Statistics, US Department of Transportation. All analysis performed on publicly available open government data.*
