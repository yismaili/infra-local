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

output "k3s_cluster" {
  description = "K3s cluster information"
  value = {
    master_ip        = module.k3s.master_node_ip
    worker_ips       = module.k3s.worker_node_ips
    cluster_endpoint = module.k3s.cluster_endpoint
    kubeconfig_cmd   = module.k3s.kubeconfig_command
    kubectl_commands = module.k3s.kubectl_commands
    status          = module.k3s.installation_status
  }
}

output "ssh_commands" {
  description = "SSH commands to connect to VMs"
  value = [
    for i, name in module.vagrant_vms.vm_names :
    "ssh -i ${var.vm_base_path}/${name}/.vagrant/machines/${name}/virtualbox/private_key vagrant@${module.vagrant_vms.vm_ips[i]}"
  ]
}

output "cluster_access_info" {
  description = "Commands to access the K3s cluster"
  value = {
    ssh_to_master = "ssh -i ${var.vm_base_path}/${var.vm_names[0]}/.vagrant/machines/${var.vm_names[0]}/virtualbox/private_key vagrant@${var.vm_ips[0]}"
    get_kubeconfig = module.k3s.kubeconfig_command
    kubectl_nodes = "sudo k3s kubectl get nodes -o wide"
    kubectl_pods = "sudo k3s kubectl get pods -A"
  }
}