# ============================================================================
# TERRAFORM OUTPUTS
# ============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

output "app_server_public_ip" {
  description = "Public IP address of the application server"
  value       = aws_instance.app_server.public_ip
}

output "app_server_private_ip" {
  description = "Private IP address of the application server"
  value       = aws_instance.app_server.private_ip
}

output "app_server_instance_id" {
  description = "Instance ID of the application server"
  value       = aws_instance.app_server.id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_url" {
  description = "URL of the Application Load Balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ssh_command" {
  description = "SSH command to connect to the application server"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem ubuntu@${aws_instance.app_server.public_ip}"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for product images"
  value       = aws_s3_bucket.product_images.id
}

output "ec2_security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2_sg.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role for EC2"
  value       = aws_iam_role.ec2_role.arn
}

output "destroy_instructions" {
  description = "Commands to destroy all resources and avoid charges"
  value       = "cd terraform && terraform destroy --auto-approve"
}
