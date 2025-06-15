# modules/vagrant-vm/outputs.tf

output "vm_connection_configs" {
  description = "Connection configurations for the created VMs"
  value       = local.connection_configs
}

output "vm_ids" {
  description = "Resource IDs of the created VMs"
  value       = null_resource.vagrant_vm[*].id
}

output "vm_names" {
  description = "Names of the created VMs"
  value       = var.vm_names
}

output "vm_ips" {
  description = "IP addresses of the created VMs"
  value       = var.vm_ips
}

output "vm_count" {
  description = "Number of VMs created"
  value       = length(var.vm_names)
}