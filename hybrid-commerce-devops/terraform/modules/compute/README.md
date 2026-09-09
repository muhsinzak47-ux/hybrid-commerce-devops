# ============================================================================
# COMPUTE MODULE
# Creates IAM role, instance profile, EC2 instance with user data
# ============================================================================

# Inputs:
#   vpc_id - VPC ID
#   public_subnet_id - Public subnet ID
#   ec2_sg_id - EC2 security group ID
#   ssh_key_name - SSH key pair name
#   instance_type - EC2 instance type (default: t2.micro)
#   app_port - Application port
#   environment - Environment name

# Outputs:
#   instance_id - EC2 instance ID
#   public_ip - EC2 public IP
#   private_ip - EC2 private IP
#   iam_role_arn - IAM role ARN
