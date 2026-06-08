# Data Source

## Bureau of Transportation Statistics (BTS)
**Dataset:** On-Time Performance Reporting  
**Provider:** US Department of Transportation  
**URL:** https://www.transtats.bts.gov/DL_SelectFields.aspx
**Kaggle:**https://www.kaggle.com/datasets/nxtwaveda/data-analyst

---

## How to Download

1. Go to https://www.transtats.bts.gov/DL_SelectFields.aspx
2. Select **Reporting Carrier On-Time Performance (1987–present)**
3. Choose your year and month
4. Select these fields:

```
Year, Quarter, Month, DayofMonth, DayOfWeek, FlightDate,
Reporting_Airline, Tail_Number, Flight_Number_Reporting_Airline,
Origin, OriginCityName, OriginState, OriginStateName,
Dest, DestCityName, DestState, DestStateName,
CRSDepTime, DepTime, DepDelay, DepDelayMinutes,
CRSArrTime, ArrTime, ArrDelay, ArrDelayMinutes,
Cancelled, CancellationCode, Diverted,
CRSElapsedTime, ActualElapsedTime, AirTime,
Flights, Distance,
CarrierDelay, WeatherDelay, NASDelay, SecurityDelay, LateAircraftDelay
```

5. Click **Download** — file comes as a `.zip` containing a `.csv`

---

## Dataset Used in This Project

| File | Year | Size |
|---|---|---|
| bts_ontime_2025.csv | 2025 (full year) | ~1.3 GB |

> **Note:** Raw CSV files are not uploaded to this repository due to size.
> Download directly from BTS using the link above.

---

## Sampling Strategy

The full 2025 file contains ~6 million rows. To fit within the
free-tier cloud PostgreSQL limit (512 MB), a balanced monthly
sample was used:

- **40,000 rows per month** sampled with `random_state=42`
- **Total rows loaded:** 480,000
- **All 12 months represented** — seasonal patterns preserved
- **All 14 carriers represented** — no carrier excluded

This is standard practice in real-world analytics when working
with infrastructure constraints.

---

## License

This dataset is open government data published by the
US Department of Transportation. Free to use for
research and analysis.
