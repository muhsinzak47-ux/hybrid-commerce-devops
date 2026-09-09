#!/bin/bash
# ============================================================================
# Hybrid Commerce - Cleanup Script (for demo/destroy)
# Purpose: Stop and clean up the application
# Usage: ./scripts/cleanup.sh [--full]
# ============================================================================

EC2_HOST="ec2-15-252-96-217.ap-south-1.compute.amazonaws.com"
SSH_KEY="$HOME/.ssh/zakkey.pem"
EC2_USER="ubuntu"

if [ "$1" = "--full" ]; then
    echo "FULL CLEANUP - This will remove the application from EC2"
    read -p "Are you sure? (y/N): " confirm
    if [ "$confirm" != "y" ]; then
        echo "Aborted"
        exit 0
    fi

    echo "Stopping and disabling service..."
    ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "sudo systemctl stop hybrid-commerce && sudo systemctl disable hybrid-commerce"

    echo "Removing application files..."
    ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "sudo rm -rf /opt/hybrid-commerce"

    echo "Removing systemd service..."
    ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "sudo rm /etc/systemd/system/hybrid-commerce.service && sudo systemctl daemon-reload"

    echo "Cleanup complete"
else
    echo "Stopping application..."
    ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "sudo systemctl stop hybrid-commerce"
    echo "Application stopped"
fi
