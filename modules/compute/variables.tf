# modules/compute/variables.tf
# Variables configuration for compute module.

variable "project_name" {
  description = "The name of the project for resource naming."
  type        = string
}

variable "key_name" {
  description = "The name of the SSH key pair to use for accessing the instance."
  type        = string
}

variable "instance_type" {
  description = "The type of instance to create."
  type        = string
}

variable "ebs_volume_size" {
  description = "The size of the EBS volume in GB."
  type        = number
}

variable "subnet_id" {
  description = "The ID of the subnet where the instance will be launched."
  type        = string
}

variable "security_group_ids" {
  description = "A list of security group IDs to associate with the instance."
  type        = list(string)
}
