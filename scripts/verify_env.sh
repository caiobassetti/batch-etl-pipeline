#!/usr/bin/env bash
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Missing $1"; exit 1; }; }

echo "Verifying local prerequisites..."
need docker
need docker-compose || true
need python3
need make

echo "✅ Tools present"
echo "✅ Docker version: $(docker --version)"
echo "✅ Python version: $(python3 --version)"

# If containers are up, show health
if docker ps --format '{{.Names}}' | grep -q '^'"${DB_CONTAINER:-}"'$'; then
  echo "✅ DB container '${DB_CONTAINER}' is running"
  docker compose ps
fi
