#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

SERVER_ARN=${1:-}
CA_ARN=${2:-}

pushd envs/dev >/dev/null
tofu init
if [[ -n "$SERVER_ARN" && -n "$CA_ARN" ]]; then
  tofu apply -auto-approve \
    -var "vpn_server_cert_arn=$SERVER_ARN" \
    -var "vpn_root_ca_arn=$CA_ARN"
else
  tofu apply -auto-approve
fi
popd >/dev/null
