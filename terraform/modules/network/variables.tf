variable "project_id" {
  description = "The ID of the GCP Project"
  type        = string
}

variable "region" {
  description = "The region to deploy to"
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_cidr" {
  description = "The CIDR for the subnet"
  type        = string
}
