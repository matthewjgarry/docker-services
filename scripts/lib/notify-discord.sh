#!/usr/bin/env bash
set -euo pipefail

DOCKER_SERVICES_WEBHOOK_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/docker-services/discord-webhook"
DOTFILES_WEBHOOK_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/discord-webhook"
HOMELAB_WEBHOOK_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/homelab/discord-webhook"

get_discord_webhook() {
  if [[ -n "${DOCKER_SERVICES_DISCORD_WEBHOOK_URL:-}" ]]; then
    printf '%s\n' "${DOCKER_SERVICES_DISCORD_WEBHOOK_URL}"
    return 0
  fi

  if [[ -f "${DOCKER_SERVICES_WEBHOOK_FILE}" ]]; then
    cat "${DOCKER_SERVICES_WEBHOOK_FILE}"
    return 0
  fi

  if [[ -n "${DISCORD_WEBHOOK_URL:-}" ]]; then
    printf '%s\n' "${DISCORD_WEBHOOK_URL}"
    return 0
  fi

  if [[ "${ALLOW_SHARED_DISCORD_WEBHOOK_FALLBACK:-false}" == "true" ]]; then
    if [[ -f "${DOTFILES_WEBHOOK_FILE}" ]]; then
      cat "${DOTFILES_WEBHOOK_FILE}"
      return 0
    fi

    if [[ -f "${HOMELAB_WEBHOOK_FILE}" ]]; then
      cat "${HOMELAB_WEBHOOK_FILE}"
      return 0
    fi
  fi

  return 1
}

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])'
}

normalize_username() {
  local username="${1:-docker-services}"
  username="$(printf '%s' "${username}" | xargs)"
  [[ -z "${username}" ]] && username="docker-services"
  printf '%s\n' "${username}"
}

normalize_message() {
  local message="${1:-}"
  # Convert literal "\n" sequences into real newlines for Discord readability.
  message="${message//\\n/$'\n'}"
  printf '%s' "${message}"
}

build_discord_embed_payload() {
  local title="${1}"
  local description="${2}"
  local color="${3}"
  local username="${4:-docker-services}"
  local hostname="${HOSTNAME:-$(hostname)}"
  local machine="${MACHINE_ID:-server01}"

  username="$(normalize_username "${username}")"
  description="$(normalize_message "${description}")"

  local title_escaped description_escaped username_escaped hostname_escaped machine_escaped
  title_escaped="$(printf '%s' "${title}" | json_escape)"
  description_escaped="$(printf '%s' "${description}" | json_escape)"
  username_escaped="$(printf '%s' "${username}" | json_escape)"
  hostname_escaped="$(printf '%s' "${hostname}" | json_escape)"
  machine_escaped="$(printf '%s' "${machine}" | json_escape)"

  cat <<EOF
{
  "username": "${username_escaped}",
  "embeds": [
    {
      "title": "${title_escaped}",
      "description": "${description_escaped}",
      "color": ${color},
      "fields": [
        { "name": "Machine", "value": "${machine_escaped}", "inline": true },
        { "name": "Host", "value": "${hostname_escaped}", "inline": true }
      ]
    }
  ]
}
EOF
}

send_discord_payload() {
  local payload="${1}"
  local webhook_url

  if ! webhook_url="$(get_discord_webhook)"; then
    echo "[WARN] No Discord webhook configured" >&2
    return 0
  fi

  local response http_code body
  response="$(curl -sS -w $'\n%{http_code}' \
    -H "Content-Type: application/json" \
    -X POST \
    -d "${payload}" \
    "${webhook_url}" || true)"

  http_code="$(printf '%s\n' "${response}" | tail -n1)"
  body="$(printf '%s\n' "${response}" | sed '$d')"

  if [[ "${http_code}" -lt 200 || "${http_code}" -ge 300 ]]; then
    echo "[WARN] Discord webhook returned HTTP ${http_code}" >&2
    [[ -n "${body}" ]] && echo "${body}" >&2
    return 1
  fi
}

send_discord_info() {
  local title="${1}"
  local message="${2}"
  local username="${3:-docker-services}"
  send_discord_payload "$(build_discord_embed_payload "ℹ️ ${title}" "${message}" 3447003 "${username}")"
}

send_discord_success() {
  local title="${1}"
  local message="${2}"
  local username="${3:-docker-services}"
  send_discord_payload "$(build_discord_embed_payload "✅ ${title}" "${message}" 5763719 "${username}")"
}

send_discord_warning() {
  local title="${1}"
  local message="${2}"
  local username="${3:-docker-services}"
  send_discord_payload "$(build_discord_embed_payload "⚠️ ${title}" "${message}" 16705372 "${username}")"
}

send_discord_error() {
  local title="${1}"
  local message="${2}"
  local username="${3:-docker-services}"
  send_discord_payload "$(build_discord_embed_payload "❌ ${title}" "${message}" 15548997 "${username}")"
}
