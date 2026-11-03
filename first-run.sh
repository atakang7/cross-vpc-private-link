#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

DEV_PROFILE=${DEV_PROFILE:-dev}
PROD_PROFILE=${PROD_PROFILE:-prod}

if (( EUID == 0 )); then
  echo "Run as a regular user, not root/sudo." >&2
  exit 1
fi

bash scripts/00_check_prereqs.sh

# Fail before creating certificates or AWS resources if either account or
# pre-provisioned remote state backend is unavailable.
for env in dev prod; do
  if [[ ! -f "envs/$env/backend.hcl" ]]; then
    echo "Missing envs/$env/backend.hcl (copy the .example and configure state)." >&2
    exit 1
  fi
done

DEV_ACCOUNT_ID=$(aws sts get-caller-identity --profile "$DEV_PROFILE" --query Account --output text)
PROD_ACCOUNT_ID=$(aws sts get-caller-identity --profile "$PROD_PROFILE" --query Account --output text)
if [[ ! "$DEV_ACCOUNT_ID" =~ ^[0-9]{12}$ || ! "$PROD_ACCOUNT_ID" =~ ^[0-9]{12}$ || "$DEV_ACCOUNT_ID" == "$PROD_ACCOUNT_ID" ]]; then
  echo "Expected two distinct, valid AWS accounts (profiles $DEV_PROFILE / $PROD_PROFILE)." >&2
  exit 1
fi
echo "Provider account: $PROD_ACCOUNT_ID; consumer account: $DEV_ACCOUNT_ID"

echo "[1/5] Generating demo VPN certificates"
bash scripts/10_generate_certs.sh

echo "[2/5] Importing VPN certificates into consumer account"
ARN_OUTPUT=$(bash scripts/20_import_acm.sh "$DEV_PROFILE")
SERVER_ARN=$(printf '%s\n' "$ARN_OUTPUT" | sed -n 's/^SERVER_ARN=//p')
CA_ARN=$(printf '%s\n' "$ARN_OUTPUT" | sed -n 's/^CA_ARN=//p')
if [[ ! "$SERVER_ARN" == arn:aws:acm:* || ! "$CA_ARN" == arn:aws:acm:* ]]; then
  echo "ACM import did not return both certificate ARNs." >&2
  exit 1
fi

echo "[3/5] Deploying provider account (review the plan)"
DEV_PROFILE="$DEV_PROFILE" PROD_PROFILE="$PROD_PROFILE" bash scripts/30_deploy_prod.sh

SERVICE_NAME=$(AWS_PROFILE="$PROD_PROFILE" tofu -chdir=envs/prod output -raw hello_world_service_name)
if [[ ! "$SERVICE_NAME" == com.amazonaws.vpce.* ]]; then
  echo "Provider did not export a valid service name." >&2
  exit 1
fi

echo "[4/5] Deploying consumer account (review the plan)"
DEV_PROFILE="$DEV_PROFILE" bash scripts/40_deploy_dev.sh "$SERVER_ARN" "$CA_ARN" "$SERVICE_NAME"

echo "[5/5] Exporting Client VPN configuration"
bash scripts/50_export_vpn_config.sh "$DEV_PROFILE" dev.ovpn
echo "Connect: sudo openvpn --config dev.ovpn --cert scripts/certs/client.crt --key scripts/certs/client.key --ca scripts/certs/ca.crt"
