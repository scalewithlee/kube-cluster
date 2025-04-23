output "instance_external_ips" {
  value = {
    for name, instance in google_compute_instance.vm_instances :
    name => instance.network_interface[0].access_config[0].nat_ip
  }
}

output "instance_internal_ips" {
  value = {
    for name, instance in google_compute_instance.vm_instances :
    name => instance.network_interface[0].network_ip
  }
}

output "instance_map" {
  description = "Map of all created instances"
  value       = google_compute_instance.vm_instances
}
