# Batch ETL/ELT Pipeline (Local Postgres)  ![CI](https://github.com/caiobassetti/batch-etl-pipeline/actions/workflows/ci.yml/badge.svg)

Minimal, reproducible batch pipeline:
- **Generate** tiny CSV fixtures
- **Load** into `raw`
- **Transform** to `stg` (typed + deduped)
- **Expose** a `mart` (daily signups by country)
- **Test** data quality and fail on violations
- **CI/CD** on GitHub Actions

## Architecture (high level)
[CSV generator] -> raw.customers -> stg.customers -> mart.signups_by_country_day<br>

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

| Command                | What it does                                           |
| ---------------------- | ------------------------------------------------------ |
| `make up`              | Start Postgres + Adminer (Docker Compose)              |
| `make db_init`         | Create `raw`, `stg`, `mart` schemas                    |
| `make gen`             | Generate `data/customers.csv`                          |
| `make load`            | Append rows into raw.customers with batch_id           |
| `make transform`       | Build `stg.customers` view (typed + deduped)           |
| `make mart`            | Build plain KPI view                                   |
| `make mart_mv_build`   | Build materialized KPI view                            |
| `make mart_mv_refresh` | Refresh MV concurrently using unique index             |
| `make test`            | Run data-quality checks (fails build on violations)    |
| `make smoke`           | Fast end-to-end check                                  |
| `make psql`            | Open psql inside the DB container (or host psql in CI) |
| `make down`            | Stop/remove containers (volumes preserved)             |
| `make reset`           | Hard reset (down -v + re-init schemas)                 |
| `make check`           | Verify local tools installed                           |


## Data quality

- `customer_id` is **NOT NULL** and **unique** in `stg`
- `country_code` ∈ {NL, DE, FR, ES, BR, US, UK, IT, PT}
- `email` matches a basic shape
- `signup_date` is within a sane range

## CI/CD

GitHub Actions workflow (.github/workflows/ci.yml) runs on every push/PR:

- Spins up Postgres service
- Runs make db_init, make gen, make load, make transform, make mart
- Runs make smoke and make test
- Badge at top of README reflects current build health

## Repo layout

 .
├─ .github/
│ └─ workflows/
│ └─ ci.yml
├─ scripts/
│ ├─ gen_customers.py 						# generates CSV with messy + duped rows
│ └─ verify_env.sh 							# check Docker/Python/Make locally
├─ sql/
│ ├─ 00_create_schemas.sql 					# creates raw, stg, mart schemas
│ ├─ raw/
│ │ ├─ 01_raw_customers.sql 				# raw.customers table
│ │ └─ 02_raw_customers_lineage.sql 		# add batch_id, source_filename, _row_hash + indexes
│ ├─ stg/
│ │ ├─ 10_stg_customers.sql
│ │ └─ 11_stg_customers_dedupe_latest.sql 	# view: normalize + dedupe per customer_id (prefer latest batch)
│ └─ mart/
│     ├─ 20_mart_signups_by_country_day.sql 	# view: daily signups by country (simple KPI)
│     └─ 25_mv_signups_by_country_day.sql 	# materialized view: same KPI, fast reads, unique index
├─ tests/
│ └─ dq_checks.sql 							# NOT NULL, uniqueness, whitelist, regex, date-range checks
├─ data/
├─ docker-compose.yml 						# Postgres + Adminer sandbox
├─ Makefile 									# make up/db_init/gen/load/transform/mart/test/smoke/etc.
├─ .env.example 							# sample config
├─ .gitignore 								# ignore .env, *.csv, caches
├─ .editorconfig 								# enforce LF, tabs in Makefiles
├─ .gitattributes 								# normalize LF endings
└─ README.md
