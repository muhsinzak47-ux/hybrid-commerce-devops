# ============================================================================
# TERRAFORM VARIABLES
# ============================================================================

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name (used for naming and tagging)"
  type        = string
  default     = "demo"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.10.0/24"
}

variable "instance_type" {
  description = "EC2 instance type (t2.micro is Free Tier eligible)"
  type        = string
  default     = "t2.micro"
}

variable "ssh_key_name" {
  description = "Name of SSH key pair for EC2 instance"
  type        = string
  default     = "zakkey"
}

variable "app_port" {
  description = "Application port (backend API)"
  type        = number
  default     = 8000
}

variable "db_volume_size_gb" {
  description = "Size of EBS volume for database in GB"
  type        = number
  default     = 8
}

variable "enable_alb" {
  description = "Whether to create Application Load Balancer"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateway for private subnet internet access"
  type        = bool
  default     = false
}

variable "ssh_cidr" {
  description = "CIDR block allowed for SSH access (0.0.0.0/0 for open, restrict in production)"
  type        = string
  default     = "0.0.0.0/0"
}
