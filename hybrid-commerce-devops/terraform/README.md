# ============================================================================
# TERRAFORM USAGE
# ============================================================================

# Prerequisites:
# 1. Install Terraform: https://developer.hashicorp.com/terraform/downloads
# 2. Configure AWS credentials: aws configure
# 3. Create SSH key pair: ssh-keygen -t ed25519 -f ~/.ssh/zakkey

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Apply infrastructure
terraform apply

# View outputs
terraform output

# SSH to server
# ssh -i ~/.ssh/zakkey.pem ubuntu@$(terraform output -raw app_server_public_ip)

# Destroy all resources (IMPORTANT: run after demo!)
# terraform destroy

# Cost notes:
# - EC2 t2.micro, EBS 8GB, S3: Free Tier eligible
# - ALB: ~$0.0225/hr (~$4 for 5 days, NOT Free Tier)
# Total estimated: $0-5 for 5-day demo
