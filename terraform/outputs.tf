output "instance_external_ips" {
  value = module.instances.instance_external_ips
}

output "instance_internal_ips" {
  value = module.instances.instance_internal_ips
}

output "machines_txt_content" {
  description = "Content for machines.txt file to be used in the tutorial"
  value = join("\n", concat(
    ["${module.instances.instance_internal_ips["server"]} server.kubernetes.local server"],
    [
      for i in range(var.worker_count) :
      "${module.instances.instance_internal_ips["node-${i}"]} node-${i}.kubernetes.local node-${i} ${local.pod_cidr_blocks["node-${i}"]}"
    ]
  ))
}

output "ssh_commands" {
  description = "SSH commands to connect to instances"
  value = {
    for name, ip in module.instances.instance_external_ips :
    name => "ssh ${var.ssh_username}@${ip}"
  }
}

output "pod_cidr_blocks" {
  description = "CIDR blocks assigned to worker nodes"
  value       = local.pod_cidr_blocks
}

output "worker_count" {
  description = "Number of worker nodes created"
  value       = var.worker_count
}

output "create_machines_txt_command" {
  description = "Command to create the machines.txt file on the jumpbox"
  value = "echo '${join("\n", concat(
    ["${module.instances.instance_internal_ips["server"]} server.kubernetes.local server"],
    [
      for i in range(var.worker_count) :
      "${module.instances.instance_internal_ips["node-${i}"]} node-${i}.kubernetes.local node-${i} ${local.pod_cidr_blocks["node-${i}"]}"
    ]
  ))}' > machines.txt"
}
