#!/usr/bin/env bash
set -euo pipefail

WEBHOOK_URL="${N8N_EVENT_WEBHOOK_URL:?N8N_EVENT_WEBHOOK_URL is required}"

SOURCE="${1:-unknown}"
CHECK_NAME="${2:-unknown}"
SEVERITY="${3:-info}"
TITLE="${4:-Event}"
MESSAGE="${5:-No message provided}"
SERVICE="${6:-$SOURCE}"

HOSTNAME_VALUE="$(hostname)"
TIMESTAMP="$(date -Iseconds)"

payload="$(jq -n \
  --arg source "$SOURCE" \
  --arg machine_id "$HOSTNAME_VALUE" \
  --arg hostname "$HOSTNAME_VALUE" \
  --arg service "$SERVICE" \
  --arg check_name "$CHECK_NAME" \
  --arg severity "$SEVERITY" \
  --arg title "$TITLE" \
  --arg message "$MESSAGE" \
  --arg timestamp "$TIMESTAMP" \
  '{
    source: $source,
    machine_id: $machine_id,
    hostname: $hostname,
    service: $service,
    check_name: $check_name,
    severity: $severity,
    title: $title,
    message: $message,
    timestamp: $timestamp
  }'
)"

curl -fsS -X POST "$WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "$payload"
