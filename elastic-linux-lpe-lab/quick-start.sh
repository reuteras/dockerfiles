#!/usr/bin/env bash
#
# Quick-start automation for elastic-linux-lpe-lab.
# Automates the complete setup of Elasticsearch, Kibana, Fleet Server,
# endpoint policy with Elastic Defend and Auditd Manager, and enrollment
# token generation.
#
# Usage: ./quick-start.sh
#        ./quick-start.sh clean [-y|--yes]
#
# After running this, copy setup-linux-vm.sh to your Linux VM and enroll
# it using the printed enrollment command.
#
# The "clean" subcommand tears the lab down: it stops and removes the
# project's containers, network, and volumes, and deletes the generated
# .env / .env.bak files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ELASTIC_HOST="${ELASTIC_HOST:-http://localhost:9200}"
KIBANA_HOST="${KIBANA_HOST:-http://localhost:5601}"
FLEET_HOST="${FLEET_HOST:-http://localhost:8220}"
ENV_FILE=".env"
ELASTIC_USER="elastic"

usage() {
  printf 'Usage: %s [clean [-y|--yes]]\n' "$(basename "$0")"
}

run_clean() {
  local assume_yes=0
  for arg in "$@"; do
    case "$arg" in
      -y|--yes) assume_yes=1 ;;
      *)
        printf 'Unknown option for clean: %s\n' "$arg" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  printf 'This will remove:\n'
  printf '  - All containers, the network, and volumes for this compose project (es-data, fleet-state)\n'
  if [[ -f "$ENV_FILE" ]]; then
    printf '  - %s (contains generated passwords and the Fleet service token)\n' "$ENV_FILE"
  fi
  if [[ -f "${ENV_FILE}.bak" ]]; then
    printf '  - %s\n' "${ENV_FILE}.bak"
  fi
  printf '\n'

  if [[ "$assume_yes" -ne 1 ]]; then
    read -r -p 'Proceed? [y/N] ' reply
    case "$reply" in
      y|Y|yes|YES) ;;
      *)
        printf 'Aborted.\n'
        exit 0
        ;;
    esac
  fi

  printf 'Stopping and removing containers, network, and volumes...\n'
  docker compose --profile fleet down --volumes --remove-orphans

  rm -f "$ENV_FILE" "${ENV_FILE}.bak"
  printf 'Clean complete.\n'
}

check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    printf 'Error: docker is required but was not found in PATH.\n' >&2
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    printf 'Error: Docker does not appear to be running. Start Docker Desktop and try again.\n' >&2
    exit 1
  fi
}

check_port_free() {
  local port="$1" label="$2"
  if lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
    printf 'Error: Port %s (%s) is already in use. Stop whatever is using it, or run "%s clean" if it is a leftover lab container.\n' \
      "$port" "$label" "$(basename "$0")" >&2
    exit 1
  fi
}

check_ports_free() {
  local running
  running=$(docker compose ps --status running --services 2>/dev/null || true)
  if ! grep -qx 'elasticsearch' <<<"$running"; then
    check_port_free 9200 Elasticsearch
  fi
  if ! grep -qx 'kibana' <<<"$running"; then
    check_port_free 5601 Kibana
  fi
  if ! grep -qx 'fleet-server' <<<"$running"; then
    check_port_free 8220 "Fleet Server"
  fi
}

case "${1:-}" in
  clean)
    shift
    run_clean "$@"
    exit 0
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  "") ;;
  *)
    printf 'Unknown argument: %s\n' "$1" >&2
    usage >&2
    exit 1
    ;;
esac

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

# Note: no -f. Callers inspect the response body to decide success/failure;
# -f would make curl fail (and, under set -e, abort the script) on 4xx/5xx
# before that body-based error handling ever runs.
kibana_api() {
  curl -sS -u "${ELASTIC_USER}:${ELASTIC_PASSWORD}" \
    -H 'Content-Type: application/json' \
    -H 'kbn-xsrf: true' \
    "$@"
}

# Retries a kibana_api call up to max_attempts times, with exponential
# backoff, as long as the response has no "id" field. Package installs
# (Elastic Defend, Auditd Manager) go through Kibana to the public Elastic
# Package Registry, which intermittently returns 403/404/500 under load;
# a short wait usually clears it.
kibana_api_retry() {
  local label="$1" max_attempts="$2"; shift 2
  local attempt=1 delay=5 response
  while :; do
    response=$(kibana_api "$@")
    if echo "$response" | grep -q '"id":"'; then
      printf '%s\n' "$response"
      return 0
    fi
    if (( attempt >= max_attempts )); then
      printf '%s\n' "$response"
      return 1
    fi
    printf '  %s: attempt %d/%d failed (likely a transient package-registry error), retrying in %ds...\n' \
      "$label" "$attempt" "$max_attempts" "$delay" >&2
    sleep "$delay"
    delay=$(( delay * 2 < 60 ? delay * 2 : 60 ))
    (( attempt++ ))
  done
}

printf '=== Elastic Linux LPE Lab - Quick Start ===\n\n'

