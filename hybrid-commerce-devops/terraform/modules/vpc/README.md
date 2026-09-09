# ============================================================================
# VPC MODULE
# Creates VPC, Internet Gateway, Public/Private Subnets, Route Tables
# ============================================================================

# Inputs:
#   vpc_cidr - CIDR block for VPC (e.g., "10.0.0.0/16")
#   public_subnet_cidr - CIDR for public subnet (e.g., "10.0.1.0/24")
#   private_subnet_cidr - CIDR for private subnet (e.g., "10.0.10.0/24")
#   environment - Environment name for tagging (e.g., "dev", "prod")

# Outputs:
#   vpc_id - VPC ID
#   public_subnet_id - Public subnet ID
#   private_subnet_id - Private subnet ID
#   igw_id - Internet gateway ID
