# ============================================================================
# TERRAFORM MAIN - Hybrid Commerce Platform AWS Infrastructure
# ============================================================================
# Purpose: Provision AWS infrastructure for the Hybrid Commerce application
# Region: ap-south-1 (Mumbai) - Free Tier eligible
# Cost: ~$3-5 for 5-day demo (ALB is the main cost)
# IMPORTANT: Run terraform destroy after demo to avoid charges
# ============================================================================

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
  default_tags {
    tags = {
      Project     = "Hybrid-Commerce-Capstone"
      Environment = "demo"
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "hybrid-commerce-vpc" }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "hybrid-commerce-igw" }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.zones[0].name
  map_public_ip_on_launch = true
  tags = { Name = "hybrid-commerce-public-subnet" }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = data.aws_availability_zones.available.zones[0].name
  tags = { Name = "hybrid-commerce-private-subnet" }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "hybrid-commerce-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "alb_sg" {
  name        = "hybrid-commerce-alb-sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "hybrid-commerce-alb-sg" }
}

resource "aws_security_group" "ec2_sg" {
  name        = "hybrid-commerce-ec2-sg"
  description = "EC2 security group"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "App port from ALB"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.public.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "hybrid-commerce-ec2-sg" }
}

# IAM
resource "aws_iam_role" "ec2_role" {
  name = "hybrid-commerce-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = { Name = "hybrid-commerce-ec2-role" }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "hybrid-commerce-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_s3" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# S3 Bucket
resource "aws_s3_bucket" "product_images" {
  bucket = "hybrid-commerce-images-${data.aws_caller_identity.current.account_id}"
  tags = { Name = "hybrid-commerce-product-images" }
}

resource "aws_s3_bucket_public_access_block" "product_images" {
  bucket = aws_s3_bucket.product_images.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# EC2 Instance
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-noble-24.04-arm64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = "zakkey"

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3 python3-pip python3-venv docker.io
              systemctl start docker
              systemctl enable docker
              EOF

  tags = { Name = "hybrid-commerce-app-server" }
}

# ALB
resource "aws_lb" "main" {
  name               = "hybrid-commerce-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public.id]
  tags = { Name = "hybrid-commerce-alb" }
}

resource "aws_lb_target_group" "app" {
  name     = "hybrid-commerce-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path            = "/health"
    interval        = 30
    timeout         = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher         = "200"
  }
  tags = { Name = "hybrid-commerce-tg" }
}

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app_server.id
  port             = 8000
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# EBS Volume
resource "aws_ebs_volume" "db_data" {
  availability_zone = data.aws_availability_zones.available.zones[0].name
  size              = 8
  type              = "gp3"
  encrypted         = true
  tags = { Name = "hybrid-commerce-db-data" }
}

resource "aws_volume_attachment" "db_data_attach" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.db_data.id
  instance_id = aws_instance.app_server.id
}

# Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "app_server_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "app_server_instance_id" {
  value = aws_instance.app_server.id
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_url" {
  value = "http://${aws_lb.main.dns_name}"
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/zakkey.pem ubuntu@${aws_instance.app_server.public_ip}"
}

output "s3_bucket_name" {
  value = aws_s3_bucket.product_images.id
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}
