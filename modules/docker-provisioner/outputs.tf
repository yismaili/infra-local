output "installation_ids" {
  description = "Resource IDs of Docker installations"
  value       = null_resource.docker_installation[*].id
}

output "vm_hosts" {
  description = "Hosts where Docker was installed"
  value       = [for config in var.vm_connection_configs : config.host]
}

output "installation_count" {
  description = "Number of Docker installations completed"
  value       = length(var.vm_connection_configs)
}