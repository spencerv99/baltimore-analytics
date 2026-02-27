# Baltimore Neighborhood Analytics Platform

An end-to-end data engineering and analytics pipeline that ingests Baltimore City open data into BigQuery, performs spatial enrichment, builds a neighborhood feature matrix, and segments all 279 Baltimore neighborhoods into actionable cohorts using hierarchical K-means clustering.

**Live Dashboard:** *(Looker Studio link — add after publishing)*  
**Stack:** Python · BigQuery · GCP · Looker Studio · scikit-learn · QGIS concepts

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA SOURCES                                │
│   Baltimore City Open Data (ArcGIS REST APIs) — 9 datasets         │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  01 — INGESTION                           raw_data dataset          │
│  Python → ArcGIS REST → BigQuery                                    │
│  • 9 tables, 11M+ rows                                              │
│  • MONTH partitioning, schema normalization                         │
│  • Polygon geometry capture with CCW winding order correction       │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  02 — SPATIAL ENRICHMENT                  analytics dataset         │
│  BigQuery GIS SQL                                                   │
│  • ST_WITHIN joins to neighborhood polygon boundaries               │
│  • Adds neighborhood column as universal join key                   │
│  • 85–100% match rates per table                                    │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  03 — FEATURE ENGINEERING      analytics.neighborhood_features      │
│  BigQuery SQL aggregations                                          │
│  • 44 features across 279 neighborhoods                             │
│  • Per-capita normalization, YoY trends, ratio metrics              │
│  • Feature groups: crime, arrests, vacancy, permits, 311, property  │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  04 — CLUSTERING               analytics.neighborhood_clusters      │
│  Python · scikit-learn                                              │
│  • Hierarchical K-means: K=2 top-level → sub-clustering per group   │
│  • Elbow method + silhouette scoring for K selection                │
│  • 7 residential cohorts + excluded neighborhood analysis           │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  LOOKER STUDIO DASHBOARD                                            │
│  • Choropleth neighborhood map                                      │
│  • 7 pages: cluster comparison, crime, vacancy, investment,         │
│    311 requests, property values                                    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Datasets

| Dataset | Source | Rows | Notes |
|---|---|---|---|
| Crime Incidents (Legacy) | BPD | 644k | Pre-2021 |
| Crime Incidents (Current) | BPD | 239k | 2021–present |
| BPD Arrests | BPD | 393k | 58.8% geocoded |
| Vacant Building Notices | Housing | 12k | Active notices |
| Vacant Building Rehabs | Housing | 12k | Rehab permits |
| Building Permits | DHCD | 430k | Includes cost |
| 311 Service Requests | 311 | 9M | 86.8% geocoded |
| Real Property | SDAT | 238k | Parcel polygons |
| Neighborhood Boundaries | Planning | 279 | NSA polygons |

---

## Cluster Cohorts

**Stable Group (182 neighborhoods)**

| Cohort | Count | Characteristics |
|---|---|---|
| Stable — Affluent North Baltimore | 14 | Lowest crime, highest property values. Roland Park, Guilford, Homeland. |
| Stable — Quiet Residential | 13 | Low crime, mid-range values, low vacancy. Dickeyville, Lake Walker. |
| Stable — Working Class Rowhouse | 77 | Moderate crime, affordable values, stable occupancy. Northwest/Northeast Baltimore. |
| Stable — Mixed/Transitional | 53 | Mixed indicators, some waterfront/historic. Fells Point, Federal Hill, Highlandtown. |
| Stable — Gentrifying/Hip | 22 | Rising investment, young demographics. Canton, Hampden, Remington, Charles Village. |

**Distressed Group (66 neighborhoods)**

| Cohort | Count | Characteristics |
|---|---|---|
| Distressed — Core Disinvestment | 64 | High crime per capita, high vacancy, low property values. Sandtown-Winchester, Upton, Harlem Park, Oliver. |
| Distressed — Downtown/Commercial Fringe | 2 | Downtown West, Seton Business Park — atypical commercial profile. |

