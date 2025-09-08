-- batch_id: identifies an ingestion run
ALTER TABLE raw.customers
  ADD COLUMN IF NOT EXISTS batch_id TEXT;

-- source_filename: useful when loading from disk
ALTER TABLE raw.customers
  ADD COLUMN IF NOT EXISTS source_filename TEXT;

-- Row hash for future idempotency
ALTER TABLE raw.customers
  ADD COLUMN IF NOT EXISTS _row_hash TEXT;

-- Indexes
CREATE INDEX IF NOT EXISTS ix_raw_customers_customer_id ON raw.customers (customer_id);
CREATE INDEX IF NOT EXISTS ix_raw_customers_ingested ON raw.customers (_ingested_at);
CREATE INDEX IF NOT EXISTS ix_raw_customers_batch ON raw.customers (batch_id);
