#!/usr/bin/env bash
set -euo pipefail

HOST=${1:-hello.internal.company}
PORT=${2:-8080}

echo "Resolving $HOST..."
getent hosts "$HOST" || { echo "DNS resolution failed; ensure VPN connected or inside VPC" >&2; exit 1; }

echo "Curling http://$HOST:$PORT"
curl -sS --max-time 3 "http://$HOST:$PORT" | sed -e 's/{/{\n  /' -e 's/}/\n}/' || {
  echo "Request failed; verify VPN and security groups" >&2; exit 1;
}
