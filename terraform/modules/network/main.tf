// Create a VPC network
resource "google_compute_network" "kubernetes_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

// Create a subnet in the VPC
resource "google_compute_subnetwork" "kubernetes_subnet" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.kubernetes_network.id
}
