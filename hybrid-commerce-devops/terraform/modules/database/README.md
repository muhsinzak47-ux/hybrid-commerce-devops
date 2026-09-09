# ============================================================================
# DATABASE MODULE
# Creates EBS volume for PostgreSQL data, attaches to EC2
# ============================================================================

# Inputs:
#   instance_id - EC2 instance ID
#   availability_zone - AZ for the volume
#   size_gb - Volume size in GB (default: 8)
#   environment - Environment name

# Outputs:
#   volume_id - EBS volume ID
#   attachment_id - Volume attachment ID
