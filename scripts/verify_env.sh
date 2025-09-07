#!/usr/bin/env bash
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Missing $1"; exit 1; }; }

echo "Verifying local prerequisites..."

# Always required locally
need python3 || true
need make     || true

# Docker is required only for local runs (not in CI), unless you explicitly want it
if [[ "${GITHUB_ACTIONS:-}" == "true" || "${SKIP_DOCKER_CHECK:-}" == "1" ]]; then
  echo "ℹ️ CI detected or SKIP_DOCKER_CHECK=1 — skipping Docker/Compose checks"
else
  need docker
  # docker-compose may be absent if users have the 'docker compose' plugin only; don't hard-fail
  command -v docker-compose >/dev/null 2>&1 || echo "ℹ️ 'docker-compose' not found; assuming 'docker compose' plugin is available."
  echo "✅ Docker present: $(docker --version)"
fi

echo "✅ Base tool check complete"
