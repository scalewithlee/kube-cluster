// Create firewall rules to allow internal communication
// All traffic to instances, even from other instances, is blocked by the firewall unless firewall rules are created to allow it.
resource "google_compute_firewall" "kubernetes_internal" {
  name    = "kubernetes-internal"
  network = var.network_name
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  source_ranges = [var.subnet_cidr]
}

// Create firewall rule to allow SSH access from anywhere
resource "google_compute_firewall" "kubernetes_external" {
  name    = "kubernetes-external"
  network = var.network_name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

// Create a firewall rule to allow all Kubernetes API traffic
resource "google_compute_firewall" "kubernetes_api" {
  name    = "kubernetes-api"
  network = var.network_name
  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }
  source_ranges = ["0.0.0.0/0"]
}