# Step 0: Preflight checks
printf 'Step 0: Checking prerequisites...\n'
check_docker
check_ports_free
printf 'Docker is running and required ports are free.\n\n'

# Step 1: Generate .env if it doesn't exist
if [[ ! -f "$ENV_FILE" ]]; then
  printf 'Step 1: Generating .env with random passwords...\n'
  ./generate-env.sh
  printf 'Created .env with secure random passwords.\n\n'
else
  printf 'Step 1: .env already exists, skipping generation.\n\n'
fi

# shellcheck source=/dev/null
source "$ENV_FILE"

# Step 2: Start Elasticsearch, setup, and Kibana
printf 'Step 2: Starting Elasticsearch and Kibana...\n'
docker compose up -d elasticsearch setup kibana

# Step 3: Verify Elasticsearch and Kibana are healthy
printf '\nStep 3: Verifying services are healthy...\n'

printf 'Waiting for Elasticsearch...\n'
if ! wait_for_url "${ELASTIC_HOST}/_cluster/health" "elastic:${ELASTIC_PASSWORD}" "Elasticsearch" 60; then
  printf 'Elasticsearch failed to start. Check logs with: docker compose logs elasticsearch\n' >&2
  exit 1
fi

es_status=$(curl -fsS --max-time 5 -u "elastic:${ELASTIC_PASSWORD}" "${ELASTIC_HOST}/_cluster/health" \
  | grep -o '"status":"[^"]*' | cut -d'"' -f4 || true)
printf 'Elasticsearch is ready (cluster status: %s).\n' "${es_status:-unknown}"

printf 'Activating trial license...\n'
license_response=$(curl -sS --max-time 10 -u "elastic:${ELASTIC_PASSWORD}" \
  -X POST "${ELASTIC_HOST}/_license/start_trial?acknowledge=true")
if echo "$license_response" | grep -q '"trial_was_started":true'; then
  printf 'Trial license activated (30 days, full functionality).\n\n'
elif echo "$license_response" | grep -q '"trial_was_started":false'; then
  printf 'Trial license already used previously; continuing with the current license.\n\n'
else
  printf 'Warning: Could not activate trial license.\n'
  printf 'Response: %s\n\n' "$license_response"
fi

printf 'Waiting for Kibana...\n'
if ! wait_for_url "${KIBANA_HOST}/api/status" "" "Kibana" 90; then
  printf 'Kibana failed to start. Check logs with: docker compose logs kibana\n' >&2
  exit 1
fi

kibana_status=$(curl -fsS --max-time 5 "${KIBANA_HOST}/api/status" 2>/dev/null \
  | grep -o '"overall":{"level":"[^"]*' | cut -d'"' -f6 || true)
printf 'Kibana is ready (status: %s).\n' "${kibana_status:-unknown}"
printf '  URL: %s\n' "$KIBANA_HOST"
printf '  Username: elastic\n'
printf '  Password: (see .env)\n\n'

# Step 4: Create Fleet Server policy and service token
printf 'Step 4: Creating Fleet Server policy...\n'

fleet_policy_response=$(kibana_api \
  -X POST "$KIBANA_HOST/api/fleet/agent_policies?sys_monitoring=true" \
  -d '{
    "name": "fleet-server-policy",
    "description": "Policy for Fleet Server",
    "namespace": "default",
    "monitoring_enabled": ["logs", "metrics"],
    "agent_features": [],
    "has_fleet_server": true
  }')

fleet_policy_id=$(echo "$fleet_policy_response" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4 || true)

if [[ -z "$fleet_policy_id" ]]; then
  printf 'Error: Failed to create Fleet Server policy.\n' >&2
  printf 'Response: %s\n' "$fleet_policy_response" >&2
  exit 1
fi

printf 'Fleet Server policy created: %s\n' "$fleet_policy_id"

printf 'Generating Fleet Server service token...\n'
token_response=$(curl -sS -u "${ELASTIC_USER}:${ELASTIC_PASSWORD}" \
  -X POST "${ELASTIC_HOST}/_security/service/elastic/fleet-server/credential/token")

fleet_service_token=$(echo "$token_response" | grep -o '"value":"[^"]*' | cut -d'"' -f4 || true)

if [[ -z "$fleet_service_token" ]]; then
  printf 'Error: Failed to generate service token.\n' >&2
  printf 'Response: %s\n' "$token_response" >&2
  exit 1
fi

printf 'Service token generated.\n'

sed -i.bak \
  -e "s/^FLEET_SERVER_POLICY_ID=.*/FLEET_SERVER_POLICY_ID=$fleet_policy_id/" \
  -e "s/^FLEET_SERVER_SERVICE_TOKEN=.*/FLEET_SERVER_SERVICE_TOKEN=$fleet_service_token/" \
  "$ENV_FILE"

# Re-source to pick up the new values
# shellcheck source=/dev/null
source "$ENV_FILE"
printf '.env updated with Fleet Server configuration.\n\n'

# Step 5: Start Fleet Server and verify it is healthy
printf 'Step 5: Starting Fleet Server...\n'
docker compose --profile fleet up -d

