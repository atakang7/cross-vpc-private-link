#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

DEV_PROFILE=${DEV_PROFILE:-dev}
SERVER_ARN=${1:-${SERVER_ARN:-}}
CA_ARN=${2:-${CA_ARN:-}}
SERVICE_NAME=${3:-${SERVICE_NAME:-}}

[[ -f envs/dev/backend.hcl ]] || { echo "Configure envs/dev/backend.hcl first." >&2; exit 1; }
for value in "$SERVER_ARN" "$CA_ARN" "$SERVICE_NAME"; do
  [[ -n "$value" ]] || { echo "Required: SERVER_ARN, CA_ARN and SERVICE_NAME (or 3 arguments)." >&2; exit 1; }
done

AWS_PROFILE="$DEV_PROFILE" tofu -chdir=envs/dev init -backend-config=backend.hcl
AWS_PROFILE="$DEV_PROFILE" tofu -chdir=envs/dev apply \
  -var "vpn_server_cert_arn=$SERVER_ARN" \
  -var "vpn_root_ca_arn=$CA_ARN" \
  -var "privatelink_service_name=$SERVICE_NAME"
