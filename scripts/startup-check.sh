#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MACHINE_ID="${MACHINE_ID:-server01}"
ENV_FILE="${REPO_ROOT}/env/${MACHINE_ID}.env"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/notify-discord.sh"

log_step() {
  echo "▶ $1"
}

log_info() {
  echo "• $1"
}

log_success() {
  echo "✓ $1"
}

log_warn() {
  echo "⚠ $1"
}

log_error() {
  echo "✗ $1"
}

if [[ ! -f "${ENV_FILE}" ]]; then
  log_error "Missing ${ENV_FILE}"
  exit 1
fi

cd "${REPO_ROOT}"

log_step "Validating docker-compose configuration..."
docker compose --env-file "${ENV_FILE}" --profile apps config >/dev/null
log_success "docker-compose configuration is valid"

log_step "Checking service state..."

status_lines="$(
  docker compose --env-file "${ENV_FILE}" --profile apps ps --format json \
    | jq -r '
        if type == "array" then .[] else . end
        | "\(.Name // .Service // "unknown")\t\(.State // .Status // "unknown")\t\(.Health // "none")"
      '
)"

if [[ -z "${status_lines}" ]]; then
  log_error "No docker compose services found"
  send_discord_error \
    "Startup Check Failed" \
    "docker-services startup check found no services." \
    "docker-startup-check"
  exit 1
fi

bad_lines=""
summary_lines=""

while IFS=$'\t' read -r name state health; do
  [[ -z "${name}" ]] && continue

  summary_lines+="${name}: state=${state}, health=${health}"$'\n'

  case "${state}" in
    exited|dead|restarting)
      bad_lines+="${name}: state=${state}, health=${health}"$'\n'
      ;;
    *)
      if [[ "${health}" == "unhealthy" ]]; then
        bad_lines+="${name}: state=${state}, health=${health}"$'\n'
      fi
      ;;
  esac
done <<< "${status_lines}"

if [[ -n "${bad_lines}" ]]; then
  log_warn "Some services are not healthy"
  printf '%s' "${bad_lines}"

  send_discord_warning \
    "Startup Check Warning" \
    "docker-services startup check found services not fully healthy.\n\n${bad_lines}" \
    "docker-startup-check"
  exit 1
fi

log_success "All detected services are running acceptably"

send_discord_success \
  "Startup Check Passed" \
  "docker-services startup check passed.\n\n${summary_lines}" \
  "docker-startup-check"
