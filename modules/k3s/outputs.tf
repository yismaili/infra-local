output "master_node_ip" {
  description = "IP address of the k3s master node"
  value       = var.vm_connection_configs[0].host
}

output "worker_node_ips" {
  description = "IP addresses of the k3s worker nodes"
  value       = slice(var.vm_connection_configs[*].host, 1, length(var.vm_connection_configs))
}

output "cluster_endpoint" {
  description = "K3s cluster endpoint URL"
  value       = "https://${var.vm_connection_configs[0].host}:6443"
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig from master node"
  value       = "scp -i ${replace(var.vm_connection_configs[0].private_key, "/", "\\/")} ${var.vm_connection_configs[0].user}@${var.vm_connection_configs[0].host}:/etc/rancher/k3s/k3s.yaml ./kubeconfig.yaml"
}

output "kubectl_commands" {
  description = "Useful kubectl commands to run on master node"
  value = {
    get_nodes    = "sudo k3s kubectl get nodes -o wide"
    get_pods     = "sudo k3s kubectl get pods -A"
    cluster_info = "sudo k3s kubectl cluster-info"
  }
}

output "installation_status" {
  description = "Installation completion status"
  value = {
    server_installed = null_resource.k3s_server.id != null ? "completed" : "pending"
    agents_installed = length(null_resource.k3s_agents) > 0 ? "completed" : "pending"
  }
}