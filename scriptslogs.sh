#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_DIR"

SERVICE="${1:-wordpress}"

echo
echo "Showing logs for:"
echo "$SERVICE"
echo

docker compose logs -f --tail=200 "$SERVICE"