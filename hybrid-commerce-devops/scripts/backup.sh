#!/bin/bash
# ============================================================================
# Hybrid Commerce - Backup Script
# Purpose: Backup SQLite database and application config
# Usage: ./scripts/backup.sh
# ============================================================================

set -e

BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
APP_DIR="/opt/hybrid-commerce"
EC2_HOST="ec2-15-252-96-217.ap-south-1.compute.amazonaws.com"
SSH_KEY="$HOME/.ssh/zakkey.pem"
EC2_USER="ubuntu"

mkdir -p "$BACKUP_DIR"

echo "Creating backup at $(date)..."

# Backup local database if exists
if [ -f "./app/backend/hybrid.db" ]; then
    cp "./app/backend/hybrid.db" "${BACKUP_DIR}/hybrid_db_${DATE}.sqlite"
    echo "Local database backed up"
fi

# Backup EC2 database
ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "sudo cp ${APP_DIR}/hybrid.db /tmp/hybrid_db_backup_${DATE}.sqlite 2>/dev/null || true"

# Create tarball of backups
tar -czf "${BACKUP_DIR}/backup_${DATE}.tar.gz" -C "$BACKUP_DIR" "hybrid_db_${DATE}.sqlite" 2>/dev/null || true

# Clean up old backups (keep last 7 days)
find "$BACKUP_DIR" -name "*.sqlite" -mtime +7 -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete 2>/dev/null || true

echo "Backup complete: ${BACKUP_DIR}/"
ls -lh "$BACKUP_DIR/"
