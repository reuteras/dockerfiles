#!/usr/bin/env bash
#
# Quick-start automation for elastic-linux-lpe-lab.
# Automates the complete setup of Elasticsearch, Kibana, and Fleet Server.
#
# Usage: ./quick-start.sh
#
# This script:
# 1. Generates .env with random passwords
# 2. Starts Elasticsearch, setup service, and Kibana
# 3. Waits for Kibana to be healthy
# 4. Attempts to create Fleet Server policy and service token via API
# 5. Starts Fleet Server
#
# After running this, you still need to:
# - Create an endpoint policy in Kibana
# - Enroll a Linux VM with the generated enrollment token

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

printf '=== Elastic Linux LPE Lab - Quick Start ===\n\n'

# Step 1: Generate .env if it doesn't exist
if [[ ! -f .env ]]; then
  printf 'Step 1: Generating .env with random passwords...\n'
  ./generate-env.sh
  printf 'Created .env with secure random passwords.\n\n'
else
  printf 'Step 1: .env already exists, skipping generation.\n\n'
fi

# Step 2: Start Elasticsearch, setup, and Kibana
printf 'Step 2: Starting Elasticsearch and Kibana...\n'
docker compose up -d elasticsearch setup kibana

printf 'Waiting for services to be healthy...\n'
for i in {1..120}; do
  if docker compose ps | grep -E 'elasticsearch|kibana' | grep -q 'healthy'; then
    printf 'Services are healthy.\n\n'
    break
  fi
  if (( i % 10 == 0 )); then
    printf '  Waiting... (%d/120)\n' "$i"
  fi
  sleep 1
done

# Step 3: Display Kibana access info
printf 'Step 3: Kibana is ready at http://localhost:5601\n'
source .env
printf '  Username: elastic\n'
printf '  Password: (check .env)\n\n'

# Step 4: Attempt automated Fleet Server setup
printf 'Step 4: Setting up Fleet Server...\n'
if command -v curl >/dev/null 2>&1; then
  if ./setup-fleet.sh; then
    printf 'Fleet Server configured automatically.\n\n'

    # Step 5: Start Fleet Server
    printf 'Step 5: Starting Fleet Server...\n'
    docker compose --profile fleet up -d

    printf 'Fleet Server starting. Check status with:\n'
    printf '  curl http://localhost:8220/api/status\n\n'
  else
    printf 'Automated Fleet setup failed. Manual configuration needed.\n'
    printf 'See README.md for manual setup steps.\n\n'
  fi
else
  printf 'curl not found. Manual Fleet Server setup required.\n'
  printf 'See README.md for setup steps.\n\n'
fi

printf '=== Setup Complete ===\n'
printf 'Next steps:\n'
printf '1. Open Kibana at http://localhost:5601\n'
printf '2. Create an endpoint policy in Fleet for the Linux VM\n'
printf '3. Generate enrollment token and enroll your Linux VM\n'
printf '4. Run setup-linux-vm.sh on the Linux VM to install Elastic Agent\n'
