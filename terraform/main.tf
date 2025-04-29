provider "google" {
  project = var.project_id
  region  = var.region
}

module "network" {
  source       = "./modules/network"
  project_id   = var.project_id
  region       = var.region
  network_name = var.network_name
  subnet_cidr  = var.subnet_cidr
}

module "firewall" {
  source       = "./modules/firewall"
  network_name = module.network.network_name
  subnet_cidr  = module.network.subnet_cidr
}

// Generate Pod CIDR map dynamically based on worker count
locals {

  # Create Pod CIDR Map:
  # { "node-0" = "10.200.0.0/24", "node-1" = "10.200.1.0/24" ... }
  pod_cidr_blocks = {
    for i in range(var.worker_count) : "node-${i}" => "${var.worker_pod_cidr_prefix}.${i}.0/24"
  }

  # Base instance configs
  base_instances = {
    "jumpbox" = {
      machine_type   = "e2-micro" # 1 CPU, 1 GB Mem
      boot_disk_size = 10
      tags           = ["jumpbox"]
    },
    "server" = {
      machine_type   = "e2-small" # 1 CPU, 2 GB Mem
      boot_disk_size = 20
      tags           = ["controller"]
    }
  }

  # Worker node configs
  worker_instances = {
    for i in range(var.worker_count) :
    "node-${i}" => {
      machine_type   = "e2-small"
      boot_disk_size = 20
      tags           = ["worker"]
    }
  }

  instances_config = merge(local.base_instances, local.worker_instances)
}

module "instances" {
  source           = "./modules/instances"
  project_id       = var.project_id
  zone             = var.zone
  subnet_id        = module.network.subnet_id
  ssh_username     = var.ssh_username
  ssh_pub_key_file = var.ssh_pub_key_file
  pod_cidr_blocks  = local.pod_cidr_blocks
  instances_config = local.instances_config
}

// Adding this to handle an issue with routing in GCP
resource "google_compute_route" "pod_network_routes" {
  for_each = local.pod_cidr_blocks

  name                   = "kubernetes-route-${replace(replace(each.value, ".", "-"), "/", "-")}"
  network                = module.network.network_name
  dest_range             = each.value
  next_hop_instance      = module.instances.instance_map[each.key].id
  next_hop_instance_zone = var.zone
  priority               = 1000
}
