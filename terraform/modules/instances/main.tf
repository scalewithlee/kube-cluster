# Get a local SSH key so that we can inject it in the
# instance metadata, which will provide SSH access
data "local_file" "ssh_public_key" {
  filename = pathexpand(var.ssh_pub_key_file)
}

resource "google_compute_instance" "vm_instances" {
  for_each     = var.instances_config
  name         = each.key
  machine_type = each.value.machine_type
  zone         = var.zone
  tags         = each.value.tags

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = each.value.boot_disk_size
    }
  }

  network_interface {
    subnetwork = var.subnet_id
    access_config {
      // Leaving this empty tells GCP to assign an ephemeral public IP address to the VM
    }
  }

  metadata = merge(
    {
      ssh-keys = "${var.ssh_username}:${data.local_file.ssh_public_key.content}"
    },
    # Only add pod-cidr for worker nodes
    contains(keys(var.pod_cidr_blocks), each.key) ?
    {
      pod-cidr = var.pod_cidr_blocks[each.key]
    } : {}
  )

  # Enable IP forwarding for Kubernetes networking
  can_ip_forward = true

  allow_stopping_for_update = true
}
