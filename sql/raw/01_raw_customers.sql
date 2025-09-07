CREATE TABLE IF NOT EXISTS raw.customers (
  customer_id TEXT,
  first_name  TEXT,
  last_name   TEXT,
  email       TEXT,
  country_code TEXT,
  signup_date  TEXT,
  is_marketing_opt_in TEXT,
  _ingested_at TIMESTAMPTZ DEFAULT now()
);
