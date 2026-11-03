#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

PROD_PROFILE=${PROD_PROFILE:-prod}
DEV_PROFILE=${DEV_PROFILE:-dev}

[[ -f envs/prod/backend.hcl ]] || { echo "Configure envs/prod/backend.hcl first." >&2; exit 1; }
DEV_ACCOUNT_ID=$(aws sts get-caller-identity --profile "$DEV_PROFILE" --query Account --output text)
[[ "$DEV_ACCOUNT_ID" =~ ^[0-9]{12}$ ]] || { echo "Invalid consumer AWS account." >&2; exit 1; }

AWS_PROFILE="$PROD_PROFILE" tofu -chdir=envs/prod init -backend-config=backend.hcl
AWS_PROFILE="$PROD_PROFILE" tofu -chdir=envs/prod apply \
  -var "dev_account_root_arn=arn:aws:iam::${DEV_ACCOUNT_ID}:root"
AWS_PROFILE="$PROD_PROFILE" tofu -chdir=envs/prod output -raw hello_world_service_name
