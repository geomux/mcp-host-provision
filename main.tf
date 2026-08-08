# main.tf
# Root Terraform main config file for this IaC repo. Uses root variables.tf to format this script.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
