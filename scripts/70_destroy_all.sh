#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

DEV_PROFILE=${DEV_PROFILE:-dev}
PROD_PROFILE=${PROD_PROFILE:-prod}
REGION=${AWS_REGION:-eu-central-1}

if (( EUID == 0 )); then
  echo "Run as a regular user, not root/sudo." >&2
  exit 1
fi
for env in dev prod; do
  [[ -f "envs/$env/backend.hcl" ]] || { echo "Missing envs/$env/backend.hcl." >&2; exit 1; }
done

if [[ "${1:-}" != "--yes" && "${1:-}" != "-y" ]]; then
  printf 'Destroy the DEV and PROD stacks (dev first)? This incurs permanent data loss.\n'
  printf 'AWS profiles: consumer=%s, provider=%s\n' "$DEV_PROFILE" "$PROD_PROFILE"
  read -r -p "Type 'destroy' to continue: " answer
  [[ "$answer" == "destroy" ]] || { echo "Aborted."; exit 1; }
fi

# Read the service name before destroying provider state. Supply SERVICE_NAME
# explicitly if the provider state has already been removed.
AWS_PROFILE="$PROD_PROFILE" tofu -chdir=envs/prod init -backend-config=backend.hcl
SERVICE_NAME=${SERVICE_NAME:-$(AWS_PROFILE="$PROD_PROFILE" tofu -chdir=envs/prod output -raw hello_world_service_name)}
[[ -n "$SERVICE_NAME" ]] || { echo "Missing PrivateLink service name." >&2; exit 1; }

# Certificate ARN input is required by the module schema even during destroy.
# Existing state contains actual resources; these placeholders are NOT applied.
PLACEHOLDER_ARN="arn:aws:acm:${REGION}:000000000000:certificate/00000000-0000-0000-0000-000000000000"
SERVER_ARN=${SERVER_ARN:-$PLACEHOLDER_ARN}
CA_ARN=${CA_ARN:-$PLACEHOLDER_ARN}

echo "[1/2] Destroying consumer resources"
AWS_PROFILE="$DEV_PROFILE" tofu -chdir=envs/dev init -backend-config=backend.hcl
AWS_PROFILE="$DEV_PROFILE" tofu -chdir=envs/dev destroy -auto-approve \
  -var "vpn_server_cert_arn=$SERVER_ARN" \
  -var "vpn_root_ca_arn=$CA_ARN" \
  -var "privatelink_service_name=$SERVICE_NAME"

DEV_ACCOUNT_ID=$(aws sts get-caller-identity --profile "$DEV_PROFILE" --query Account --output text)
[[ "$DEV_ACCOUNT_ID" =~ ^[0-9]{12}$ ]] || { echo "Invalid consumer AWS account." >&2; exit 1; }

echo "[2/2] Destroying provider resources"
AWS_PROFILE="$PROD_PROFILE" tofu -chdir=envs/prod destroy -auto-approve \
  -var "dev_account_root_arn=arn:aws:iam::${DEV_ACCOUNT_ID}:root"

echo "Stacks removed. ACM imported certificates and remote state backends are not managed by these stacks."
