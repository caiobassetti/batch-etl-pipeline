SHELL := /bin/bash
# Load env (ignore missing to allow first-run)
-include .env
export

# Helpers
ifeq ($(GITHUB_ACTIONS),true)
  PSQL = PGPASSWORD=$(POSTGRES_PASSWORD) psql -v ON_ERROR_STOP=1 -h $(POSTGRES_HOST) -p $(POSTGRES_PORT) -U $(POSTGRES_USER) -d $(POSTGRES_DB)
else
  PSQL = docker exec -i $(DB_CONTAINER) psql -v ON_ERROR_STOP=1 -U $(POSTGRES_USER) -d $(POSTGRES_DB)
endif


.PHONY: check up down reset logs ps psql db_init adminer_shell gen load transform mart smoke test

# Verify local tools & show versions
check:
	bash scripts/verify_env.sh

# Start the stack in the background
up:
	docker compose up -d

# Stop and remove containers (preserves volume)
down:
	docker compose down

# Hard reset: stop stack and wipe pg_data (destructive!)
reset:
	docker compose down -v
	docker compose up -d
	$(MAKE) db_init

# Show container health/status
ps:
	docker compose ps

# Tail DB logs
logs:
	docker compose logs -f db

# Open a shell inside Adminer
adminer_shell:
	docker exec -it $(ADMINER_CONTAINER) sh

# Interactive psql inside the DB container
psql:
	docker exec -it $(DB_CONTAINER) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

# Apply base schemas (raw, stg, mart)
# We stream the local SQL file into psql STDIN; no bind mount required.
db_init:
	$(PSQL) -v db_user=$(POSTGRES_USER) -f - < sql/00_create_schemas.sql

# Generate tiny CSV fixtures (deterministic)
gen:
	mkdir -p data
	python3 scripts/gen_customers.py
	@echo "✅ Generated data/customers.csv"

# Create raw table & load CSV (idempotent: TRUNCATE before COPY for demo)
load:
	$(PSQL) -f - < sql/raw/01_raw_customers.sql
	$(PSQL) -c "TRUNCATE raw.customers;"
	$(PSQL) -c "\COPY raw.customers (customer_id,first_name,last_name,email,country_code,signup_date,is_marketing_opt_in) FROM STDIN WITH CSV HEADER" < data/customers.csv
	@echo "✅ Loaded raw.customers"

# Build stg views/tables
transform:
	$(PSQL) -f - < sql/stg/10_stg_customers.sql
	@echo "✅ Built stg.customers"

# Build mart views/tables
mart:
	$(PSQL) -f - < sql/mart/20_mart_signups_by_country_day.sql
	@echo "✅ Built mart.signups_by_country_day"

# schemas exist, raw/stg have rows, stg PK is unique
smoke:
	@echo "Checking schema contract..."
	@$(PSQL) -c "SELECT nspname FROM pg_namespace WHERE nspname IN ('raw','stg','mart') ORDER BY 1;" | grep -E 'raw|stg|mart' >/dev/null \
		&& echo '✅ Schemas present: raw, stg, mart' \
		|| (echo '❌ Missing schemas'; exit 1)

	@echo "Checking row counts..."
	@raw_cnt="$$( $(PSQL) -t -c "SELECT COUNT(*) FROM raw.customers;" | tr -d '[:space:]' )"; \
	 stg_cnt="$$( $(PSQL) -t -c "SELECT COUNT(*) FROM stg.customers;" | tr -d '[:space:]' )"; \
	 [ "$$raw_cnt" -gt 0 ] && [ "$$stg_cnt" -gt 0 ] \
	   && echo "✅ Rows -> raw: $$raw_cnt, stg: $$stg_cnt" \
	   || (echo "❌ Empty raw/stg"; exit 1)

	@echo "Checking stg.customer_id uniqueness..."
	@dups="$$( $(PSQL) -t -c "SELECT COUNT(*) FROM (SELECT customer_id FROM stg.customers GROUP BY customer_id HAVING COUNT(*)>1) s;" | tr -d '[:space:]' )"; \
	 [ "$$dups" -eq 0 ] && echo "✅ stg.customer_id unique" \
	 || (echo "❌ stg.customer_id has duplicates"; exit 1)

# Data-quality assertions (fail on any violation)
test:
	@echo "Running data-quality checks..."
	@out="$$( $(PSQL) -t -A -F '|' -f - < tests/dq_checks.sql )"; \
	awk -F'|' ' \
		{ printf " • %-28s  violations=%s\n", $$1, $$2; s += $$2 } \
		END { if (s==0) { print "✅ All data-quality checks passed" } \
		      else { printf "❌ Data-quality violations: %d\n", s; exit 1 } }' \
	<<< "$$out"
