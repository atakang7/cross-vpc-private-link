#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# AWS CLI profiles (override by exporting DEV_PROFILE/PROD_PROFILE)
DEV_PROFILE=${DEV_PROFILE:-dev}
PROD_PROFILE=${PROD_PROFILE:-prod}

# Protect against running with sudo/root where profiles are not visible
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  echo "Do not run this script as root/sudo. AWS CLI and OpenTofu may not see your user profiles." >&2
  echo "Run as your user, e.g.: DEV_PROFILE=$DEV_PROFILE PROD_PROFILE=$PROD_PROFILE bash scripts/70_destroy_all.sh" >&2
  exit 1
fi

# Simple confirmation unless -y/--yes is provided
CONFIRM=${1:-}
if [[ "$CONFIRM" != "-y" && "$CONFIRM" != "--yes" ]]; then
  echo "This will DESTROY all resources in both environments with OpenTofu (order: dev -> prod)."
  echo "Profiles: DEV_PROFILE=$DEV_PROFILE, PROD_PROFILE=$PROD_PROFILE"
  read -r -p "Type 'destroy' to proceed: " ans
  if [[ "$ans" != "destroy" ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# Destroy consumer first (dev), then provider (prod)
echo "[1/2] Destroying consumer (dev)"
AWS_PROFILE="$DEV_PROFILE" tofu -chdir=envs/dev init -reconfigure || true
# Avoid interactive var prompts: pass syntactically valid placeholder ARNs
# Detect region from state outputs (vpn_dns), fallback to env/AWS default, then eu-central-1
DEV_REGION="${DEV_REGION:-}"
if [[ -z "$DEV_REGION" ]]; then
  DEV_VPN_DNS=$(AWS_PROFILE="$DEV_PROFILE" tofu -chdir=envs/dev output -raw vpn_dns 2>/dev/null || true)
  if [[ "$DEV_VPN_DNS" =~ \\.clientvpn\\.([a-z0-9-]+)\\.amazonaws\\.com$ ]]; then
    DEV_REGION="${BASH_REMATCH[1]}"
  fi
fi
if [[ -z "$DEV_REGION" ]]; then
  DEV_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-eu-central-1}}"
fi

VPN_SERVER_CERT_ARN=${VPN_SERVER_CERT_ARN:-"arn:aws:acm:$DEV_REGION:000000000000:certificate/00000000-0000-0000-0000-000000000000"}
VPN_ROOT_CA_ARN=${VPN_ROOT_CA_ARN:-"arn:aws:acm:$DEV_REGION:000000000000:certificate/00000000-0000-0000-0000-000000000000"}

AWS_PROFILE="$DEV_PROFILE" TF_INPUT=0 tofu -chdir=envs/dev destroy -auto-approve \
  -var "vpn_server_cert_arn=$VPN_SERVER_CERT_ARN" \
  -var "vpn_root_ca_arn=$VPN_ROOT_CA_ARN"


echo "[2/2] Destroying provider (prod)"
AWS_PROFILE="$PROD_PROFILE" tofu -chdir=envs/prod init -reconfigure || true
AWS_PROFILE="$PROD_PROFILE" TF_INPUT=0 tofu -chdir=envs/prod destroy -auto-approve


echo "All done. Both environments have been destroyed."
