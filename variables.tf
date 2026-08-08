# variables.tf
# Root Terraform variables config file for this IaC repo. Formats root main.tf script.

variable "aws_region" {
  description = "AWS region to deploy into (e.g. us-east-1)"
  type        = string
}
