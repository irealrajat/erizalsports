#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_DIR"

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo:"
    echo "sudo ./scripts/backup.sh"
    exit 1
fi

if [[ ! -f ".env" ]]; then
    echo ".env not found."
    exit 1
fi

set -a
source .env
set +a

: "${BACKUP_DIR:?BACKUP_DIR is missing from .env}"
: "${BACKUP_RETENTION:=7}"

DATE="$(date +%Y-%m-%d_%H-%M-%S)"

DEST="${BACKUP_DIR}/${DATE}"

mkdir -p "$DEST"

echo
echo "Creating backup:"
echo "$DEST"
echo

#############################################
# DATABASE
#############################################

echo "Backing up MySQL..."

docker compose exec -T db \
    mysqldump \
    -u root \
    -p"${MYSQL_ROOT_PASSWORD}" \
    --single-transaction \
    --routines \
    --triggers \
    "${MYSQL_DATABASE}" \
    | gzip > "${DEST}/database.sql.gz"

#############################################
# WORDPRESS FILES
#############################################

echo "Backing up WordPress files..."

docker run --rm \
    -v "${COMPOSE_PROJECT_NAME}_wordpress_data:/source:ro" \
    -v "${DEST}:/backup" \
    alpine:latest \
    tar czf /backup/wordpress.tar.gz -C /source .

#############################################
# ENVIRONMENT INFORMATION
#############################################

cat > "${DEST}/backup-info.txt" <<EOF
WooCommerce backup

Date:
$(date)

Domain:
${DOMAIN}

Project:
${COMPOSE_PROJECT_NAME}
EOF

#############################################
# RETENTION
#############################################

echo
echo "Removing old backups..."

find "$BACKUP_DIR" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -printf '%T@ %p\n' \
    | sort -nr \
    | tail -n +$((BACKUP_RETENTION + 1)) \
    | cut -d' ' -f2- \
    | xargs -r rm -rf

echo
echo "Backup completed:"
echo "$DEST"