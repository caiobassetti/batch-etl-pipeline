# Load env (ignore missing to allow first-run)
-include .env
export

# Helpers
PSQL=docker exec -i $(DB_CONTAINER) psql -v ON_ERROR_STOP=1 -U $(POSTGRES_USER) -d $(POSTGRES_DB)

.PHONY: up down logs ps psql db_init smoke adminer_shell

# Start the stack in the background
up:
	docker compose up -d

# Stop and remove containers (preserves volume)
down:
	docker compose down

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

# Minimal smoke: verify schemas exist and are accessible
smoke:
	@echo "Checking schemas raw, stg, mart..."
	@$(PSQL) -c "SELECT nspname FROM pg_namespace WHERE nspname IN ('raw','stg','mart') ORDER BY 1;" | grep -E 'raw|stg|mart' >/dev/null \
		&& echo '✅ Schemas present: raw, stg, mart' \
		|| (echo '❌ Missing one or more schemas'; exit 1)
