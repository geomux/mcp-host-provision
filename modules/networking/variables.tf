# modules/networking/variables.tf
# Variables configuration for networking module.

variable "aws_region" {
  description = "The AWS region where the resources will be created."
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "The CIDR block for the subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_ssh_cidr" {
  description = "The CIDR block allowed to access the VPC via SSH."
  type        = string
  default     = "0.0.0.0/0"
}
