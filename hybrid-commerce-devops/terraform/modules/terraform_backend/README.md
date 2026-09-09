# Terraform State Locking Module
# Use this module to enable S3+DynamoDB remote state

# Example usage in main.tf:
#
# module "terraform_backend" {
#   source = "./modules/terraform_backend"
#   
#   bucket_name = "hybrid-commerce-terraform-state"
#   region      = var.aws_region
#   dynamodb_table = "terraform-state-locks"
# }
