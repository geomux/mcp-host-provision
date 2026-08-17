# variables.tf
# Root Terraform variables config file for this IaC repo. Formats root main.tf script.

variable "aws_region" {
  description = "The AWS region where the resources will be created."
  type        = string
  default     = "us-east-1"
}
