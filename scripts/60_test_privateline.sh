#!/usr/bin/env bash
set -euo pipefail

HOST=${1:-hello.internal.company}
PORT=${2:-8080}

echo "Resolving $HOST..."
getent hosts "$HOST" || { echo "DNS lookup failed; check VPN DNS or VPC resolver." >&2; exit 1; }

echo "Testing http://$HOST:$PORT/"
curl --fail --silent --show-error --connect-timeout 5 --max-time 15 "http://$HOST:$PORT/"
printf '\n'
