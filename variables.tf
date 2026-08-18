# variables.tf
# Root Terraform variables config file for this IaC repo. Formats root main.tf script.


### --------------------------
### --- REQUIRED VARIABLES ---
### --------------------------


variable "ssh_public_key_path" {
  description = "The path to the SSH public key file."
  type        = string
  default     = "~/.ssh/mcp-host.pub" # terraform.tfvars overrides this.
}

variable "project_name" {
  description = "The name of the project for resource naming."
  type        = string
  default     = "mcp-host" # terraform.tfvars overrides this.
}

variable "allowed_ssh_cidr" {
  description = "The CIDR block allowed to access the VPC via SSH."
  type        = string
}

### --------------------------
### --- OPTIONAL VARIABLES ---
### --------------------------


variable "aws_region" {
  description = "The AWS region where the resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The type of instance to create."
  type        = string
  default     = "t3.micro"
}

variable "ebs_volume_size" {
  description = "The size of the EBS volume in GB."
  type        = number
  default     = 8
}

