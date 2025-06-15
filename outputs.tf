output "vm_names" {
  description = "Names of the created VMs"
  value       = module.vagrant_vms.vm_names
}

output "vm_ips" {
  description = "IP addresses of the created VMs"
  value       = module.vagrant_vms.vm_ips
}

output "vm_count" {
  description = "Number of VMs created"
  value       = module.vagrant_vms.vm_count
}

output "docker_installations" {
  description = "Docker installation details"
  value = {
    hosts = module.docker_provisioner.vm_hosts
    count = module.docker_provisioner.installation_count
  }
}

output "ssh_commands" {
  description = "SSH commands to connect to VMs"
  value = [
    for i, name in module.vagrant_vms.vm_names :
    "ssh -i ${var.vm_base_path}/${name}/.vagrant/machines/${name}/virtualbox/private_key vagrant@${module.vagrant_vms.vm_ips[i]}"
  ]
}