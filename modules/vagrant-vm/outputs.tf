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

output "vm_connection_configs" {
  description = "Connection configurations for all VMs"
  value       = local.connection_configs
  depends_on  = [null_resource.wait_for_keys]
}

output "vm_ids" {
  description = "List of VM resource IDs"
  value       = null_resource.vagrant_vm[*].id
}

output "vm_key_wait_ids" {
  description = "List of key wait resource IDs for proper dependency ordering"
  value       = null_resource.wait_for_keys[*].id
}