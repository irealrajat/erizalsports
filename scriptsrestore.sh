#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_DIR"

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo:"
    echo "sudo ./scripts/restore.sh /path/to/backup"
    exit 1
fi

if [[ $# -ne 1 ]]; then
    echo "Usage:"
    echo
    echo "sudo ./scripts/restore.sh /path/to/backup"
    exit 1
fi

BACKUP="$1"

if [[ ! -d "$BACKUP" ]]; then
    echo "Backup directory does not exist:"
    echo "$BACKUP"
    exit 1
fi

if [[ ! -f "$BACKUP/database.sql.gz" ]]; then
    echo "database.sql.gz not found."
    exit 1
fi

if [[ ! -f "$BACKUP/wordpress.tar.gz" ]]; then
    echo "wordpress.tar.gz not found."
    exit 1
fi

set -a
source .env
set +a

echo
echo "WARNING!"
echo
echo "This will overwrite the current WordPress files and database."
echo
read -r -p "Type RESTORE to continue: " CONFIRM

if [[ "$CONFIRM" != "RESTORE" ]]; then
    echo "Restore cancelled."
    exit 1
fi

#############################################
# STOP WORDPRESS
#############################################

docker compose stop wordpress

#############################################
# RESTORE WORDPRESS FILES
#############################################

echo
echo "Restoring WordPress files..."

docker run --rm \
    -v "${COMPOSE_PROJECT_NAME}_wordpress_data:/destination" \
    -v "${BACKUP}:/backup:ro" \
    alpine:latest \
    sh -c "rm -rf /destination/* /destination/.[!.]* /destination/..?* 2>/dev/null || true; tar xzf /backup/wordpress.tar.gz -C /destination"

#############################################
# START MYSQL
#############################################

docker compose up -d db

echo
echo "Waiting for MySQL..."

sleep 15

#############################################
# RESTORE DATABASE
#############################################

echo
echo "Restoring database..."

gunzip -c "$BACKUP/database.sql.gz" \
    | docker compose exec -T db \
      mysql \
      -u root \
      -p"${MYSQL_ROOT_PASSWORD}" \
      "${MYSQL_DATABASE}"

#############################################
# START EVERYTHING
#############################################

docker compose up -d

echo
echo "Restore completed."

docker compose ps