printf 'Waiting for Fleet Server...\n'
if wait_for_url "${FLEET_HOST}/api/status" "" "Fleet Server" 90; then
  fleet_status=$(curl -fsS --max-time 5 "${FLEET_HOST}/api/status" 2>/dev/null \
    | grep -o '"status":"[^"]*' | head -1 | cut -d'"' -f4 || true)
  printf 'Fleet Server is ready (status: %s).\n\n' "${fleet_status:-unknown}"
else
  printf 'Warning: Fleet Server did not become healthy in time.\n'
  printf 'Check logs with: docker compose logs fleet-server\n\n'
fi

# Step 6: Create Linux endpoint policy with integrations
printf 'Step 6: Creating Linux endpoint policy...\n'

endpoint_policy_response=$(kibana_api \
  -X POST "$KIBANA_HOST/api/fleet/agent_policies?sys_monitoring=true" \
  -d '{
    "name": "linux-lpe-endpoint",
    "description": "Linux endpoint policy with Elastic Defend and Auditd Manager",
    "namespace": "default",
    "monitoring_enabled": ["logs", "metrics"],
    "agent_features": []
  }')

endpoint_policy_id=$(echo "$endpoint_policy_response" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4 || true)

if [[ -z "$endpoint_policy_id" ]]; then
  printf 'Error: Failed to create endpoint policy.\n' >&2
  printf 'Response: %s\n' "$endpoint_policy_response" >&2
  exit 1
fi

printf 'Endpoint policy created: %s\n' "$endpoint_policy_id"

printf 'Adding Elastic Defend integration...\n'
defend_response=$(kibana_api_retry "Elastic Defend" 5 \
  -X POST "$KIBANA_HOST/api/fleet/package_policies" \
  -d "{
    \"name\": \"Elastic Defend - LPE Lab\",
    \"namespace\": \"default\",
    \"policy_id\": \"$endpoint_policy_id\",
    \"package\": {
      \"name\": \"endpoint\",
      \"title\": \"Elastic Defend\",
      \"version\": \"\"
    },
    \"inputs\": {
      \"endpoint-endpoint\": {
        \"enabled\": true,
        \"streams\": {},
        \"vars\": {}
      }
    }
  }" || true)

defend_id=$(echo "$defend_response" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4 || true)

if [[ -z "$defend_id" ]]; then
  printf 'Warning: Elastic Defend integration may need manual setup.\n'
  printf 'Response: %s\n' "$defend_response"
else
  printf 'Elastic Defend added.\n'
fi

printf 'Adding Auditd Manager integration...\n'
auditd_response=$(kibana_api_retry "Auditd Manager" 5 \
  -X POST "$KIBANA_HOST/api/fleet/package_policies" \
  -d "{
    \"name\": \"Auditd Manager - LPE Lab\",
    \"namespace\": \"default\",
    \"policy_id\": \"$endpoint_policy_id\",
    \"package\": {
      \"name\": \"auditd_manager\",
      \"title\": \"Auditd Manager\",
      \"version\": \"\"
    },
    \"inputs\": {
      \"audit-audit/auditd\": {
        \"enabled\": true,
        \"streams\": {},
        \"vars\": {}
      }
    }
  }" || true)

auditd_id=$(echo "$auditd_response" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4 || true)

if [[ -z "$auditd_id" ]]; then
  printf 'Warning: Auditd Manager integration may need manual setup.\n'
  printf 'Response: %s\n' "$auditd_response"
else
  printf 'Auditd Manager added.\n'
fi

# Step 7: Generate enrollment token
printf '\nStep 7: Generating enrollment token...\n'

enrollment_response=$(kibana_api \
  -X POST "$KIBANA_HOST/api/fleet/enrollment_api_keys" \
  -d "{\"policy_id\": \"$endpoint_policy_id\"}")

enrollment_token=$(echo "$enrollment_response" | grep -o '"api_key":"[^"]*' | cut -d'"' -f4 || true)

if [[ -z "$enrollment_token" ]]; then
  printf 'Warning: Could not generate enrollment token.\n'
  printf 'Response: %s\n' "$enrollment_response"
  printf 'Generate one manually in Kibana under Management > Fleet > Enrollment tokens.\n\n'
else
  printf 'Enrollment token generated.\n\n'
fi

# Summary
printf '=== Setup Complete ===\n\n'
printf 'Kibana: %s (user: elastic, password in .env)\n' "$KIBANA_HOST"
printf 'Fleet Server: %s\n' "$FLEET_HOST"
printf 'Endpoint policy: linux-lpe-endpoint'
if [[ -n "${defend_id:-}" ]]; then
  printf ' + Elastic Defend'
fi
if [[ -n "${auditd_id:-}" ]]; then
  printf ' + Auditd Manager'
fi
printf '\n\n'

if [[ -n "${enrollment_token:-}" ]]; then
  printf 'Enroll your Linux VM with:\n'
  printf '  sudo ./setup-linux-vm.sh --mac-ip YOUR_MAC_IP --fleet-token %s\n\n' "$enrollment_token"
fi

printf 'After enrollment, install prebuilt detection rules in Kibana:\n'
printf '  Security > Rules > Add Elastic rules\n'
