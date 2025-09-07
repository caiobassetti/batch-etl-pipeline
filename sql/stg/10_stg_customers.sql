CREATE OR REPLACE VIEW stg.customers AS
WITH normalized AS (
  SELECT
    trim(customer_id)                           AS customer_id,
    initcap(trim(first_name))                   AS first_name,
    initcap(trim(last_name))                    AS last_name,
    lower(trim(email))                          AS email,
    upper(trim(country_code))                   AS country_code,
    CASE WHEN nullif(trim(signup_date),'') IS NULL
         THEN NULL
         ELSE to_date(trim(signup_date), 'YYYY-MM-DD')
    END                                         AS signup_date,
    CASE
      WHEN lower(trim(is_marketing_opt_in)) IN ('true','t','1','yes','y')  THEN true
      WHEN lower(trim(is_marketing_opt_in)) IN ('false','f','0','no','n')  THEN false
      ELSE NULL
    END                                         AS is_marketing_opt_in,
    _ingested_at
  FROM raw.customers
),
deduped AS (
  SELECT *,
         row_number() OVER (PARTITION BY customer_id ORDER BY _ingested_at DESC) AS rn
  FROM normalized
)
SELECT
  customer_id, first_name, last_name, email, country_code, signup_date, is_marketing_opt_in, _ingested_at
FROM deduped
WHERE rn = 1;
