# Olist E-Commerce Operations Intelligence Dashboard

An executive operations dashboard built on the Olist Brazilian e-commerce dataset, designed to help operations leadership monitor delivery performance, seller efficiency, and customer experience risk across 100,000+ orders.

---

## Dashboard Preview

### Page 1 — Head of Operations
![Operations Executive Summary](screenshots/page1_operations.png)

### Page 2 — Logistics Team
![Logistics Performance](screenshots/page2_logistics.png)

### Page 3 — Seller Management
![Seller Risk Intelligence](screenshots/page3_seller.png)

### Page 4 — Customer Experience
![Customer Dissatisfaction Intelligence](screenshots/page4_customer.png)

---

## Business Problem

Olist operates across 27 Brazilian states with thousands of sellers and millions of orders. Operations leadership needed a way to identify:

- Which regions carry the highest late delivery risk
- Which sellers are creating logistics failures
- Which product categories are damaging customer experience
- How delivery distance affects operational performance
- Where composite risk signals are concentrating

---

## Key Findings

| Finding | Metric |
|---------|--------|
| Platform late delivery rate | 8.11% across 96K delivered orders |
| Highest regional risk | Rio de Janeiro at 13% late delivery rate |
| Distance threshold | Late delivery risk escalates sharply beyond 735km |
| Long-distance exposure | 27.8% of orders exceed the 735km risk threshold |
| High-risk sellers identified | 6 sellers flagged for disproportionate carrier deadline failures |
| Composite risk orders | 361 orders carry 3+ simultaneous dissatisfaction signals |
| Repeat customer risk | Limited — 75% of customers placed only 1 order |

---

## Dashboard Structure

The dashboard is structured across 4 pages, each designed for a specific operational audience:

**Page 1 — Head of Operations**
Regional delivery risk map, category risk matrix, and composite operational risk KPIs for executive-level monitoring.

**Page 2 — Logistics Team**
Distance band analysis showing late delivery rate and delay severity escalation beyond 735km, with supporting volume KPIs.

**Page 3 — Seller Management**
6 high-risk sellers identified using a dual-threshold model — order volume above 75th percentile and review score below 3.0. Carrier deadline miss rates surfaced per seller.

**Page 4 — Customer Experience**
Freight burden analysis, installment exposure risk, and category-level dissatisfaction signals for customer retention monitoring.

---

## Technical Architecture

### Data Source
[Olist Brazilian E-Commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — 9 tables, 100,000+ orders

### Data Engineering — MySQL
- Converted all date columns from VARCHAR to DATETIME
- Built star schema: `fact_orders`, `fact_order_items`, `fact_payments`, `fact_reviews`, `dim_customers`, `dim_sellers`, `dim_products`
- Validated duplicates, null values, and referential integrity across all tables
- Derived metrics:
  - `delivery_delay_days` — DATEDIFF between actual and estimated delivery
  - `carrier_deadline_miss_days` — seller logistics accountability metric
  - `freight_to_price_ratio` — shipping cost dissatisfaction exposure
  - `delivery_distance_km` — Haversine formula using seller and customer geolocation
  - `order_risk_score` — composite risk flag pre-computed in SQL to optimize Power BI performance

### Data Modeling — Power BI
- Star schema with validated relationships and cardinality
- Centralized measure table for all KPIs
- Calculated columns for distance band segmentation and geocoding corrections

### KPI Engineering — DAX

| Concept | Application |
|---------|-------------|
| `CALCULATE` + `FILTER` | Conditional KPI filtering |
| `PERCENTILEX.INC` | Benchmark threshold derivation |
| `SUMMARIZE` + `AVERAGEX` | Customer and seller grain aggregation |
| `DIVIDE` | Safe ratio calculations |
| `SWITCH` | Distance band and geocoding logic |
| `ALL` | Filter context override for platform benchmarks |
| `VAR` | Multi-flag composite scoring efficiency |
| `SUMX` | Row-level iteration for risk counting |

### Analytical Modeling Concepts
- Operational grain engineering — resolving many-to-one relationship challenges
- Benchmark-based thresholding — 75th percentile volume flags
- Multi-factor risk scoring — composite dissatisfaction model across 4 signals
- Distribution-aware KPI design — handling compressed variance in category review scores
- Filter context validation — ensuring measures behave correctly across visual interactions

---

## Data Limitations

- **Repeat customer analysis** — 75% of Olist customers placed only 1 order, making repeat-delay risk analysis statistically limited
- **Product returns** — no return status available in the dataset; cancellation rate used as proxy
- **Review grain** — reviews exist at order level, not product level; sentiment propagated across categories

---

## Repository Structure

olist-ecommerce-dashboard/
├── README.md
├── Olist_Dashboard.pbix
├── screenshots/
│   ├── page1_operations.png
│   ├── page2_logistics.png
│   ├── page3_seller.png
│   └── page4_customer.png
└── sql/
└── data_preparation.sql

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| MySQL | Data preparation, star schema construction, derived metric engineering |
| Power BI Desktop | Data modeling, DAX measure engineering, dashboard visualization |
| DAX | KPI calculation, operational grain resolution, risk scoring |
| Haversine Formula | Geospatial distance calculation between seller and customer locations |

---

## Author

**Roshan Vishwakarma**
Final Year B.E. Information Technology — PVG's College of Engineering, Nashik
GitHub: [github.com/Roshan-1510](https://github.com/Roshan-1510)
