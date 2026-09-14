#!/usr/bin/env bash
#
# Quick-start automation for elastic-linux-lpe-lab.
# Automates the complete setup of Elasticsearch, Kibana, Fleet Server,
# endpoint policy with Elastic Defend and Auditd Manager, and enrollment
# token generation.
#
# Usage: ./quick-start.sh
#
# After running this, copy setup-linux-vm.sh to your Linux VM and enroll
# it using the printed enrollment command.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ELASTIC_HOST="${ELASTIC_HOST:-http://localhost:9200}"
KIBANA_HOST="${KIBANA_HOST:-http://localhost:5601}"
FLEET_HOST="${FLEET_HOST:-http://localhost:8220}"

wait_for_url() {
  local url="$1" auth="${2:-}" label="$3" max_attempts="${4:-60}"
  local curl_args=(-fsS --max-time 5)
  if [[ -n "$auth" ]]; then
    curl_args+=(-u "$auth")
  fi
  for (( i=1; i<=max_attempts; i++ )); do
    if curl "${curl_args[@]}" "$url" >/dev/null 2>&1; then
      return 0
    fi
    if (( i % 10 == 0 )); then
      printf '  Still waiting for %s... (%d/%d)\n' "$label" "$i" "$max_attempts"
    fi
    sleep 2
  done
  printf 'Error: %s did not become ready after %d attempts.\n' "$label" "$max_attempts" >&2
  return 1
}

printf '=== Elastic Linux LPE Lab - Quick Start ===\n\n'

# Step 1: Generate .env if it doesn't exist
if [[ ! -f .env ]]; then
  printf 'Step 1: Generating .env with random passwords...\n'
  ./generate-env.sh
  printf 'Created .env with secure random passwords.\n\n'
else
  printf 'Step 1: .env already exists, skipping generation.\n\n'
fi

# shellcheck source=/dev/null
source .env

# Step 2: Start Elasticsearch, setup, and Kibana
printf 'Step 2: Starting Elasticsearch and Kibana...\n'
docker compose up -d elasticsearch setup kibana

# Step 3: Verify services via their APIs
printf '\nStep 3: Verifying services are healthy...\n'

printf 'Waiting for Elasticsearch...\n'
if ! wait_for_url "${ELASTIC_HOST}/_cluster/health" "elastic:${ELASTIC_PASSWORD}" "Elasticsearch" 60; then
  printf 'Elasticsearch failed to start. Check logs with: docker compose logs elasticsearch\n' >&2
  exit 1
fi

es_status=$(curl -fsS --max-time 5 -u "elastic:${ELASTIC_PASSWORD}" "${ELASTIC_HOST}/_cluster/health" \
  | grep -o '"status":"[^"]*' | cut -d'"' -f4)
printf 'Elasticsearch is ready (cluster status: %s).\n' "$es_status"

printf 'Waiting for Kibana...\n'
if ! wait_for_url "${KIBANA_HOST}/api/status" "" "Kibana" 90; then
  printf 'Kibana failed to start. Check logs with: docker compose logs kibana\n' >&2
  exit 1
fi

kibana_status=$(curl -fsS --max-time 5 "${KIBANA_HOST}/api/status" 2>/dev/null \
  | grep -o '"overall":{"level":"[^"]*' | cut -d'"' -f6)
printf 'Kibana is ready (status: %s).\n' "${kibana_status:-unknown}"
printf '  URL: %s\n' "$KIBANA_HOST"
printf '  Username: elastic\n'
printf '  Password: (see .env)\n\n'

# Step 4: Fleet Server + endpoint policy + enrollment token
printf 'Step 4: Setting up Fleet Server and endpoint policy...\n'
if ./setup-fleet.sh; then
  # Re-source .env to pick up the Fleet Server token and policy ID
  # shellcheck source=/dev/null
  source .env

  # Step 5: Start Fleet Server and verify it is healthy
  printf 'Step 5: Starting Fleet Server...\n'
  docker compose --profile fleet up -d

  printf 'Waiting for Fleet Server...\n'
  if wait_for_url "${FLEET_HOST}/api/status" "" "Fleet Server" 90; then
    fleet_status=$(curl -fsS --max-time 5 "${FLEET_HOST}/api/status" 2>/dev/null \
      | grep -o '"status":"[^"]*' | head -1 | cut -d'"' -f4)
    printf 'Fleet Server is ready (status: %s).\n\n' "${fleet_status:-unknown}"
  else
    printf 'Warning: Fleet Server did not become healthy in time.\n'
    printf 'Check logs with: docker compose logs fleet-server\n\n'
  fi
else
  printf 'Automated Fleet setup failed. See README.md for manual steps.\n\n'
fi

printf '=== Setup Complete ===\n\n'
printf 'Next steps:\n'
printf '1. Open Kibana at %s\n' "$KIBANA_HOST"
printf '2. Copy setup-linux-vm.sh to your Linux VM\n'
printf '3. Enroll the VM using the enrollment command printed above\n'
printf '4. Install prebuilt detection rules in Kibana (Security > Rules > Add Elastic rules)\n'
