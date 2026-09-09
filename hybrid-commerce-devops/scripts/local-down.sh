#!/bin/bash
# ============================================================================
# Hybrid Commerce - Local Development Stop Script
# Purpose: Stop local Docker Compose
# Usage: ./scripts/local-down.sh
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="${PROJECT_ROOT}/docker"

cd "$DOCKER_DIR"

echo "Stopping Hybrid Commerce..."

docker-compose down

echo "Stopped. To remove volumes: docker-compose down -v"
