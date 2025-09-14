#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

PROFILE=${1:-dev}
CERT_DIR="$(pwd)/certs"

if [[ ! -f "$CERT_DIR/server.crt" ]]; then
  echo "Certs not found in $CERT_DIR; run 10_generate_certs.sh first" >&2
  exit 1
fi

SERVER_ARN=$(aws acm import-certificate --profile "$PROFILE" \
  --certificate fileb://"$CERT_DIR/server.crt" \
  --private-key fileb://"$CERT_DIR/server.key" \
  --certificate-chain fileb://"$CERT_DIR/ca.crt" \
  --query CertificateArn --output text)

CA_ARN=$(aws acm import-certificate --profile "$PROFILE" \
  --certificate fileb://"$CERT_DIR/ca.crt" \
  --private-key fileb://"$CERT_DIR/ca.key" \
  --query CertificateArn --output text)

echo "SERVER_ARN=$SERVER_ARN"
echo "CA_ARN=$CA_ARN"
