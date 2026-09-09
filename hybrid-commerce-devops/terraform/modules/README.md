# ============================================================================
# TERRAFORM MODULES
# ============================================================================

# Module structure:
# modules/
#   vpc/           - VPC, subnets, internet gateway, route tables
#   security/      - Security groups (ALB, EC2)
#   compute/       - IAM roles, EC2 instance, user data
#   database/      - EBS volume for PostgreSQL data
#   storage/       - S3 bucket for product images
#   alb/           - Application Load Balancer, target group, listener
#   kubernetes/    - EC2 instance for self-managed Kubernetes (optional)

# Usage:
# Each module is called from root main.tf with source = "./modules/<name>"
# Module inputs are passed as arguments, outputs are referenced as module.<name>.<output>

# Example:
# module "vpc" {
#   source = "./modules/vpc"
#   vpc_cidr = var.vpc_cidr
#   public_subnet_cidr = var.public_subnet_cidr
#   private_subnet_cidr = var.private_subnet_cidr
#   environment = var.environment
# }
