#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MACHINE_ID="${MACHINE_ID:-server01}"
ENV_FILE="${REPO_ROOT}/env/${MACHINE_ID}.env"
STATE_DIR="${REPO_ROOT}/runtime/${MACHINE_ID}/monitor"
STATE_FILE="${STATE_DIR}/state.tsv"
TMP_FILE="$(mktemp)"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/notify-discord.sh"

mkdir -p "${STATE_DIR}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "[ERROR] Missing ${ENV_FILE}"
  exit 1
fi

cd "${REPO_ROOT}"

docker compose --env-file "${ENV_FILE}" --profile apps ps --format json \
  | jq -r '
      if type == "array" then .[] else . end
      | [
          (.Name // .Service // "unknown"),
          (.State // .Status // "unknown"),
          (.Health // "none")
        ]
      | @tsv
    ' \
  | sort > "${TMP_FILE}"

if [[ ! -f "${STATE_FILE}" ]]; then
  cp "${TMP_FILE}" "${STATE_FILE}"
  send_discord_info "Monitor Initialized" "docker-services monitor initialized successfully." "docker-monitor"
  rm -f "${TMP_FILE}"
  exit 0
fi

join -t $'\t' -a1 -a2 -e "missing" -o '0,1.2,1.3,2.2,2.3' \
  <(sort "${STATE_FILE}") \
  <(sort "${TMP_FILE}") \
  | while IFS=$'\t' read -r name old_state old_health new_state new_health; do

    if [[ "${old_state}" == "${new_state}" && "${old_health}" == "${new_health}" ]]; then
      continue
    fi

    if [[ "${new_state}" == "running" && "${new_health}" == "healthy" ]]; then
      send_discord_success \
        "Container Recovered" \
        "${name} recovered.\n\nOld: state=${old_state}, health=${old_health}\nNew: state=${new_state}, health=${new_health}" \
        "docker-monitor"
    elif [[ "${new_state}" == "running" && "${new_health}" == "unhealthy" ]]; then
      send_discord_error \
        "Container Unhealthy" \
        "${name} became unhealthy.\n\nOld: state=${old_state}, health=${old_health}\nNew: state=${new_state}, health=${new_health}" \
        "docker-monitor"
    elif [[ "${new_state}" == "exited" || "${new_state}" == "dead" ]]; then
      send_discord_error \
        "Container Stopped" \
        "${name} stopped.\n\nOld: state=${old_state}, health=${old_health}\nNew: state=${new_state}, health=${new_health}" \
        "docker-monitor"
    elif [[ "${new_state}" == "restarting" ]]; then
      send_discord_warning \
        "Container Restarting" \
        "${name} is restarting.\n\nOld: state=${old_state}, health=${old_health}\nNew: state=${new_state}, health=${new_health}" \
        "docker-monitor"
    elif [[ "${new_state}" == "missing" ]]; then
      send_discord_warning \
        "Container Missing" \
        "${name} disappeared from docker-services." \
        "docker-monitor"
    elif [[ "${old_state}" == "missing" ]]; then
      send_discord_success \
        "Container Added" \
        "${name} appeared.\n\nState=${new_state}, health=${new_health}" \
        "docker-monitor"
    else
      send_discord_info \
        "Container State Changed" \
        "${name} changed.\n\nOld: state=${old_state}, health=${old_health}\nNew: state=${new_state}, health=${new_health}" \
        "docker-monitor"
    fi
  done

cp "${TMP_FILE}" "${STATE_FILE}"
rm -f "${TMP_FILE}"
