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

# --- CHECK FOR UPDATES (DO NOT PULL) ---
PULL_OUTPUT="$(docker compose --env-file "${ENV_FILE}" --profile apps pull --dry-run 2>&1 || true)"

# --- PARSE UPDATED SERVICES ---
UPDATED_SERVICES="$(
  printf '%s\n' "${PULL_OUTPUT}" \
    | sed -nE 's/^.*(Downloading|Pulling).* ([^ ]+)$/\2/p' \
    | sort -u
)"

COUNT="$(printf '%s\n' "${UPDATED_SERVICES}" | grep -c . || true)"

# --- BUILD MESSAGE ---
if [[ "${COUNT}" -gt 0 ]]; then
  SERVICE_LIST="$(printf '%s\n' "${UPDATED_SERVICES}" | sed 's/^/• /' | head -n 15)"

  if (( COUNT > 15 )); then
    SERVICE_LIST+=$'\n'"• …and $((COUNT - 15)) more"
  fi

  MESSAGE=$(cat <<EOF
Image updates available

Services with updates: ${COUNT}

${SERVICE_LIST}
EOF
)

  send_discord_info \
    "Image Updates Available" \
    "${MESSAGE}" \
    "docker-image-check"

else
  MESSAGE="All container images are up to date"

  send_discord_success \
    "Image Check Passed" \
    "${MESSAGE}" \
    "docker-image-check"
fi
