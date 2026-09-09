# ============================================================================
# TERRAFORM PROVIDERS
# ============================================================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state configuration (uncomment and configure for team use)
  # backend "s3" {
  #   bucket = "hybrid-commerce-terraform-state"
  #   key    = "terraform.tfstate"
  #   region = "ap-south-1"
  #   dynamodb_table = "terraform-state-lock"
  # }
}
