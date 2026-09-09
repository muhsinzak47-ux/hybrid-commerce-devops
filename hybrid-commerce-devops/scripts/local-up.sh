#!/bin/bash
# ============================================================================
# Hybrid Commerce - Local Development Start Script
# Purpose: Start the application locally using Docker Compose
# Usage: ./scripts/local-up.sh
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="${PROJECT_ROOT}/docker"

cd "$PROJECT_ROOT"

echo "Starting Hybrid Commerce locally..."

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "ERROR: Docker Compose is not installed"
    exit 1
fi

# Create .env if not exists
if [ ! -f "${DOCKER_DIR}/.env" ]; then
    echo "Creating .env file from example..."
    cp "${PROJECT_ROOT}/app/backend/.env.example" "${DOCKER_DIR}/.env"
    # Generate a secure secret key
    SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    sed -i "s/SECRET_KEY=your-secret-key-here/SECRET_KEY=${SECRET_KEY}/" "${DOCKER_DIR}/.env"
fi

# Start Docker Compose
cd "$DOCKER_DIR"
docker-compose up -d

echo ""
echo "=========================================="
echo "Hybrid Commerce Local Development"
echo "=========================================="
echo "Frontend:   http://localhost:5173"
echo "Backend:    http://localhost:8000"
echo "API Docs:   http://localhost:8000/docs"
echo "Health:     http://localhost:8000/health"
echo "PostgreSQL: localhost:5432"
echo "Redis:      localhost:6379"
echo "=========================================="
echo ""
echo "Logs: docker-compose logs -f"
echo "Stop: docker-compose down"
echo "=========================================="
