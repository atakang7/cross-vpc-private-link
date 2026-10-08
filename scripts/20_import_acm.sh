#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

PROFILE=${1:-${DEV_PROFILE:-dev}}
REGION=${AWS_REGION:-eu-central-1}
CERT_DIR="$(pwd)/certs"

for file in server.crt server.key ca.crt ca.key; do
  [[ -f "$CERT_DIR/$file" ]] || { echo "Missing $CERT_DIR/$file; generate certificates first." >&2; exit 1; }
done

SERVER_ARN=$(aws acm import-certificate --profile "$PROFILE" --region "$REGION" \
  --certificate "fileb://$CERT_DIR/server.crt" \
  --private-key "fileb://$CERT_DIR/server.key" \
  --certificate-chain "fileb://$CERT_DIR/ca.crt" \
  --query CertificateArn --output text)

CA_ARN=$(aws acm import-certificate --profile "$PROFILE" --region "$REGION" \
  --certificate "fileb://$CERT_DIR/ca.crt" \
  --private-key "fileb://$CERT_DIR/ca.key" \
  --query CertificateArn --output text)

printf 'SERVER_ARN=%s\nCA_ARN=%s\n' "$SERVER_ARN" "$CA_ARN"
