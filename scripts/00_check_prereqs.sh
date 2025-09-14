#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing required tool: $1" >&2; exit 1; }; }

need tofu
need aws
need openssl
echo "Prereqs OK (tofu, aws, openssl)"