**Excluded (32 neighborhoods)** — Parks, industrial areas, and institutional campuses analyzed separately.

---

## Key Engineering Challenges Solved

**Polygon winding order bug** — ArcGIS REST APIs return polygon rings in clockwise winding order; BigQuery's `ST_GEOGFROMTEXT` expects counter-clockwise for exterior rings. Undetected, this caused every polygon to be interpreted as covering the entire globe (~510M sq km), resulting in 270x row fan-out in spatial joins. Fixed by reversing ring coordinate order during ingestion.

**Parcel geometry validation** — Real property parcels contain duplicate vertices that BigQuery's GEOGRAPHY type rejects at load time. Resolved by storing parcel polygons as STRING and using `ST_GEOGFROMTEXT(wkt, make_valid => TRUE)` at query time, with `ST_CENTROID` to derive join points.

**Assessed value column** — `fullcash` is zero for 93% of Baltimore parcels. The correct assessed value is `currland + currimpr` (current land + current improvements), which is non-zero for ~92% of records.

**Clustering outlier contamination** — Industrial/entertainment areas (stadiums, industrial parks) have artificially inflated crime per capita due to near-zero residential population, pulling K-means into meaningless splits. Resolved by separating residential, institutional, and park/open space neighborhoods into distinct analytical groups before clustering.

**Looker Studio GEOGRAPHY blend limitation** — Looker Studio's blend editor does not pass through BigQuery GEOGRAPHY fields, making it impossible to include polygon geometry in a blended data source. Resolved by pre-joining neighborhood_clusters and neighborhood_boundaries in a BigQuery view (analytics.neighborhood_map), allowing the GEOGRAPHY field to flow through directly to Looker Studio without a blend.

---

## Repository Structure

```
baltimore-analytics/
├── notebooks/
│   ├── 01_ingest_to_bigquery.ipynb     # Ingestion pipeline
│   ├── 02_spatial_enrichment.ipynb     # Spatial joins
│   ├── 03_feature_engineering.ipynb    # Feature matrix
│   ├── 04_clustering.ipynb             # Hierarchical K-means
│   └── 05_looker_studio.md             # Dashboard setup guide
└── README.md
```

---

## Setup

### Prerequisites

- Python 3.9+
- GCP project with BigQuery enabled
- Service account with BigQuery Data Editor + Job User roles

### Install Dependencies

```bash
pip install google-cloud-bigquery google-auth pandas numpy scikit-learn scipy matplotlib seaborn pyarrow requests
```

### Configuration

Each notebook reads credentials from `service_account.json` in the project root. Create a service account key in GCP Console → IAM → Service Accounts → Keys, download as JSON, and place it at the project root.

**Never commit `service_account.json` to version control.**

Update these constants at the top of each notebook to match your project:

```python
GCP_PROJECT       = "your-project-id"
ANALYTICS_DATASET = "analytics"
RAW_DATASET       = "raw_data"
GCP_REGION        = "us-east1"
CREDENTIALS_PATH  = "service_account.json"
```

### Run Order

```
01 → 02 → 03 → 04
```

Each notebook reads from the previous notebook's BigQuery output. Run cells top to bottom within each notebook.

---

## Data Sources

All data sourced from [Baltimore City Open Data](https://data.baltimorecity.gov/) via ArcGIS REST APIs. Data is publicly available and refreshed periodically by the city.

---

## Notes

- `bpd_arrests`: ~41% of records predate geocoding — arrest features undercount for records before ~2015
- `service_requests_311`: Records before ~2010 lack coordinates
- Neighborhoods with `population < 100` are parks, cemeteries, and industrial areas — excluded from residential clustering
- Cluster labels are interpretive and based on mean feature profiles; individual neighborhoods may not perfectly match their cohort description
