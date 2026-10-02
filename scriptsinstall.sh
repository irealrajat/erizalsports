#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_DIR"

echo
echo "=========================================="
echo " WooCommerce VPS Installer"
echo "=========================================="
echo

if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo:"
    echo
    echo "sudo ./scripts/install.sh"
    exit 1
fi

#############################################
# CHECK .ENV
#############################################

if [[ ! -f "$PROJECT_DIR/.env" ]]; then
    echo "ERROR: .env file not found."
    echo
    echo "Create it first:"
    echo
    echo "cp .env.example .env"
    echo "nano .env"
    exit 1
fi

set -a
source "$PROJECT_DIR/.env"
set +a

#############################################
# REQUIRED VARIABLES
#############################################

: "${DOMAIN:?DOMAIN is missing from .env}"
: "${WORDPRESS_PORT:?WORDPRESS_PORT is missing from .env}"
: "${CADDYFILE:?CADDYFILE is missing from .env}"
: "${CADDY_SITES_DIR:?CADDY_SITES_DIR is missing from .env}"

#############################################
# CHECK DOCKER
#############################################

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is not installed."
    echo "Install Docker first."
    exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
    echo "ERROR: Docker Compose plugin is not installed."
    exit 1
fi

echo "Docker:"
docker --version

echo
echo "Docker Compose:"
docker compose version

#############################################
# CHECK CADDY
#############################################

if ! command -v caddy >/dev/null 2>&1; then
    echo "ERROR: Caddy is not installed."
    exit 1
fi

if [[ ! -f "$CADDYFILE" ]]; then
    echo "ERROR: Caddyfile not found:"
    echo "$CADDYFILE"
    exit 1
fi

#############################################
# CHECK PORT
#############################################

if ss -lnt | grep -q ":${WORDPRESS_PORT} "; then
    echo
    echo "WARNING:"
    echo "Port ${WORDPRESS_PORT} appears to already be in use."
    echo
    ss -lntp | grep ":${WORDPRESS_PORT} " || true
    echo
    read -r -p "Continue anyway? [y/N]: " ANSWER

    if [[ ! "$ANSWER" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

#############################################
# CREATE CADDY DIRECTORY
#############################################

mkdir -p "$CADDY_SITES_DIR"

#############################################
# ENABLE CADDY IMPORT
#############################################

if ! grep -qF "import ${CADDY_SITES_DIR}/*" "$CADDYFILE"; then

    echo
    echo "Adding Caddy sites import..."

    cp "$CADDYFILE" "${CADDYFILE}.backup.$(date +%Y%m%d-%H%M%S)"

    cat >> "$CADDYFILE" <<EOF

# WooCommerce Docker sites
import ${CADDY_SITES_DIR}/*
EOF

fi

#############################################
# CREATE CADDY SITE
#############################################

CADDY_SITE_FILE="${CADDY_SITES_DIR}/${DOMAIN}.caddy"

cat > "$CADDY_SITE_FILE" <<EOF
${DOMAIN} {
    reverse_proxy 127.0.0.1:${WORDPRESS_PORT}
}
EOF

echo
echo "Generated Caddy configuration:"
echo
cat "$CADDY_SITE_FILE"

#############################################
# VALIDATE CADDY
#############################################

echo
echo "Validating Caddy configuration..."

caddy validate --config "$CADDYFILE"

#############################################
# START DOCKER
#############################################

echo
echo "Pulling Docker images..."

docker compose pull

echo
echo "Starting WooCommerce..."

docker compose up -d

#############################################
# RELOAD CADDY
#############################################

echo
echo "Reloading Caddy..."

systemctl reload caddy

#############################################
# STATUS
#############################################

echo
echo "=========================================="
echo " Installation completed"
echo "=========================================="
echo

docker compose ps

echo
echo "Website:"
echo "https://${DOMAIN}"

echo
echo "WordPress container:"
echo "127.0.0.1:${WORDPRESS_PORT}"

echo
echo "Caddy:"
echo "Ports 80/443 remain managed by Caddy."

echo
echo "Open the following URL:"
echo
echo "https://${DOMAIN}"
echo