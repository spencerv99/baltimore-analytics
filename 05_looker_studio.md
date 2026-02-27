# Baltimore Analytics — Looker Studio Dashboard Guide

**Project:** `baltimore-analytics`  
**Primary Table:** `analytics.neighborhood_clusters`  
**Supporting Tables:** `analytics.neighborhood_boundaries`, `analytics.crime_incidents_all`, `analytics.service_requests_311`, `analytics.building_permits`  
**Author:** Spencer  

---

## Table of Contents

1. [BigQuery Connection Setup](#1-bigquery-connection-setup)
2. [Data Sources](#2-data-sources)
3. [Dashboard Pages Overview](#3-dashboard-pages-overview)
4. [Page 1 — Neighborhood Map](#4-page-1--neighborhood-map)
5. [Page 2 — Cluster Comparison](#5-page-2--cluster-comparison)
6. [Page 3 — Crime Trends](#6-page-3--crime-trends)
7. [Page 4 — Vacancy & Housing Health](#7-page-4--vacancy--housing-health)
8. [Page 5 — Investment Activity](#8-page-5--investment-activity)
9. [Page 6 — 311 Service Requests](#9-page-6--311-service-requests)
10. [Page 7 — Property Values](#10-page-7--property-values)
11. [Calculated Fields Reference](#11-calculated-fields-reference)
12. [Filter Controls Reference](#12-filter-controls-reference)
13. [Sharing & Publishing](#13-sharing--publishing)

---

## 1. BigQuery Connection Setup

### Step 1 — Create a New Report

1. Go to [lookerstudio.google.com](https://lookerstudio.google.com)
2. Click **Create → Report**
3. Select **BigQuery** as the connector

### Step 2 — Connect to Primary Data Source

1. Select project: `baltimore-analytics`
2. Select dataset: `analytics`
3. Select table: `neighborhood_clusters`
4. Click **Add** → **Add to Report**

> **Note:** `neighborhood_clusters` contains all 279 neighborhoods with cluster labels and the full feature matrix. This is your primary source for most pages.

### Step 3 — Grant Viewer Access to Service Account

For public sharing without requiring viewer Google accounts:

1. In BigQuery Console → IAM → Add Principal
2. Add: `looker-studio-service-account@baltimore-analytics.iam.gserviceaccount.com`
3. Role: **BigQuery Data Viewer** + **BigQuery Job User**

Alternatively use **Owner credentials** (simpler, less secure) under Data Source settings → Credentials → Owner's credentials.

---

## 2. Data Sources

You will need the following data sources connected. Add each via **Resource → Manage added data sources → Add a data source**.

| Data Source Name | BigQuery Table | Primary Use |
|---|---|---|
| `neighborhood_clusters` | `analytics.neighborhood_clusters` | All pages — feature matrix + cluster labels |
| `neighborhood_boundaries` | `analytics.neighborhood_boundaries` | Map polygon layer |
| `crime_incidents` | `analytics.crime_incidents_all` | Crime trends over time |
| `service_requests_311` | `analytics.service_requests_311` | 311 time series |
| `building_permits` | `analytics.building_permits` | Permit trends over time |


### Blended Data Source — Map Layer

The choropleth map requires joining `neighborhood_clusters` (features) with `neighborhood_boundaries` (polygons). Create a blended source:

1. **Resource → Manage blends → Add a blend**
2. Left table: `neighborhood_clusters` — join key: `neighborhood`
3. Right table: `neighborhood_boundaries` — join key: `name`
4. Join type: **Left outer**
5. Include from left: all fields you need
6. Include from right: `geo_polygon_wkt`
7. Name this blend: `neighborhood_map_blend`

---

## 3. Dashboard Pages Overview

| Page | Data Source | Purpose |
|---|---|---|
| 1. Neighborhood Map | `neighborhood_map_blend` | Geographic overview — cluster labels on map |
| 2. Cluster Comparison | `neighborhood_clusters` | Side-by-side cohort profiles |
| 3. Crime Trends | `crime_incidents` + `neighborhood_clusters` | Crime over time by neighborhood/cluster |
| 4. Vacancy & Housing | `neighborhood_clusters` | Vacancy rates, rehab activity |
| 5. Investment Activity | `building_permits` + `neighborhood_clusters` | Permit trends and investment heat |
| 6. 311 Requests | `service_requests_311` + `neighborhood_clusters` | Service request patterns |
| 7. Property Values | `neighborhood_clusters` | Assessed value distribution |

### Recommended Report-Level Filters (apply to all pages)

Add these as **report-level filter controls** so they persist across pages:

- `top_cluster_label` — Dropdown: filter by Stable / Distressed / Excluded
- `cluster_label` — Dropdown: filter by specific cohort
- Date range control (where applicable)

---

## 4. Page 1 — Neighborhood Map

**Purpose:** Geographic overview. Users can see all 279 neighborhoods colored by cluster, click to see key stats.

**Data source:** `neighborhood_map_blend`

### Layout

```
┌─────────────────────────────────────────────────────┐
│  HEADER: Baltimore Neighborhood Clusters             │
│  Subtitle: Hierarchical K-Means Segmentation        │
├──────────────────────────────┬──────────────────────┤
│                              │  CLUSTER LEGEND       │
│   FILLED MAP                 │  ─────────────────── │
│   (choropleth by            │  ● Stable — Affluent  │
│    cluster_label)            │  ● Stable — Working.. │
│                              │  ● Distressed — Core  │
│                              │  ...                  │
├──────────────────────────────┴──────────────────────┤
│  SCORECARD ROW:                                      │
│  Total Neighborhoods | Avg Crime/Capita | Avg Vacancy│
└─────────────────────────────────────────────────────┘
```

### Filled Map Configuration

1. Add a **Filled Map** chart
2. Data source: `neighborhood_map_blend`
3. **Location dimension:** `geo_polygon_wkt`
   - Set location type to **Geo: Latitude/Longitude** → actually use **Geo field** type
   - In field settings, set **Semantic type** to `Geo: Latitude, Longitude` — Looker Studio will recognize WKT polygons
4. **Color dimension:** `cluster_label`
5. **Tooltip:** Add `neighborhood`, `crime_per_capita`, `housing_vacancy_rate`, `median_assessed_value`

> **Alternative if WKT polygons don't render:** Use latitude/longitude point markers instead. Set location to a blend of `_latitude` and `_longitude` from `neighborhood_boundaries`, color by `cluster_label`. Less precise but simpler.

### Cluster Color Mapping

Set consistent colors across all pages. Under **Style → Color by → Fixed colors**:

| Cluster | Suggested Color |
|---|---|
| Stable — Affluent North Baltimore | `#1a6e3c` (dark green) |
| Stable — Quiet Residential | `#4daf4a` (medium green) |
| Stable — Working Class Rowhouse | `#a8d5a2` (light green) |
| Stable — Mixed/Transitional | `#fee08b` (yellow) |
| Stable — Gentrifying/Hip | `#fdae61` (orange) |
| Distressed — Core Disinvestment | `#d73027` (red) |
| Distressed — Downtown/Commercial Fringe | `#f46d43` (light red) |
| Excluded | `#cccccc` (gray) |

### Scorecards

Add 3 scorecards below the map:

| Scorecard | Field | Aggregation |
|---|---|---|
| Total Neighborhoods | `neighborhood` | COUNT DISTINCT |
| Avg Crime per Capita | `crime_per_capita` | AVG |
| Avg Housing Vacancy | `housing_vacancy_rate` | AVG — format as % |

---

## 5. Page 2 — Cluster Comparison

**Purpose:** Side-by-side comparison of all cluster cohorts across key metrics. Primary analytical page.

**Data source:** `neighborhood_clusters`

### Layout

```
┌─────────────────────────────────────────────────────┐
│  HEADER: Cluster Cohort Comparison                   │
├─────────────────────────────────────────────────────┤
│  FILTER: top_cluster_label  |  cluster_label        │
├─────────────────────────────────────────────────────┤
│  BAR CHART: Avg Crime/Capita by cluster_label        │
├──────────────────────┬──────────────────────────────┤
│  BAR CHART:          │  BAR CHART:                  │
│  Avg Vacancy Rate    │  Avg Median Assessed Value   │
│  by cluster_label    │  by cluster_label            │
├──────────────────────┴──────────────────────────────┤
│  TABLE: All clusters — all key metrics               │
└─────────────────────────────────────────────────────┘
```

### Bar Charts

For each bar chart:
- **Dimension:** `cluster_label`
- **Sort:** Descending by metric value
- **Color:** Fixed — match cluster color mapping above
- **Style:** Horizontal bars work best for long cluster label names

**Metrics to show:**
1. `crime_per_capita` — AVG
2. `housing_vacancy_rate` — AVG (format %)
3. `median_assessed_value` — AVG (format currency $)
4. `permit_value_per_capita` — AVG (format currency $)
5. `requests_311_per_capita` — AVG

### Summary Table

Add a **Table** chart:
- Dimension: `cluster_label`
- Metrics:
  - `neighborhood` — COUNT (rename to "Neighborhoods")
  - `crime_per_capita` — AVG
  - `housing_vacancy_rate` — AVG
  - `median_assessed_value` — AVG
  - `vacant_notice_count` — SUM
  - `permit_total_value` — SUM
  - `requests_311_total` — SUM
- Enable **Heatmap** on numeric columns for quick visual scanning
- Sort: `crime_per_capita` DESC

---

## 6. Page 3 — Crime Trends

**Purpose:** Crime over time — trends by year, neighborhood, and cluster.

**Data sources:** `crime_incidents_all` (primary — unified legacy + current), `neighborhood_clusters` (for cluster labels via blend)

### Blend Setup for This Page

1. Create a new blend: `crime_with_clusters`
2. Left: `crime_incidents_all` — join key: `neighborhood`
3. Right: `neighborhood_clusters` — join key: `neighborhood`
4. Include from right: `cluster_label`, `top_cluster_label`

### Layout

```
┌─────────────────────────────────────────────────────┐
│  HEADER: Crime Trends                                │
├─────────────────────────────────────────────────────┤
│  FILTERS: cluster_label | Date range | Crime type   │
├─────────────────────────────────────────────────────┤
│  LINE CHART: Crime count by year (2015–2024)         │
│  Breakdown by top_cluster_label                      │
├──────────────────────┬──────────────────────────────┤
│  BAR CHART:          │  SCORECARD ROW:              │
│  Top 10 neighborhoods│  Total Crimes | YoY Change   │
│  by crime count      │  Most Common Crime Type       │
├──────────────────────┴──────────────────────────────┤
│  TABLE: Crime by neighborhood with YoY change        │
└─────────────────────────────────────────────────────┘
```

### Line Chart — Crime Over Time

- **Dimension (time):** `crimedatetime` — set granularity to **Year**
- **Breakdown:** `top_cluster_label`
- **Metric:** `crimedatetime` — COUNT (rename to "Crime Incidents")
- **Date range:** Add a date range control linked to `crimedatetime`

### Calculated Field — YoY Change

In `neighborhood_clusters` data source, add a calculated field:

```
Name: crime_yoy_pct
Formula: crime_yoy_change * 100
Format: Percent (1 decimal)
```

### Top Neighborhoods Bar Chart

- **Dimension:** `neighborhood`
- **Metric:** `crime_total` — SUM
- **Filter:** Exclude `top_cluster_label = "Excluded"`
- **Sort:** Descending, show top 10
- **Style:** Color by `cluster_label`

---

## 7. Page 4 — Vacancy & Housing Health

**Purpose:** Understand blight, vacancy patterns, and rehab activity across neighborhoods.

**Data source:** `neighborhood_clusters`

### Layout

```
┌─────────────────────────────────────────────────────┐
│  HEADER: Vacancy & Housing Health                    │
├─────────────────────────────────────────────────────┤
│  FILTERS: cluster_label | council_district          │
├──────────────────┬──────────────────────────────────┤
│  SCATTER PLOT:   │  BAR CHART:                      │
│  X: vacancy rate │  Top 20 neighborhoods            │
│  Y: crime/capita │  by vacant notice count          │
│  Size: population│                                  │
│  Color: cluster  │                                  │
├──────────────────┴──────────────────────────────────┤
│  BAR CHART: Rehab-to-vacant ratio by cluster         │
├─────────────────────────────────────────────────────┤
│  TABLE: Vacancy details by neighborhood              │
└─────────────────────────────────────────────────────┘
```

### Scatter Plot — Vacancy vs Crime

- **X-axis:** `housing_vacancy_rate`
- **Y-axis:** `crime_per_capita`
- **Bubble size:** `population`
- **Color dimension:** `cluster_label`
- **Tooltip:** Add `neighborhood`
- This reveals neighborhoods that are high-vacancy/high-crime (deep distress) vs high-vacancy/low-crime (transitional)

### Rehab Activity Bar Chart

- **Dimension:** `cluster_label`
- **Metric:** `rehab_to_vacant_ratio` — AVG
- Ratios close to 1.0 indicate active remediation; ratios near 0 indicate neglect

### Vacancy Table

- Dimension: `neighborhood`
- Metrics: `vacant_notice_count`, `rehab_permit_count`, `rehab_to_vacant_ratio`, `housing_vacancy_rate`, `cluster_label`
- Conditional formatting on `housing_vacancy_rate`: green < 10%, yellow 10-20%, red > 20%

---

## 8. Page 5 — Investment Activity

**Purpose:** Track building permit investment — where is money flowing, which clusters are attracting development.

**Data sources:** `building_permits` (primary), `neighborhood_clusters` (blend for cluster labels)

### Blend Setup

1. Create blend: `permits_with_clusters`
2. Left: `building_permits` — join key: `neighborhood`
3. Right: `neighborhood_clusters` — join key: `neighborhood`
4. Include from right: `cluster_label`, `top_cluster_label`

### Layout

```
┌─────────────────────────────────────────────────────┐
│  HEADER: Investment Activity                         │
├─────────────────────────────────────────────────────┤
│  FILTERS: cluster_label | Date range | Permit type  │
├─────────────────────────────────────────────────────┤
│  LINE CHART: Permit count by year                    │
│  Breakdown by top_cluster_label                      │
├──────────────────────┬──────────────────────────────┤
│  BAR CHART:          │  BAR CHART:                  │
│  Total permit value  │  Permit count                │
│  by cluster_label    │  by cluster_label            │
├──────────────────────┴──────────────────────────────┤
│  TABLE: Top 20 neighborhoods by permit value         │
└─────────────────────────────────────────────────────┘
```

### Calculated Field — Permit Cost

In `building_permits` data source:

```
Name: cost_numeric
Formula: CAST(cost AS NUMBER)
```

> Note: If `cost` is already FLOAT64 in BigQuery this may not be needed.

### Line Chart — Permits Over Time

- **Dimension:** `issueddate` — granularity: Year
- **Breakdown:** `top_cluster_label`
- **Metric:** `issueddate` — COUNT (rename "Permits Issued")
- Date range: 2010–2024

### Investment Concentration

A key story for this page: are distressed neighborhoods receiving reinvestment? Compare:
- `permit_value_per_capita` for Distressed vs Stable clusters
- `permit_recent_5yr` — recent permit activity (2020+)

---

## 9. Page 6 — 311 Service Requests

**Purpose:** Understand service demand patterns — where residents are requesting help and what types of issues dominate.

**Data sources:** `service_requests_311` (primary), `neighborhood_clusters` (blend)

### Blend Setup

1. Create blend: `requests_with_clusters`
2. Left: `service_requests_311` — join key: `neighborhood`
3. Right: `neighborhood_clusters` — join key: `neighborhood`
4. Include from right: `cluster_label`, `top_cluster_label`

### Layout

```
┌─────────────────────────────────────────────────────┐
│  HEADER: 311 Service Requests                        │
├─────────────────────────────────────────────────────┤
│  FILTERS: cluster_label | Date range | Request type  │
├─────────────────────────────────────────────────────┤
│  LINE CHART: Request volume by year                  │
├──────────────────────┬──────────────────────────────┤
│  PIE/DONUT:          │  BAR CHART:                  │
│  Top request types   │  Requests per capita         │
│  (srtype)            │  by cluster_label            │
├──────────────────────┴──────────────────────────────┤
│  TABLE: Neighborhood 311 summary                     │
└─────────────────────────────────────────────────────┘
```

### Blight-Related Requests

Create a calculated field in `service_requests_311`:

```
Name: is_blight_request
Formula: CASE
  WHEN CONTAINS_TEXT(LOWER(srtype), "abandon") THEN 1
  WHEN CONTAINS_TEXT(LOWER(srtype), "vacant") THEN 1
  ELSE 0
END
```

Use `SUM(is_blight_request)` as a metric to track blight-related service demand over time and by cluster.

### Request Volume Line Chart

- **Dimension:** `createddate` — granularity: Year
- **Breakdown:** `top_cluster_label`
- **Metric:** COUNT of `srrecordid`
- Filter: Exclude null neighborhoods

---

## 10. Page 7 — Property Values

**Purpose:** Understand assessed value distribution across clusters and neighborhoods.

**Data source:** `neighborhood_clusters`

### Layout

```
┌─────────────────────────────────────────────────────┐
│  HEADER: Property Values                             │
├─────────────────────────────────────────────────────┤
│  FILTERS: cluster_label | top_cluster_label          │
├──────────────────────┬──────────────────────────────┤
│  BAR CHART:          │  SCORECARD ROW:              │
│  Median assessed     │  City Median Value           │
│  value by cluster    │  Total Assessed Value        │
│                      │  Residential Parcels         │
├──────────────────────┴──────────────────────────────┤
│  SCATTER PLOT:                                       │
│  X: median_assessed_value                           │
│  Y: crime_per_capita                                │
│  Size: parcel_count  Color: cluster_label           │
├─────────────────────────────────────────────────────┤
│  TABLE: Property value by neighborhood               │
└─────────────────────────────────────────────────────┘
```

### Scatter Plot — Value vs Safety

This is a key insight chart — it reveals the relationship between property values and public safety across all neighborhoods and lets you identify outliers (high value + high crime = gentrification pressure; low value + low crime = hidden gems).

- **X-axis:** `median_assessed_value`
- **Y-axis:** `crime_per_capita`  
- **Bubble size:** `parcel_count`
- **Color:** `cluster_label`
- **Tooltip:** `neighborhood`, `median_assessed_value`, `crime_per_capita`
- Filter: Exclude `top_cluster_label = "Excluded"` and `median_assessed_value = 0`

---

## 11. Calculated Fields Reference

Add these in the relevant data sources via **Resource → Manage data sources → Edit → Add a field**.

### In `neighborhood_clusters`

| Field Name | Formula | Format | Notes |
|---|---|---|---|
| `crime_yoy_pct` | `crime_yoy_change * 100` | Percent | YoY crime change as % |
| `vacancy_pct` | `housing_vacancy_rate * 100` | Percent | Display-friendly |
| `owner_pct` | `owner_occupancy_rate * 100` | Percent | |
| `is_distressed` | `CASE WHEN top_cluster_label = "Distressed - Core Disinvestment" THEN 1 ELSE 0 END` | Number | Binary flag for filtering |

### In `crime_incidents`

| Field Name | Formula | Format | Notes |
|---|---|---|---|
| `crime_year` | `YEAR(crimedatetime)` | Number | For time series |
| `crime_month` | `MONTH(crimedatetime)` | Number | For seasonality |

### In `service_requests_311`

| Field Name | Formula | Format | Notes |
|---|---|---|---|
| `request_year` | `YEAR(createddate)` | Number | For time series |
| `is_blight` | `CASE WHEN CONTAINS_TEXT(LOWER(srtype), "abandon") THEN 1 WHEN CONTAINS_TEXT(LOWER(srtype), "vacant") THEN 1 ELSE 0 END` | Number | Blight flag |

---

## 12. Filter Controls Reference

### Report-Level Controls (apply to all pages)

Add these to a shared header or navigation bar:

| Control | Type | Field | Data Source |
|---|---|---|---|
| Cluster Group | Dropdown | `top_cluster_label` | `neighborhood_clusters` |
| Cluster Cohort | Dropdown | `cluster_label` | `neighborhood_clusters` |

### Page-Level Controls

| Page | Control | Field |
|---|---|---|
| Crime Trends | Date Range | `crimedatetime` |
| Crime Trends | Dropdown | `description` (crime type) |
| Investment | Date Range | `issueddate` |
| 311 | Date Range | `createddate` |
| 311 | Dropdown | `srtype` |

### Cross-Filter Setup

Enable cross-filtering so clicking a neighborhood on the map filters all charts:

1. Select the map or any chart
2. **Chart interactions → Apply filter**
3. Repeat for each interactive chart

---

## 13. Sharing & Publishing

### For Portfolio (Public Viewing)

1. Top right → **Share → Manage access**
2. Change to **Anyone with the link can view**
3. Copy the link for your portfolio

### For Stakeholder Sharing

1. **Share → Invite people** — add specific Google accounts
2. Set role to **Viewer** (they cannot edit)
3. For embed: **File → Embed report** — copy iframe code

### Scheduled Email Delivery

For recurring stakeholder reports:

1. **File → Schedule email delivery**
2. Set frequency (weekly/monthly)
3. Select pages to include
4. Add recipient emails

### Data Freshness

The dashboard reflects BigQuery data at query time. To keep it current:

- Re-run notebooks 01 → 02 → 03 → 04 to refresh all tables
- No manual steps needed in Looker Studio — it queries BigQuery live
- Consider scheduling notebook runs via Cloud Scheduler or Airflow if this becomes a recurring workflow

---

## Appendix — BigQuery Table Reference

### `analytics.neighborhood_clusters` — Key Fields

| Field | Type | Description |
|---|---|---|
| `neighborhood` | STRING | Neighborhood name — universal join key |
| `top_cluster_label` | STRING | Stable / Distressed / Excluded |
| `cluster_label` | STRING | Specific cohort label |
| `sub_cluster` | INTEGER | Numeric sub-cluster ID |
| `population` | FLOAT | Residential population |
| `crime_per_capita` | FLOAT | Crime incidents per resident |
| `housing_vacancy_rate` | FLOAT | Share of units vacant |
| `median_assessed_value` | FLOAT | Median parcel assessed value ($) |
| `permit_value_per_capita` | FLOAT | Building permit $ per resident |
| `requests_311_per_capita` | FLOAT | 311 requests per resident |
| `vacant_notice_count` | INTEGER | Open vacant building notices |
| `rehab_to_vacant_ratio` | FLOAT | Rehab permits / vacant notices |

### `analytics.neighborhood_boundaries` — Key Fields

| Field | Type | Description |
|---|---|---|
| `name` | STRING | Neighborhood name — join to `neighborhood` |
| `geo_polygon_wkt` | GEOGRAPHY | Polygon boundary for map rendering |
| `population` | FLOAT | Census population |
| `objectid` | INTEGER | Unique ID |
