#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WARN_PERCENT="${WARN_PERCENT:-85}"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/notify-discord.sh"

usage_line="$(df -P "${REPO_ROOT}" | awk 'NR==2 {print $5 " " $4 " " $6}')"
usage_percent="$(printf '%s' "${usage_line}" | awk '{print $1}' | tr -d '%')"
available_space="$(printf '%s' "${usage_line}" | awk '{print $2}')"
mount_point="$(printf '%s' "${usage_line}" | awk '{print $3}')"

if (( usage_percent >= WARN_PERCENT )); then
  message=$(cat <<EOF
Docker services host disk usage is above threshold.

Usage: ${usage_percent}%
Available: ${available_space}
Mount: ${mount_point}
Threshold: ${WARN_PERCENT}%
EOF
)

  send_discord_warning \
    "Disk Usage Warning" \
    "${message}" \
    "docker-disk-check"

  exit 1
fi

message=$(cat <<EOF
Docker services disk usage is within threshold.

Usage: ${usage_percent}%
Available: ${available_space}
Mount: ${mount_point}
Threshold: ${WARN_PERCENT}%
EOF
)

send_discord_info \
  "Disk Check Passed" \
  "${message}" \
  "docker-disk-check"
