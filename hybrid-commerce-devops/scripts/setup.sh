#!/bin/bash
# ============================================================================
# Hybrid Commerce - Initial Server Setup
# Purpose: Set up a fresh Ubuntu 24.04 EC2 instance
# Usage: ./scripts/setup.sh
# ============================================================================

set -e

EC2_HOST="${1:-ec2-15-252-96-217.ap-south-1.compute.amazonaws.com}"
SSH_KEY="$HOME/.ssh/zakkey.pem"
EC2_USER="ubuntu"

echo "=========================================="
echo "Hybrid Commerce - Initial Server Setup"
echo "Target: ${EC2_HOST}"
echo "=========================================="

# Check SSH key
if [ ! -f "$SSH_KEY" ]; then
    echo "ERROR: SSH key not found at $SSH_KEY"
    exit 1
fi

echo "[1/6] Updating system packages..."
ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "sudo apt-get update && sudo apt-get upgrade -y"

echo "[2/6] Installing required packages..."
ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "sudo apt-get install -y python3 python3-pip python3-venv git curl wget ufw fail2ban"

echo "[3/6] Installing Docker..."
ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg"
ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu noble stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"
ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin"
ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "sudo systemctl start docker && sudo systemctl enable docker"

echo "[4/6] Configuring firewall (UFW)..."
ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "sudo ufw allow 22/tcp && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw allow 8000/tcp && sudo ufw --force enable"

echo "[5/6] Hardening SSH..."
ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && sudo sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && sudo systemctl restart ssh"

echo "[6/6] Creating application directories..."
ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "mkdir -p /opt/hybrid-commerce"

echo "=========================================="
echo "Initial setup complete!"
echo ""
echo "Next steps:"
echo "  1. Run: ./scripts/deploy.sh"
echo "  2. Access app at: http://${EC2_HOST}:8000"
echo "=========================================="
