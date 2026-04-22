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

  # Trim whitespace
  username="$(printf '%s' "${username}" | xargs)"

  if [[ -z "${username}" ]]; then
    username="docker-services"
  fi

  printf '%s\n' "${username}"
}

build_discord_embed_payload() {
  local title="${1}"
  local description="${2}"
  local color="${3}"
  local username="${4:-docker-services}"
  local hostname="${HOSTNAME:-$(hostname)}"
  local machine="${MACHINE_ID:-server01}"

  username="$(normalize_username "${username}")"

  local title_escaped
  local description_escaped
  local username_escaped
  local hostname_escaped
  local machine_escaped

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

post_discord_payload() {
  local payload="${1}"
  local webhook
  local response_file
  local http_code
  local retry_after

  if ! webhook="$(get_discord_webhook)"; then
    echo "[WARN] Discord webhook not configured; skipping notification"
    return 0
  fi

  response_file="$(mktemp)"

  http_code="$(
    curl -sS \
      -o "${response_file}" \
      -w "%{http_code}" \
      -H "Content-Type: application/json" \
      -X POST \
      -d "${payload}" \
      "${webhook}"
  )"

  if [[ "${http_code}" == "204" || "${http_code}" == "200" ]]; then
    rm -f "${response_file}"
    return 0
  fi

  if [[ "${http_code}" == "429" ]]; then
    retry_after="$(grep -o '"retry_after":[0-9.]*' "${response_file}" | cut -d: -f2 || true)"
    retry_after="${retry_after:-2}"
    sleep "${retry_after}"

    http_code="$(
      curl -sS \
        -o "${response_file}" \
        -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -X POST \
        -d "${payload}" \
        "${webhook}"
    )"

    if [[ "${http_code}" == "204" || "${http_code}" == "200" ]]; then
      rm -f "${response_file}"
      return 0
    fi
  fi

  echo "[WARN] Discord webhook returned HTTP ${http_code}"
  cat "${response_file}" || true
  rm -f "${response_file}"
  return 1
}

send_discord_embed() {
  local title="${1}"
  local description="${2}"
  local color="${3}"
  local username="${4:-docker-services}"

  username="$(normalize_username "${username}")"

  local payload
  payload="$(build_discord_embed_payload "${title}" "${description}" "${color}" "${username}")"
  post_discord_payload "${payload}"
}

send_discord_success() {
  local title="${1}"
  local description="${2}"
  local username="${3:-docker-services}"
  send_discord_embed "${title}" "${description}" 3066993 "${username}"
}

send_discord_warning() {
  local title="${1}"
  local description="${2}"
  local username="${3:-docker-services}"
  send_discord_embed "${title}" "${description}" 15105570 "${username}"
}

send_discord_error() {
  local title="${1}"
  local description="${2}"
  local username="${3:-docker-services}"
  send_discord_embed "${title}" "${description}" 15158332 "${username}"
}

send_discord_info() {
  local title="${1}"
  local description="${2}"
  local username="${3:-docker-services}"
  send_discord_embed "${title}" "${description}" 3447003 "${username}"
}
