#!/usr/bin/env bash
#
# Automate Fleet Server and endpoint policy setup in Kibana.
# This script:
# 1. Creates a Fleet Server policy and generates a service token
# 2. Creates a Linux endpoint policy with Elastic Defend and Auditd Manager
# 3. Generates an enrollment token for the endpoint policy
#
# Usage: ./setup-fleet.sh
#
# Prerequisites:
# - Elasticsearch and Kibana must be running
# - Kibana must be healthy
# - .env file must exist with ELASTIC_PASSWORD

set -euo pipefail

ELASTIC_HOST="${ELASTIC_HOST:-http://localhost:9200}"
KIBANA_HOST="${KIBANA_HOST:-http://localhost:5601}"
ENV_FILE=".env"

if [[ ! -f "$ENV_FILE" ]]; then
  printf 'Error: %s not found. Run ./generate-env.sh first.\n' "$ENV_FILE" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$ENV_FILE"

ELASTIC_USER="elastic"

kibana_api() {
  curl -fsS -u "${ELASTIC_USER}:${ELASTIC_PASSWORD}" \
    -H 'Content-Type: application/json' \
    -H 'kbn-xsrf: true' \
    "$@"
}

printf '=== Elastic Fleet Server Automation Setup ===\n\n'

# Wait for Kibana to be healthy
printf 'Waiting for Kibana to be ready...\n'
for i in {1..60}; do
  if curl -fsS "$KIBANA_HOST/api/status" >/dev/null 2>&1; then
    printf 'Kibana is ready.\n\n'
    break
  fi
  if (( i == 60 )); then
    printf 'Error: Kibana did not become ready in time.\n' >&2
    exit 1
  fi
  sleep 2
done

# --- Fleet Server Policy and Token ---

printf 'Creating Fleet Server policy...\n'
fleet_policy_response=$(kibana_api \
  -X POST "$KIBANA_HOST/api/fleet/agent_policies?sys_monitoring=true" \
  -d '{
    "name": "fleet-server-policy",
    "description": "Policy for Fleet Server",
    "namespace": "default",
    "monitoring_enabled": ["logs", "metrics"],
    "agent_features": []
  }')

fleet_policy_id=$(echo "$fleet_policy_response" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [[ -z "$fleet_policy_id" ]]; then
  printf 'Error: Failed to create Fleet Server policy.\n' >&2
  printf 'Response: %s\n' "$fleet_policy_response" >&2
  exit 1
fi

printf 'Fleet Server policy created: %s\n\n' "$fleet_policy_id"

printf 'Generating Fleet Server service token...\n'
token_response=$(curl -fsS -u "${ELASTIC_USER}:${ELASTIC_PASSWORD}" \
  -H 'Content-Type: application/json' \
  -X POST "${ELASTIC_HOST}/_security/service/elastic/fleet-server/credential/http/token" \
  -d '{"grant_type": "client_credentials"}')

fleet_service_token=$(echo "$token_response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [[ -z "$fleet_service_token" ]]; then
  printf 'Error: Failed to generate service token.\n' >&2
  printf 'Response: %s\n' "$token_response" >&2
  exit 1
fi

printf 'Service token generated.\n\n'

# Update .env file with Fleet Server settings
printf 'Updating %s with Fleet Server configuration...\n' "$ENV_FILE"
sed -i.bak \
  -e "s/^FLEET_SERVER_POLICY_ID=.*/FLEET_SERVER_POLICY_ID=$fleet_policy_id/" \
  -e "s/^FLEET_SERVER_SERVICE_TOKEN=.*/FLEET_SERVER_SERVICE_TOKEN=$fleet_service_token/" \
  "$ENV_FILE"

printf '.env updated.\n\n'

# --- Linux Endpoint Policy ---

printf 'Creating Linux endpoint policy...\n'
endpoint_policy_response=$(kibana_api \
  -X POST "$KIBANA_HOST/api/fleet/agent_policies?sys_monitoring=true" \
  -d '{
    "name": "linux-lpe-endpoint",
    "description": "Linux endpoint policy with Elastic Defend and Auditd Manager",
    "namespace": "default",
    "monitoring_enabled": ["logs", "metrics"],
    "agent_features": []
  }')

endpoint_policy_id=$(echo "$endpoint_policy_response" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [[ -z "$endpoint_policy_id" ]]; then
  printf 'Error: Failed to create endpoint policy.\n' >&2
  printf 'Response: %s\n' "$endpoint_policy_response" >&2
  exit 1
fi

printf 'Endpoint policy created: %s\n\n' "$endpoint_policy_id"

# --- Add Elastic Defend integration ---

printf 'Adding Elastic Defend integration...\n'
defend_response=$(kibana_api \
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
  }")

defend_id=$(echo "$defend_response" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [[ -z "$defend_id" ]]; then
  printf 'Warning: Elastic Defend integration may need manual setup.\n'
  printf 'Response: %s\n\n' "$defend_response"
else
  printf 'Elastic Defend added: %s\n\n' "$defend_id"
fi

# --- Add Auditd Manager integration ---

printf 'Adding Auditd Manager integration...\n'
auditd_response=$(kibana_api \
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
  }")

auditd_id=$(echo "$auditd_response" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [[ -z "$auditd_id" ]]; then
  printf 'Warning: Auditd Manager integration may need manual setup.\n'
  printf 'Response: %s\n\n' "$auditd_response"
else
  printf 'Auditd Manager added: %s\n\n' "$auditd_id"
fi

# --- Generate enrollment token ---

printf 'Generating enrollment token for endpoint policy...\n'
enrollment_response=$(kibana_api \
  -X POST "$KIBANA_HOST/api/fleet/enrollment_api_keys" \
  -d "{\"policy_id\": \"$endpoint_policy_id\"}")

enrollment_token=$(echo "$enrollment_response" | grep -o '"api_key":"[^"]*' | cut -d'"' -f4)

if [[ -z "$enrollment_token" ]]; then
  printf 'Warning: Could not generate enrollment token.\n'
  printf 'Response: %s\n' "$enrollment_response"
  printf 'Generate one manually in Kibana under Management > Fleet > Enrollment tokens.\n\n'
else
  printf 'Enrollment token generated.\n\n'
fi

# --- Summary ---

printf '=== Fleet Setup Complete ===\n\n'
printf 'Fleet Server Policy ID: %s\n' "$fleet_policy_id"
printf 'Service Token (stored in .env): %s...\n\n' "${fleet_service_token:0:20}"
printf 'Endpoint Policy: %s (%s)\n' "linux-lpe-endpoint" "$endpoint_policy_id"
if [[ -n "${defend_id:-}" ]]; then
  printf '  Elastic Defend: installed\n'
fi
if [[ -n "${auditd_id:-}" ]]; then
  printf '  Auditd Manager: installed\n'
fi
printf '\n'

if [[ -n "${enrollment_token:-}" ]]; then
  printf 'Enrollment token for Linux VM:\n'
  printf '  %s\n\n' "$enrollment_token"
  printf 'Enroll the VM with:\n'
  printf '  sudo ./setup-linux-vm.sh --mac-ip YOUR_MAC_IP --fleet-token %s\n\n' "$enrollment_token"
fi

printf 'Next step: Start Fleet Server with:\n'
printf '  docker compose --profile fleet up -d\n\n'
