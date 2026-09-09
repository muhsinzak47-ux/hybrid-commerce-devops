# ============================================================================
# ALB MODULE
# Creates Application Load Balancer, target group, listener
# ============================================================================

# Inputs:
#   public_subnet_ids - List of public subnet IDs
#   vpc_id - VPC ID
#   ec2_instance_id - EC2 instance ID
#   app_port - Application port (default: 8000)
#   environment - Environment name

# Outputs:
#   alb_dns_name - ALB DNS name
#   alb_url - Full ALB URL (http://...)
#   target_group_arn - Target group ARN
