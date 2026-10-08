#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077

PROFILE=${1:-${DEV_PROFILE:-dev}}
OUT=${2:-dev.ovpn}
REGION=${3:-eu-central-1}
VPN_ENDPOINT_ID=$(AWS_PROFILE="$PROFILE" tofu -chdir=envs/dev output -raw vpn_endpoint)
[[ -n "$VPN_ENDPOINT_ID" ]] || { echo "No Client VPN endpoint in dev state." >&2; exit 1; }

aws ec2 export-client-vpn-client-configuration \
  --profile "$PROFILE" \
  --region "$REGION" \
  --client-vpn-endpoint-id "$VPN_ENDPOINT_ID" \
  --query ClientConfiguration \
  --output text > "$OUT"

[[ -s "$OUT" ]] || { rm -f "$OUT"; echo "VPN configuration export was empty." >&2; exit 1; }
chmod 0600 "$OUT"
echo "Exported $OUT (mode 0600); keep client keys private."
