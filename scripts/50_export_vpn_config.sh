#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

PROFILE=${1:-dev}
OUT=${2:-dev.ovpn}
REGION=${3:-}

# Get endpoint ID from state
VPN_ENDPOINT_ID=$(AWS_PROFILE="$PROFILE" tofu -chdir=envs/dev output -raw vpn_endpoint 2>/dev/null || true)
if [[ -z "$VPN_ENDPOINT_ID" ]]; then
  echo "No vpn_endpoint output found; ensure VPN was created (pass ACM ARNs)." >&2
  exit 1
fi

# Detect region from vpn_dns if not provided
if [[ -z "$REGION" ]]; then
  VPN_DNS=$(AWS_PROFILE="$PROFILE" tofu -chdir=envs/dev output -raw vpn_dns 2>/dev/null || true)
  if [[ "$VPN_DNS" =~ \.clientvpn\.([a-z0-9-]+)\.amazonaws\.com$ ]]; then
    REGION="${BASH_REMATCH[1]}"
  fi
fi

export AWS_PAGER=""

# Build base AWS CLI args
BASE=(aws ec2 export-client-vpn-client-configuration --no-cli-pager --profile "$PROFILE" --client-vpn-endpoint-id "$VPN_ENDPOINT_ID")
if [[ -n "$REGION" ]]; then
  BASE+=(--region "$REGION")
fi

# Prefer JSON + jq, fallback to text
CONFIG=""
if command -v jq >/dev/null 2>&1; then
  CONFIG=$({ "${BASE[@]}" --output json 2>/dev/null || true; } | jq -r '.ClientConfiguration' 2>/dev/null || true)
fi
if [[ -z "$CONFIG" ]]; then
  CONFIG=$("${BASE[@]}" --output text --query 'ClientConfiguration' 2>/dev/null || true)
fi
if [[ -z "$CONFIG" ]]; then
  CONFIG=$("${BASE[@]}" --output text 2>/dev/null || true)
fi

if [[ -z "$CONFIG" ]]; then
  echo "Failed to export VPN config. Profile='$PROFILE' Endpoint='$VPN_ENDPOINT_ID' Region='${REGION:-unset}'." >&2
  echo "Tip: AWS_PROFILE=$PROFILE aws ec2 describe-client-vpn-endpoints --client-vpn-endpoint-ids $VPN_ENDPOINT_ID ${REGION:+--region $REGION}" >&2
  exit 1
fi

printf '%s\n' "$CONFIG" > "$OUT"
echo "Exported VPN config to $OUT"
