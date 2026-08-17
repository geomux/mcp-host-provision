# main.tf
# Root Terraform main config file for this IaC repo. 
# Uses root variables.tf to format this script.


terraform {

  backend "s3" {
    bucket       = "BUCKET_NAME_HERE"
    key          = "tf-state-backend/terraform.state"
    region       = "us-east-1"
    use_lockfile = true
  }

  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.58.0"
    }
  }
}


### -----------------------------------
### --- CLOUD CONNECTION & IDENTITY ---
### -----------------------------------


provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}


### ------------------------
### --- MAIN CLOUD INFRA ---
### ------------------------


module "networking" {
  source     = "./modules/networking"
  aws_region = var.aws_region
}

module "compute" {
  source             = "./modules/compute"
  subnet_id          = module.networking.subnet_id
  security_group_ids = [module.networking.security_group_id]
}
