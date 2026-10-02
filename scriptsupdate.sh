#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_DIR"

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo:"
    echo "sudo ./scripts/update.sh"
    exit 1
fi

echo
echo "=========================================="
echo " WooCommerce Update"
echo "=========================================="
echo

#############################################
# BACKUP FIRST
#############################################

echo "Creating backup before update..."

"$PROJECT_DIR/scripts/backup.sh"

#############################################
# GIT UPDATE
#############################################

echo
echo "Updating Git repository..."

git pull --ff-only

#############################################
# DOCKER UPDATE
#############################################

echo
echo "Pulling new images..."

docker compose pull

echo
echo "Recreating containers..."

docker compose up -d

#############################################
# STATUS
#############################################

echo
echo "Containers:"

docker compose ps

echo
echo "Update completed."