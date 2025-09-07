-- Return one row per check with a violation_count column.
-- The Makefile will parse and fail if any violation_count > 0.

-- 1) stg.customer_id must be NOT NULL
SELECT 'stg.customer_id not null' AS check, COUNT(*) AS violation_count
FROM stg.customers
WHERE customer_id IS NULL

UNION ALL
-- 2) stg.customer_id must be unique
SELECT 'stg.customer_id unique' AS check, COUNT(*) AS violation_count
FROM (
  SELECT customer_id
  FROM stg.customers
  GROUP BY customer_id
  HAVING COUNT(*) > 1
) d

UNION ALL
-- 3) country_code must be in allowed list (uppercased in stg)
SELECT 'country_code valid set' AS check, COUNT(*) AS violation_count
FROM stg.customers
WHERE country_code IS NOT NULL
  AND country_code NOT IN ('NL','DE','FR','ES','BR','US','UK','IT','PT')

UNION ALL
-- 4) email format must look like an email (very basic regex)
SELECT 'email basic format' AS check, COUNT(*) AS violation_count
FROM stg.customers
WHERE email IS NOT NULL
  AND email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'

UNION ALL
-- 5) signup_date within a sane range (no absurd future/past)
SELECT 'signup_date sane range' AS check, COUNT(*) AS violation_count
FROM stg.customers
WHERE signup_date IS NOT NULL
  AND (signup_date < DATE '2023-01-01' OR signup_date > current_date + 1);
