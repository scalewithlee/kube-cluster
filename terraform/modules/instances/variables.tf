variable "project_id" {
  description = "The ID of the GCP Project"
  type        = string
}

variable "zone" {
  description = "The zone to deploy to"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet"
  type        = string
}

variable "ssh_username" {
  description = "The SSH username"
  type        = string
}

variable "ssh_pub_key_file" {
  description = "Path to the SSH public key"
  type        = string
}

variable "pod_cidr_blocks" {
  description = "CIDR blocks for pods on each node"
  type        = map(string)
}

variable "instances_config" {
  description = "Configuration for each instances"
  type = map(object({
    machine_type   = string
    boot_disk_size = number
    tags           = list(string)
  }))
}
