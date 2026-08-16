# modules/network/outputs.tf
# Outputs definitions for networking module.

output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "The ID of the created subnet."
  value       = aws_subnet.main.id
}

output "security_group_id" {
  description = "The ID of the created security group."
  value       = aws_security_group.allow_ssh_https.id
}
