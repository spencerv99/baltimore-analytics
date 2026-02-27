-- View: analytics.crime_incidents_all
-- Purpose: Unions legacy (pre-2021) and current (2021-present) crime incident tables
--          into a single queryable source for time series analysis in Looker Studio.
--
-- Source tables:
--   analytics.crime_incidents_legacy  -- BPD data ~2012-2020
--   analytics.crime_incidents_current -- BPD data 2021-present
--
-- Usage: Connect analytics.crime_incidents_all as a data source in Looker Studio.
--        Use crimedatetime as the time dimension for trend charts.
--        Blend with analytics.neighborhood_clusters on neighborhood to get cluster labels.

CREATE OR REPLACE VIEW `baltimore-analytics.analytics.crime_incidents_all` AS
SELECT
    neighborhood,
    crimedatetime,
    description,
    'legacy' AS source
FROM `baltimore-analytics.analytics.crime_incidents_legacy`
WHERE neighborhood IS NOT NULL

UNION ALL

SELECT
    neighborhood,
    crimedatetime,
    description,
    'current' AS source
FROM `baltimore-analytics.analytics.crime_incidents_current`
WHERE neighborhood IS NOT NULL
