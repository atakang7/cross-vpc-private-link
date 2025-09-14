#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

pushd envs/prod >/dev/null
tofu init
tofu apply -auto-approve
echo "PROD service name: $(tofu output -raw hello_world_service_name)"
popd >/dev/null
