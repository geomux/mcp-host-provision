# modules/compute/outputs.tf
# Outputs definitions for compute module.

output "mcp_server_host" {
  description = "The EC2 instance created to hold the remote MCP server."
  value       = aws_instance.mcp_ec2_instance.id
}

output "mcp_server_storage" {
  description = "The EBS volume created to hold the remote MCP server storage."
  value       = aws_ebs_volume.mcp_ebs_volume.id
}

output "mcp_server_public_ip" {
  description = "The public IPv4 address auto-assigned to the instance at launch."
  value       = aws_instance.mcp_ec2_instance.public_ip
}

