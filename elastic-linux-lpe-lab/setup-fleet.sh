#!/usr/bin/env bash
#
# Automate Fleet Server setup in Kibana.
# This script creates a Fleet Server policy and generates the enrollment token.
# Usage: ./setup-fleet.sh
#
# Prerequisites:
# - Elasticsearch and Kibana must be running (docker compose up -d elasticsearch setup kibana)
# - Kibana must be healthy
# - .env file must exist with ELASTIC_PASSWORD and KIBANA_PASSWORD

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
KIBANA_USER="kibana_system"

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

# Create Fleet Server policy
printf 'Creating Fleet Server policy...\n'
fleet_policy_response=$(curl -fsS -u "${ELASTIC_USER}:${ELASTIC_PASSWORD}" \
  -H 'Content-Type: application/json' \
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

# Generate Fleet Server service token
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

# Update .env file
printf 'Updating %s with Fleet Server configuration...\n' "$ENV_FILE"
sed -i.bak \
  -e "s/^FLEET_SERVER_POLICY_ID=.*/FLEET_SERVER_POLICY_ID=$fleet_policy_id/" \
  -e "s/^FLEET_SERVER_SERVICE_TOKEN=.*/FLEET_SERVER_SERVICE_TOKEN=$fleet_service_token/" \
  "$ENV_FILE"

printf '.env updated successfully.\n\n'

# Display the enrollment URL
printf '=== Fleet Server Configuration Complete ===\n'
printf 'Fleet Server Policy ID: %s\n' "$fleet_policy_id"
printf 'Service Token (stored in .env): %s\n\n' "${fleet_service_token:0:20}..."
printf 'Next step: Start Fleet Server with:\n'
printf '  docker compose --profile fleet up -d\n\n'
