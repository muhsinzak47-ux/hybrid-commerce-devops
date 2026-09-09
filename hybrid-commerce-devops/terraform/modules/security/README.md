# ============================================================================
# SECURITY MODULE
# Creates security groups for ALB and EC2
# ============================================================================

# Inputs:
#   vpc_id - VPC ID
#   public_subnet_cidr - Public subnet CIDR (for EC2 SG ingress)
#   app_port - Application port (default 8000)

# Outputs:
#   alb_sg_id - ALB security group ID
#   ec2_sg_id - EC2 security group ID
