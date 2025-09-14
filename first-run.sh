#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

DEV_PROFILE=${DEV_PROFILE:-dev}
PROD_PROFILE=${PROD_PROFILE:-prod}

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  echo "Do not run this script with sudo/root. AWS CLI and OpenTofu will not see your user profiles." >&2
  echo "Run: DEV_PROFILE=$DEV_PROFILE PROD_PROFILE=$PROD_PROFILE bash first-run.sh" >&2
  exit 1
fi

echo "[1/6] Checking prerequisites"
bash scripts/00_check_prereqs.sh

echo "[2/6] Generating demo certificates (optional)"
bash scripts/10_generate_certs.sh || true

echo "[3/6] Importing ACM certificates to $DEV_PROFILE"
ARN_OUTPUT=$(bash scripts/20_import_acm.sh "$DEV_PROFILE" || true)
echo "$ARN_OUTPUT"
SERVER_ARN=$(echo "$ARN_OUTPUT" | awk -F= '/SERVER_ARN/ {print $2}' || true)
CA_ARN=$(echo "$ARN_OUTPUT" | awk -F= '/CA_ARN/ {print $2}' || true)

echo "[4/6] Deploying provider (prod) with OpenTofu"
AWS_PROFILE="$PROD_PROFILE" tofu -chdir=envs/prod init
AWS_PROFILE="$PROD_PROFILE" tofu -chdir=envs/prod apply -auto-approve

echo "[5/6] Deploying dev environment"
./scripts/40_deploy_dev.sh "$@"

echo "[6/6] Exporting VPN config (if VPN created)"
./scripts/50_export_vpn_config.sh "$@"

echo "Done. If VPN was created, connect with: sudo openvpn --config ./dev.ovpn --cert scripts/certs/client.crt --key scripts/certs/client.key --ca scripts/certs/ca.crt"

