✈️ US Airline On-Time Performance Analytics (2025)

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

## 🗂️ Phase 1 — Data Setup (Complete)

### Data Source
- **Provider:** Bureau of Transportation Statistics (BTS)
- **Dataset:** On-Time Performance Reporting
- **URL:** https://www.transtats.bts.gov/DL_SelectFields.aspx
- **Coverage:** Full year 2025 (January → December)
- **Raw file size:** ~1.3 GB CSV
- **Final rows loaded:** 480,000 (stratified sample — 40,000 per month, all 12 months)

> **Why sampled?** Neon free tier has a 512 MB limit. A balanced monthly
> sample preserves all seasonal patterns and carrier representation while
> fitting within cloud constraints — a standard real-world practice.

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
| Python 3.12 | ETL pipeline |
| pandas | CSV ingestion and cleaning |
| SQLAlchemy | Database connection and writes |
| PostgreSQL (Neon) | Cloud database |
| Google Colab | Notebook environment |
| BTS Open Data | Source dataset |

---

## 🔄 ETL Pipeline

**File:** `notebooks/01_etl_pipeline.ipynb`

The pipeline runs in 6 steps:

1. **Mount** Google Drive and connect to Neon PostgreSQL
2. **Configure** — select 23 of 38 raw columns needed for analysis
3. **Load** — chunked CSV reading (100K rows at a time) to avoid RAM overflow
4. **Clean** — rename columns, fix dates, fill NaN delays with 0, drop nulls
5. **Transform** — build 4 normalized tables from flat CSV
6. **Push** — write to PostgreSQL in chunks of 10K rows

**Key decisions made:**
- Used `chunksize=100_000` to handle 1.3 GB file without memory crash
- Filled NaN delay columns with 0 (no delay = 0 minutes, not missing)
- Used `random_state=42` for reproducible monthly sampling
- Passwords handled via `getpass` — never stored in code

---

## ✅ Data Quality Results

**File:** `notebooks/02_data_quality.ipynb`

| Check | Result |
|---|---|| Total flights loaded | 480,000 |
| Cancelled flights | 7,124 (1.48%) |
| Diverted flights | 1,317 (0.27%) |
| Unique carriers | 14 |
| Unique airports | 351 |
| Average arrival delay | 16.81 min |
| Max arrival delay | 3,275 min |
| Date range | 2025-01-01 → 2025-12-31 |
| Null values in critical columns | 0 |
| Duplicate flights | 0 |
| Flights missing delay record | 0 |
| All 12 months present | ✅ Yes |
| Foreign key integrity | ✅ Pass |

> **Note on max delay (3,275 min):** This is ~54 hours — a real edge case
> in the BTS data, not a data error. These extreme outliers are retained
> in the dataset and flagged in analysis where relevant.

---

## 📁 Repository Structure

```
airline-analytics-p1/
│
├── README.md
│
├── data/
│   └── data_source.md           ← BTS download instructions
│
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_basic_queries.sql
│   ├── 03_window_functions.sql
│   ├── 04_cte_queries.sql
│   ├── 05_kpi_calculations.sql
│   └── 06_query_optimization.sql
│
├── notebooks/
│   ├── 01_etl_pipeline.ipynb
│   └── 02_data_quality.ipynb
│
├── dashboard/
│   └── screenshots/
│
├── docs/
│   ├── data_quality_report.md
│   ├── query_optimization_report.md
│   └── schema_erd.png
│
└── results/
    ├── key_insights.md
    └── resume_bullets.md
```

---

## 🚀 How to Reproduce

### 1. Get the data
Go to https://www.transtats.bts.gov and download the On-Time Performance
dataset for 2025. Save as `bts_ontime_2025.csv` in a Google Drive folder
called `P1_Airline`.

### 2. Set up Neon PostgreSQL
Create a free account at https://neon.tech and create a project called
`airline-analytics`. Copy your connection string.

### 3. Run the ETL notebook
Open `notebooks/01_etl_pipeline.ipynb` in Google Colab. Mount your Drive,
enter your Neon password when prompted, and run all cells top to bottom.
Expected runtime: 15–25 minutes.

### 4. Run data quality checks
Open `notebooks/02_data_quality.ipynb` and run all 8 cells. All checks
should pass with 0 nulls, 0 duplicates, and full referential integrity.

### 5. Run SQL analytics
Connect any SQL client to your Neon database and run the files in the
`sql/` folder in numbered order.

> ⚠️ Never commit your Neon connection string or password to GitHub.
> The notebooks use `getpass` so credentials are never stored in code.

---

## 👤 Author

**Rishi Patel**
Aspiring Data Analyst | SQL • Python • Power BI
📧 codewithrishi01@gmail.com
🔗 LinkedIn: linkedin.com/in/rishipatel01

---

*Dataset: Bureau of Transportation Statistics, US Department of Transportation.
All analysis performed on publicly available open government data.*
