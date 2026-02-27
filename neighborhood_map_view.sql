-- View: analytics.neighborhood_map
-- Purpose: Pre-joins neighborhood_clusters (feature matrix + cluster labels) with
--          neighborhood_boundaries (polygon geometry) so that GEOGRAPHY fields
--          pass through to Looker Studio without a blend.
--
-- Background: Looker Studio's blend editor does not support GEOGRAPHY field types.
--             Pre-joining in BigQuery and connecting the view directly to Looker
--             Studio is the recommended workaround.
--
-- Usage: Connect analytics.neighborhood_map as a data source in Looker Studio.
--        Use geo_polygon_wkt as the Location field on the Filled Map chart,
--        with semantic type set to Geo: Region (WKT).

CREATE OR REPLACE VIEW `baltimore-analytics.analytics.neighborhood_map` AS
SELECT
    c.neighborhood,
    c.cluster_label,
    c.top_cluster_label,
    c.sub_cluster,
    c.population,
    c.med_age,
    c.crime_per_capita,
    c.crime_total,
    c.crime_2024,
    c.crime_yoy_change,
    c.top_crime_type,
    c.arrest_per_capita,
    c.housing_vacancy_rate,
    c.vacant_notice_count,
    c.rehab_permit_count,
    c.rehab_to_vacant_ratio,
    c.permit_value_per_capita,
    c.permit_total,
    c.permit_recent_5yr,
    c.median_assessed_value,
    c.avg_assessed_value,
    c.requests_311_per_capita,
    c.requests_311_total,
    c.requests_311_blight,
    c.top_311_request_type,
    c.owner_occupancy_rate,
    c.renter_occupancy_rate,
    b.geo_polygon_wkt
FROM `baltimore-analytics.analytics.neighborhood_clusters` c
LEFT JOIN `baltimore-analytics.analytics.neighborhood_boundaries` b
    ON c.neighborhood = b.name
