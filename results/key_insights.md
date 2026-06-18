# Key Insights — US Airline On-Time Performance Analytics (2025)

A consolidated summary of the most important, presentable findings from this project — useful for interviews, the LinkedIn post, or a quick refresher before discussing the project with anyone.

---

## 1. Headline Metrics

| Metric | Value |
|---|---|
| Total flights analyzed | 480,000 |
| On-Time Performance (OTP%) | 78.57% |
| Cancellation rate | 1.48% |
| Average arrival delay | 17.06 min (median: 0 min) |
| Unique carriers | 14 |
| Unique airports | 351 |
| Unique routes | ~6,500–7,000 |

---

## 2. The "Average Delay" Number Is Misleading on Its Own

The mean arrival delay (16.8 min) is far higher than the median (0 min). The delay distribution is extremely right-skewed (skewness ≈ 11.2, kurtosis ≈ 233): 63% of flights are on-time or early, and only 7.8% are severely delayed (60+ minutes) — but that small severe-delay group pulls the average up substantially. This is exactly why airlines report OTP% as a headline KPI rather than average delay: it's far less distorted by rare extreme outliers.

---

## 3. Departure Delay Almost Fully Determines Arrival Delay

Correlation between departure delay and arrival delay: **0.97**. Aircraft essentially do not "make up time" in flight at any meaningful scale across this dataset — if a flight leaves late, it arrives late.

---

## 4. Carrier and Late-Aircraft Delay Are the Dominant Delay Drivers — Not Weather

| Delay cause | Correlation with arrival delay |
|---|---|
| Carrier delay | 0.68 |
| Late aircraft delay | 0.61 |
| NAS (air traffic/system) delay | 0.37 |
| Weather delay | 0.31 |
| Security delay | 0.03 (negligible) |

Distance has effectively zero correlation with any delay cause — a 200-mile flight and a 2,000-mile flight are equally likely to be delayed.

---

## 5. Delay Causes and Cancellation Causes Are Different Stories

While carrier and late-aircraft issues drive most delay *minutes*, weather is responsible for **62.5% of all cancellations** — far more than carrier (19.4%) or NAS (18.1%) causes. The implied pattern: airlines tend to absorb most disruptions as delays, but when weather is severe enough, they cancel outright rather than wait it out.

---

## 6. Seasonality Is Clear in Delay and Cancellation — Even Though Volume Is Flat

- Flight volume is evenly distributed across all 12 months (~40,000/month) by design (stratified sampling)
- **Delay peaks in July** (~24 min avg) — summer storms and congestion
- **September is the calmest month** (~12 min avg)
- **Cancellations spike in January (~3.0%) and November (~2.65%)** — winter storms and holiday travel
- Quarterly view: Q2 has the highest average delay (18.2 min), Q1 the lowest (14.7 min)

---

## 7. Day-of-Week Effect: Sunday Is the Worst Day to Fly

| Day | Avg arrival delay |
|---|---|
| Sunday | ~21 min (worst) |
| Monday | ~18 min |
| Tuesday | ~13.3 min (best) |

Roughly a 60% gap between the best and worst day — likely a mix of weekend leisure travel congestion and operational carryover into Monday before the schedule resets by midweek.

---

## 8. Carriers Have Distinct "Delay Fingerprints"

- **Hawaiian Airlines (HA):** lowest average delay (10.2 min) and lowest diversion rate; delays are almost entirely carrier-caused (internal operations), with minimal weather/NAS impact — consistent with island routes and less congested airspace
- **Spirit (NK):** delays dominated by NAS (air traffic congestion) delay, more than any other carrier — likely reflects routes through busier airspace
- **Southwest (WN):** high flight volume (95,916 flights) but a relatively low average delay (13.0 min) — an example of operating at scale without a proportional delay penalty
- **OH (smallest carrier in this comparison):** worst average delay (24.1 min) and highest cancellation rate (4.45%) simultaneously

---

## 9. Delay Prediction Has a Real, Defensible Ceiling

A Random Forest classifier trained to predict delay (≥15 min) using **only pre-departure features** (carrier, route, distance, time-based features, historical route/carrier delay rates) plateaued at **74% test accuracy**, regardless of hyperparameter tuning (GridSearchCV) or additional engineered features.

This is a deliberate, honest finding rather than a shortfall: it indicates pre-flight contextual information explains a meaningful but limited share of delay variance. The remaining variance is most likely driven by same-day operational conditions — real-time weather, live air traffic congestion, aircraft turnaround status — that aren't available as features before a flight departs. A model using post-departure information (e.g., actual departure delay) could trivially exceed 95% accuracy, but would be useless for real-world prediction, since that information isn't known until the flight is already delayed.

---

## 10. One-Sentence Summary

*Delays and cancellations in this dataset are driven by different root causes (carrier/late-aircraft operations vs. weather, respectively), follow clear seasonal and weekly patterns, vary meaningfully by carrier, and can be predicted from pre-flight information alone only up to a ceiling of about 74% accuracy — beyond which same-day operational data would be required.*
