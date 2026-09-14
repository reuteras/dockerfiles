#!/usr/bin/env bash

set -euo pipefail

template=${1:-.env.example}
output=${2:-.env}

if [[ ! -f "$template" ]]; then
  printf 'Template not found: %s\n' "$template" >&2
  exit 1
fi

if [[ -e "$output" ]]; then
  printf 'Refusing to overwrite existing file: %s\n' "$output" >&2
  exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
  printf 'openssl is required but was not found in PATH.\n' >&2
  exit 1
fi

elastic_password=$(openssl rand -hex 24)
kibana_password=$(openssl rand -hex 24)
kibana_encryption_key=$(openssl rand -hex 32)

umask 077
temporary_file=$(mktemp "${output}.tmp.XXXXXX")
trap 'rm -f "$temporary_file"' EXIT

awk \
  -v elastic_password="$elastic_password" \
  -v kibana_password="$kibana_password" \
  -v kibana_encryption_key="$kibana_encryption_key" '
    /^ELASTIC_PASSWORD=/ {
      print "ELASTIC_PASSWORD=" elastic_password
      next
    }
    /^KIBANA_PASSWORD=/ {
      print "KIBANA_PASSWORD=" kibana_password
      next
    }
    /^KIBANA_ENCRYPTION_KEY=/ {
      print "KIBANA_ENCRYPTION_KEY=" kibana_encryption_key
      next
    }
    { print }
  ' "$template" >"$temporary_file"

mv "$temporary_file" "$output"
trap - EXIT

printf 'Created %s with permissions 600.\n' "$output"
printf 'Add the Fleet service token and policy ID after configuring Fleet in Kibana.\n'
