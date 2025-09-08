-- Materialized mart for faster reads that refresh on demand.
CREATE MATERIALIZED VIEW IF NOT EXISTS mart.mv_signups_by_country_day AS
SELECT
  signup_date::date AS signup_date,
  country_code,
  COUNT(*)::bigint AS signups
FROM stg.customers
WHERE signup_date IS NOT NULL
GROUP BY signup_date, country_code;

-- (Re)create the required UNIQUE index for concurrent refresh
DROP INDEX IF EXISTS ix_mv_signups_date_country;
CREATE UNIQUE INDEX IF NOT EXISTS ux_mv_signups_date_country
  ON mart.mv_signups_by_country_day (signup_date, country_code);
