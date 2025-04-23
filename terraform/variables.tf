variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The region to deploy to"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone to deploy to"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
  default     = "kubernetes-the-hard-way"
}

variable "subnet_cidr" {
  description = "The CIDR for the subnet"
  type        = string
  default     = "10.240.0.0/24"
}

variable "worker_count" {
  description = "Number of Kubernetes worker nodes to create"
  type        = number
  default     = 2
}

variable "worker_pod_cidr_prefix" {
  description = "CIDR prefix for worker pod networks (will be appended with node number)"
  type        = string
  default     = "10.200"
}

variable "ssh_username" {
  description = "SSH username"
  type        = string
  default     = "kubernetes"
}

variable "ssh_pub_key_file" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
