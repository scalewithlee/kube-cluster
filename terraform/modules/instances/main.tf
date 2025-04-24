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

  metadata = {
    ssh-keys = "${var.ssh_username}:${data.local_file.ssh_public_key.content}"
    pod-cidr = contains(keys(var.pod_cidr_blocks), each.key) ? var.pod_cidr_blocks[each.key] : null
  }

  metadata_startup_script = <<EOF
  #!/bin/bash
  # Enable root login via SSH
  sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  sed -i 's/^PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config

  # Create .ssh directory for root
  mkdir -p /root/.ssh

  # Copy authorized keys from the default user to root
  if [ -f "/home/${var.ssh_username}/.ssh/authorized_keys" ]; then
    cp /home/${var.ssh_username}/.ssh/authorized_keys /root/.ssh/
  fi

  # Create SSH key pair for root if needed
  if [ ! -f /root/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
  fi

  # Set proper permissions
  chmod 700 /root/.ssh
  chmod 600 /root/.ssh/authorized_keys || true
  chmod 600 /root/.ssh/id_rsa
  chown -R root:root /root/.ssh

  # Restart SSH service
  systemctl restart sshd
  EOF

  # Enable IP forwarding for Kubernetes networking
  can_ip_forward = true

  allow_stopping_for_update = true
}

# Add this as a local file resource to store a provisioning script
resource "local_file" "ssh_key_distribution" {
  content  = <<-EOT
    #!/bin/bash
    set -e

    echo "Starting SSH key distribution..."

    # Wait for jumpbox to be fully provisioned
    echo "Waiting for jumpbox SSH to be ready..."
    for i in {1..30}; do
      if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@${google_compute_instance.vm_instances["jumpbox"].network_interface[0].access_config[0].nat_ip} "echo 'SSH is ready'"; then
        break
      fi
      echo "Waiting for jumpbox SSH... attempt $i of 30"
      sleep 10
    done

    # Get the jumpbox's root public key
    JUMPBOX_KEY=$(ssh -o StrictHostKeyChecking=no root@${google_compute_instance.vm_instances["jumpbox"].network_interface[0].access_config[0].nat_ip} "cat /root/.ssh/id_rsa.pub")

    # Define nodes to copy keys to (all except jumpbox)
    echo "Got jumpbox key: $JUMPBOX_KEY"

    # Loop through all instances except jumpbox
    ${join("\n", [for k, v in var.instances_config : "    # Copying key to ${k}\n    if [ \"${k}\" != \"jumpbox\" ]; then\n      NODE_IP=${google_compute_instance.vm_instances[k].network_interface[0].access_config[0].nat_ip}\n      echo \"Copying key to ${k} at $NODE_IP...\"\n      \n      # Wait for node SSH to be ready\n      for i in {1..30}; do\n        if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$NODE_IP \"echo 'SSH is ready'\"; then\n          break\n        fi\n        echo \"Waiting for ${k} SSH... attempt $i of 30\"\n        sleep 10\n      done\n      \n      # Add the jumpbox key to this node\n      ssh -o StrictHostKeyChecking=no root@$NODE_IP \"echo \\\"$JUMPBOX_KEY\\\" >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys\"\n      \n      echo \"Key distributed to ${k} successfully\"\n    fi"])}

    echo "SSH key distribution completed!"

    # Test SSH connections from jumpbox to all nodes
    echo "Testing SSH connections from jumpbox to all nodes..."
    ssh -o StrictHostKeyChecking=no root@${google_compute_instance.vm_instances["jumpbox"].network_interface[0].access_config[0].nat_ip} "for NODE in ${join(" ", [for k, v in var.instances_config : k if k != "jumpbox"])}; do echo \"Testing connection to \$NODE\"; ssh -o StrictHostKeyChecking=no \$NODE hostname || echo \"Failed to connect to \$NODE\"; done"
  EOT
  filename = "${path.module}/distribute_keys.sh"

  # Make the script executable
  provisioner "local-exec" {
    command = "chmod +x ${path.module}/distribute_keys.sh"
  }

  depends_on = [google_compute_instance.vm_instances]
}

# Add this null_resource to run the script after all instances are created
resource "null_resource" "distribute_ssh_keys" {
  # Only run this after all instances are created and the script is generated
  depends_on = [
    google_compute_instance.vm_instances,
    local_file.ssh_key_distribution
  ]

  # Run the distribution script
  provisioner "local-exec" {
    command = "${path.module}/distribute_keys.sh"
  }
}
