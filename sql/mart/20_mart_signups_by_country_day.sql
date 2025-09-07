-- Daily signups per country. Business-facing, stable shape.
CREATE OR REPLACE VIEW mart.signups_by_country_day AS
SELECT
  signup_date::date AS signup_date,
  country_code,
  COUNT(*)::bigint AS signups
FROM stg.customers
WHERE signup_date IS NOT NULL
GROUP BY signup_date, country_code
ORDER BY signup_date, country_code;
