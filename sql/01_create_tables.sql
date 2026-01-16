/*
=====================================================
Air Pollution Exposure Around Schools in England
Table creation script
=====================================================

Purpose:
- Store UK air quality monitoring data (PM2.5, NO2)
- Support spatial joins with schools (PostGIS)
- Provide clean daily aggregates for analytics, Tableau,
  and stakeholder reporting

Date range:
- September 2022 – January 2026

=====================================================
*/

-- Enable PostGIS (safe if already enabled)
CREATE EXTENSION IF NOT EXISTS postgis;

--1. Monitoring sites (dimension)
DROP TABLE IF EXISTS dim_uk_air_sites CASCADE;

CREATE TABLE dim_uk_air_sites (
    site_key TEXT PRIMARY KEY,          -- stable internal identifier
    site_name TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    site_type TEXT,
    zone TEXT,
    agglomeration TEXT,
    local_authority TEXT,
    geom GEOMETRY(Point, 4326),
    loaded_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_dim_uk_air_sites_geom
    ON dim_uk_air_sites
    USING GIST (geom);

--2. Hourly air quality measurements (fact)
DROP TABLE IF EXISTS fact_uk_air_hourly CASCADE;

CREATE TABLE fact_uk_air_hourly (
    pollutant TEXT NOT NULL,             -- 'pm25' or 'no2'
    site_key TEXT NOT NULL
        REFERENCES dim_uk_air_sites(site_key),
    datetime_utc TIMESTAMPTZ NOT NULL,
    value DOUBLE PRECISION,
    status_text TEXT,
    units TEXT,
    method TEXT,
    raw JSONB,
    loaded_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (pollutant, site_key, datetime_utc)
);

CREATE INDEX idx_fact_uk_air_hourly_dt
    ON fact_uk_air_hourly (datetime_utc);

CREATE INDEX idx_fact_uk_air_hourly_pollutant
    ON fact_uk_air_hourly (pollutant);

--3. Daily aggregates (analytics-ready)
DROP TABLE IF EXISTS fact_uk_air_daily CASCADE;

CREATE TABLE fact_uk_air_daily (
    pollutant TEXT NOT NULL,
    site_key TEXT NOT NULL
        REFERENCES dim_uk_air_sites(site_key),
    date_utc DATE NOT NULL,
    avg_value DOUBLE PRECISION,
    n_hours INTEGER,
    pct_valid DOUBLE PRECISION,
    loaded_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (pollutant, site_key, date_utc)
);

CREATE INDEX idx_fact_uk_air_daily_date
    ON fact_uk_air_daily (date_utc);

CREATE INDEX idx_fact_uk_air_daily_pollutant
    ON fact_uk_air_daily (pollutant);