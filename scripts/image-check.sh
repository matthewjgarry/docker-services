#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MACHINE_ID="${MACHINE_ID:-server01}"
ENV_FILE="${REPO_ROOT}/env/${MACHINE_ID}.env"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/notify-discord.sh"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "[ERROR] Missing ${ENV_FILE}"
  exit 1
fi

cd "${REPO_ROOT}"

pull_output="$(docker compose --env-file "${ENV_FILE}" --profile apps pull 2>&1 || true)"
updated_lines="$(printf '%s\n' "${pull_output}" | grep -E 'Downloaded newer image|Pull complete|Status: Downloaded newer image' || true)"

if [[ -n "${updated_lines}" ]]; then
  send_discord_info \
    "Image Updates Available" \
    "docker-compose pull found newer images.\n\n${updated_lines}" \
    "docker-image-check"
else
  send_discord_success \
    "Image Check Passed" \
    "No newer images were found during docker compose pull." \
    "docker-image-check"
fi
