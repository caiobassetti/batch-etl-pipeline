# Batch ETL/ELT Pipeline (Local Postgres)  ![CI](https://github.com/caiobassetti/batch-etl-pipeline/actions/workflows/ci.yml/badge.svg)

Minimal, reproducible batch pipeline:
- **Generate** tiny CSV fixtures
- **Load** into `raw`
- **Transform** to `stg` (typed + deduped)
- **Expose** a `mart` (daily signups by country)
- **Test** data quality and fail on violations

## Architecture (high level)
[CSV generator] -> raw.customers -> stg.customers -> mart.signups_by_country_day<br>
   (Python)     (text, as-landed)  (typed + de-duped)       (KPI view)

## Schemas
- `raw`: landing; strings as received, `_ingested_at` metadata
- `stg`: typed + normalized + deduped (business key: `customer_id`)
- `mart`: business-ready views (stable shape)

## Pre-reqs
- Docker + Docker Compose
- Python 3.9+ (for the CSV generator)
- Make (for shortcuts)

## Quickstart

```bash
# 0. one-time: copy env
cp .env.example .env

# 1. Quick pre-check
make check

# 2. start infra
make up

# 3. bootstrap schemas
make db_init

# 4. data loop
make gen
make load
make transform
make mart

# 5. quality gates
make test

# optional: 2nd check
make smoke

Adminer: open http://localhost:${ADMINER_PORT:-8080}
Login -> System: PostgreSQL, Server: db, DB: ${POSTGRES_DB}, User: ${POSTGRES_USER}, Pass: ${POSTGRES_PASSWORD}.
```

## Make commands

| Command          | What it does                                        |
| ---------------- | --------------------------------------------------- |
| `make up`        | Start Postgres + Adminer (Docker Compose)           |
| `make db_init`   | Create `raw`, `stg`, `mart` schemas                 |
| `make gen`       | Generate `data/customers.csv`                       |
| `make load`      | Create `raw.customers`, truncate, and load CSV      |
| `make transform` | Build `stg.customers` view (typed + deduped)        |
| `make mart`      | Build `mart.signups_by_country_day`                 |
| `make test`      | Run data-quality checks (fails build on violations) |
| `make smoke`     | Fast end-to-end check                               |
| `make psql`      | Open psql inside the DB container                   |
| `make down`      | Stop/remove containers (volumes preserved)          |

## Data quality

- `customer_id` is **NOT NULL** and **unique** in `stg`
- `country_code` ∈ {NL, DE, FR, ES, BR, US, UK, IT, PT}
- `email` matches a basic shape
- `signup_date` is within a sane range

## Repo layout

```
scripts/
  gen_customers.py
  verify_env.sh

sql/
  00_create_schemas.sql
  raw/
    01_raw_customers.sql
  stg/
    10_stg_customers.sql
  mart/
    20_mart_signups_by_country_day.sql

tests/
  dq_checks.sql

```
