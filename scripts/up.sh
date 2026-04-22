#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

if [[ ! -f "./env/server01.env" ]]; then
  echo "Missing ./env/server01.env"
  echo "Create it from ./env/server01.env.example"
  exit 1
fi

"${SCRIPT_DIR}/decrypt-secrets.sh"
"${SCRIPT_DIR}/validate.sh"

docker compose --env-file ./env/server01.env up -d
