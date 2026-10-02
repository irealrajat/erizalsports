#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_DIR"

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo:"
    echo "sudo ./scripts/uninstall.sh"
    exit 1
fi

if [[ ! -f ".env" ]]; then
    echo ".env not found."
    exit 1
fi

set -a
source .env
set +a

CADDY_SITE_FILE="${CADDY_SITES_DIR}/${DOMAIN}.caddy"

echo
echo "=========================================="
echo " WooCommerce Uninstaller"
echo "=========================================="
echo

echo "This will stop and remove the WooCommerce containers."
echo
echo "Docker volumes will NOT be deleted."
echo

read -r -p "Continue? [y/N]: " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

#############################################
# REMOVE CONTAINERS
#############################################

docker compose down

#############################################
# REMOVE CADDY SITE
#############################################

if [[ -f "$CADDY_SITE_FILE" ]]; then
    rm -f "$CADDY_SITE_FILE"
fi

#############################################
# RELOAD CADDY
#############################################

caddy validate --config "$CADDYFILE"

systemctl reload caddy

echo
echo "Containers removed."
echo "Docker volumes were preserved."
echo
echo "To see volumes:"
docker volume ls | grep "${COMPOSE_PROJECT_NAME}" || true