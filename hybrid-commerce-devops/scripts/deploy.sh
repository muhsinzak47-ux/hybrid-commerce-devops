#!/bin/bash
# ============================================================================
# Hybrid Commerce - Deployment Script
# Purpose: Deploy application to EC2 instance
# Usage: ./scripts/deploy.sh
# ============================================================================

set -e

APP_NAME="hybrid-commerce"
APP_DIR="/opt/${APP_NAME}"
SSH_KEY="$HOME/.ssh/zakkey.pem"
EC2_HOST="ec2-15-252-96-217.ap-south-1.compute.amazonaws.com"
EC2_USER="ubuntu"

echo "=========================================="
echo "Hybrid Commerce Deployment Script"
echo "=========================================="

# Check if SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    echo "ERROR: SSH key not found at $SSH_KEY"
    echo "Create it with: ssh-keygen -t ed25519 -f $SSH_KEY"
    exit 1
fi

# Sync application files to EC2
echo "[1/5] Syncing application files to EC2..."
rsync -avz --exclude='venv' --exclude='__pycache__' \
    --exclude='*.pyc' --exclude='*.db' \
    --exclude='.env' \
    ./app/backend/ ${EC2_USER}@${EC2_HOST}:${APP_DIR}/

# Run remote setup commands
echo "[2/5] Setting up Python environment on EC2..."
ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} << 'REMOTE'
    set -e
    cd /opt/hybrid-commerce

    # Create virtual environment if not exists
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi

    # Activate and install dependencies
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt

    echo "Python environment ready"
REMOTE

# Create/update systemd service
echo "[3/5] Configuring systemd service..."
ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} << 'REMOTE'
    set -e

    cat > /etc/systemd/system/hybrid-commerce.service << 'EOF'
[Unit]
Description=Hybrid Commerce Backend API
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/hybrid-commerce
Environment="PATH=/opt/hybrid-commerce/venv/bin"
ExecStart=/opt/hybrid-commerce/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable hybrid-commerce
    systemctl restart hybrid-commerce

    echo "Systemd service configured"
REMOTE

# Wait for service to start
echo "[4/5] Waiting for application to start..."
sleep 10

# Health check
echo "[5/5] Running health check..."
HEALTH=$(ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/health")

if [ "$HEALTH" = "200" ]; then
    echo "=========================================="
    echo "Deployment successful!"
    echo "Application: http://${EC2_HOST}:8000"
    echo "API Docs: http://${EC2_HOST}:8000/docs"
    echo "Health: http://${EC2_HOST}:8000/health"
    echo "=========================================="
else
    echo "WARNING: Health check returned $HEALTH"
    echo "Check logs: ssh -i $SSH_KEY ${EC2_USER}@${EC2_HOST} 'journalctl -u hybrid-commerce -f'"
    exit 1
fi
