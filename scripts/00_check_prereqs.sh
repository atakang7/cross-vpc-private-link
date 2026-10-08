#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

for tool in tofu aws openssl curl getent; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing prerequisite: $tool" >&2
    exit 1
  fi
done
echo "Prerequisites OK."
