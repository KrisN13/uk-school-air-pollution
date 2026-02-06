DROP TABLE IF EXISTS mart_la_monthly_exposure;

CREATE TABLE mart_la_monthly_exposure AS
WITH base AS (
  SELECT
    smc.school_id,
    s.local_authority,
    d.pollutant,
    date_trunc('month', d.date_utc)::date AS month,

    smc.distance_m,
    (1.0 / (POWER(smc.distance_m / 1000.0, 2) + 1.0)) AS w,  -- IDW weight

    d.avg_value,
    d.pct_valid
  FROM school_monitor_candidates smc
  JOIN dim_schools s
    ON s.school_id = smc.school_id
  JOIN fact_uk_air_daily d
    ON d.site_key = smc.site_key
  WHERE d.pollutant IN ('pm25','no2')
    AND d.date_utc >= DATE '2022-09-01'
    AND d.date_utc <= DATE '2026-01-15'
),
school_month AS (
  -- Monthly IDW exposure per school
  SELECT
    school_id,
    local_authority,
    pollutant,
    month,
    SUM(w * avg_value) / NULLIF(SUM(w), 0) AS school_month_exposure,
    MIN(distance_m) AS nearest_distance_m,
    AVG(pct_valid) AS mean_site_pct_valid
  FROM base
  GROUP BY 1,2,3,4
),
school_month_scored AS (
  SELECT
    *,
    LEAST(
      100.0,
      100.0
        * (1.0 / (1.0 + (COALESCE(nearest_distance_m, 5000) / 1000.0)))
        * (COALESCE(mean_site_pct_valid, 0) / 100.0)
    ) AS confidence_score
  FROM school_month
)
SELECT
  local_authority,
  month,
  pollutant,

  AVG(school_month_exposure) AS la_avg_exposure,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY school_month_exposure) AS la_median_exposure,

  COUNT(*) AS n_school_months,
  COUNT(*) FILTER (WHERE confidence_score >= 40) AS n_school_months_high_conf,

  AVG(confidence_score) AS avg_confidence,
  AVG(nearest_distance_m) AS avg_nearest_distance_m
FROM school_month_scored
GROUP BY 1,2,3
ORDER BY month, local_authority, pollutant;