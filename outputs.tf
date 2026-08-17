# outputs.tf
# Root Terraform outputs config file for this IaC repo. 
# Defines provisioned resource values shown after Plan/Apply is run.

output "mcp_server_public_ip" {
  description = "The public IPv4 address auto-assigned to the instance at launch."
  value       = module.compute.mcp_server_public_ip
}

output "mcp_server_host" {
  description = "The EC2 instance created to hold the remote MCP server."
  value       = module.compute.mcp_server_host
}

output "mcp_server_storage" {
  description = "The EBS volume created to hold the remote MCP server storage."
  value       = module.compute.mcp_server_storage
}
