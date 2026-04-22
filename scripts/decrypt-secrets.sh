#!/usr/bin/env bash
set -euo pipefail

MACHINE_ID="${MACHINE_ID:-server01}"
SECRETS_DIR="./secrets/${MACHINE_ID}"
RUNTIME_DIR="./runtime/${MACHINE_ID}/secrets"

mkdir -p "${RUNTIME_DIR}"

sops --decrypt \
  --output "${RUNTIME_DIR}/pihole_web_password.txt" \
  "${SECRETS_DIR}/pihole_web_password.txt.enc"

chmod 600 "${RUNTIME_DIR}/pihole_web_password.txt"

echo "Decrypted Pi-hole secrets to ${RUNTIME_DIR}"
