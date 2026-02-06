-- =====================================================
-- Build school exposure mart (distance-weighted, IDW)
-- Keys:
--   dim_schools.school_id (stable PK)
-- Inputs:
--   dim_schools (school points)
--   dim_uk_air_sites (monitor points)
--   fact_uk_air_daily (daily averages per monitor, pollutant)
-- Output:
--   mart_school_air_exposure (one row per school)
-- =====================================================

DROP TABLE IF EXISTS school_monitor_candidates;
DROP TABLE IF EXISTS mart_school_air_exposure;

-- Speed indexes (safe if already exist)
CREATE INDEX IF NOT EXISTS idx_sites_geom_gist   ON dim_uk_air_sites USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_schools_geom_gist ON dim_schools     USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_daily_site_pollutant_date
  ON fact_uk_air_daily (site_key, pollutant, date_utc);

-- 1) Candidate set: K nearest monitoring sites per school
--    KNN operator (<->) makes this fast with a GiST index on geom.
CREATE TABLE school_monitor_candidates AS
SELECT
  s.school_id,
  m.site_key,
  ST_Distance(s.geom::geography, m.geom::geography) AS distance_m
FROM dim_schools s
JOIN LATERAL (
  SELECT site_key, geom
  FROM dim_uk_air_sites
  WHERE geom IS NOT NULL
  ORDER BY geom <-> s.geom
  LIMIT 10
) m ON TRUE
WHERE s.geom IS NOT NULL;

CREATE INDEX idx_smc_school ON school_monitor_candidates(school_id);
CREATE INDEX idx_smc_site   ON school_monitor_candidates(site_key);

-- 2) Mart: compute distance-weighted exposure per school across the period
CREATE TABLE mart_school_air_exposure AS
WITH base AS (
  SELECT
    smc.school_id,
    d.pollutant,
    d.date_utc,
    smc.distance_m,
    (1.0 / (POWER(smc.distance_m / 1000.0, 2) + 1.0)) AS w,  -- IDW weight
    d.avg_value,
    d.pct_valid
  FROM school_monitor_candidates smc
  JOIN fact_uk_air_daily d
    ON d.site_key = smc.site_key
  WHERE d.pollutant IN ('pm25','no2')
    AND d.date_utc >= DATE '2022-09-01'
    AND d.date_utc <= DATE '2026-01-15'
),
daily_school AS (
  -- For each school-day-pollutant, compute IDW weighted value
  SELECT
    school_id,
    pollutant,
    date_utc,
    SUM(w * avg_value) / NULLIF(SUM(w), 0) AS idw_value,
    MIN(distance_m) AS nearest_distance_m,
    AVG(pct_valid) AS mean_site_pct_valid
  FROM base
  GROUP BY 1,2,3
),
summary AS (
  -- Summarise across the full period into one row per school
  SELECT
    school_id,
    AVG(CASE WHEN pollutant='pm25' THEN idw_value END) AS pm25_exposure,
    AVG(CASE WHEN pollutant='no2'  THEN idw_value END) AS no2_exposure,
    AVG(nearest_distance_m) AS avg_nearest_distance_m,
    AVG(mean_site_pct_valid) AS avg_site_pct_valid,
    COUNT(*) FILTER (WHERE pollutant='pm25') AS n_days_pm25,
    COUNT(*) FILTER (WHERE pollutant='no2')  AS n_days_no2
  FROM daily_school
  GROUP BY 1
)
SELECT
  s.school_id,
  s.school_name,
  s.postcode,
  s.address,
  s.town,
  s.local_authority,
  s.lat,
  s.lon,

  x.pm25_exposure,
  x.no2_exposure,

  -- Combined exposure index:
  -- Keep simple for stakeholders; you can normalise/weight in Tableau.
  (COALESCE(x.pm25_exposure, 0) + COALESCE(x.no2_exposure, 0)) AS combined_exposure_index,

  -- Confidence score (0–100):
  -- Higher when monitors are closer and data completeness is higher.
  LEAST(
    100.0,
    100.0
      * (1.0 / (1.0 + (COALESCE(x.avg_nearest_distance_m, 5000) / 1000.0)))
      * (COALESCE(x.avg_site_pct_valid, 0) / 100.0)
  ) AS confidence_score,

  x.avg_nearest_distance_m,
  x.avg_site_pct_valid,
  x.n_days_pm25,
  x.n_days_no2,

  s.geom
FROM summary x
JOIN dim_schools s
  ON s.school_id = x.school_id;

-- Helpful indexes for Tableau filtering/sorting
CREATE INDEX idx_mart_la ON mart_school_air_exposure(local_authority);
CREATE INDEX idx_mart_combined ON mart_school_air_exposure(combined_exposure_index DESC);
CREATE INDEX idx_mart_conf ON mart_school_air_exposure(confidence_score DESC);
CREATE INDEX idx_mart_geom ON mart_school_air_exposure USING GIST (geom);