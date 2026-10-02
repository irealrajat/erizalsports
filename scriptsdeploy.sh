#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_DIR"

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo:"
    echo "sudo ./scripts/deploy.sh"
    exit 1
fi

if [[ ! -f ".env" ]]; then
    echo ".env not found."
    exit 1
fi

echo "Pulling latest Docker images..."

docker compose pull

echo
echo "Starting containers..."

docker compose up -d

echo
echo "Current status:"

docker compose ps

echo
echo "Deployment completed."