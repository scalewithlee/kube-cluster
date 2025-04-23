output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.kubernetes_network.name
}

output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.kubernetes_network.id
}

output "subnet_id" {
  description = "The ID of the Kubernetes subnet"
  value       = google_compute_subnetwork.kubernetes_subnet.id
}

output "subnet_cidr" {
  description = "The CIDR range of the subnet"
  value       = var.subnet_cidr
}
