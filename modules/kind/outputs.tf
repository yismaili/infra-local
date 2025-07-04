output "master_node_ip" {
  description = "IP address of the KIND master node"
  value       = var.vm_connection_configs[0].host
}

output "worker_node_ips" {
  description = "IP address of the single VM hosting KIND containers"
  value       = [var.vm_connection_configs[0].host]
}

output "cluster_endpoint" {
  description = "KIND cluster endpoint URL"
  value       = "https://${var.vm_connection_configs[0].host}:${var.api_server_port}"
}

output "cluster_name" {
  description = "Name of the KIND cluster"
  value       = var.cluster_name
}

output "kubeconfig_path" {
  description = "Path to downloaded kubeconfig file"
  value       = "${path.root}/kubeconfig/kubeconfig-${var.cluster_name}.yaml"
}

output "kubeconfig_command" {
  description = "Command to download kubeconfig from master node"
  value       = "scp -i ${var.vm_connection_configs[0].private_key} ${var.vm_connection_configs[0].user}@${var.vm_connection_configs[0].host}:/tmp/kubeconfig-${var.cluster_name}.yaml ./kubeconfig-${var.cluster_name}.yaml"
}

output "kubectl_commands" {
  description = "Useful kubectl commands for KIND cluster"
  value = {
    get_nodes    = "kubectl get nodes --kubeconfig=${path.root}/kubeconfig/kubeconfig-${var.cluster_name}.yaml"
    get_pods     = "kubectl get pods -A --kubeconfig=${path.root}/kubeconfig/kubeconfig-${var.cluster_name}.yaml"
    cluster_info = "kubectl cluster-info --kubeconfig=${path.root}/kubeconfig/kubeconfig-${var.cluster_name}.yaml"
  }
}

output "kind_commands" {
  description = "Useful KIND commands to run on master node"
  value = {
    get_clusters    = "kind get clusters"
    cluster_info    = "kind get kubeconfig --name ${var.cluster_name}"
    delete_cluster  = "kind delete cluster --name ${var.cluster_name}"
    load_image      = "kind load docker-image <image-name> --name ${var.cluster_name}"
  }
}

output "docker_commands" {
  description = "Docker commands to inspect KIND containers"
  value = {
    list_containers = "docker ps --filter 'label=io.x-k8s.kind.cluster=${var.cluster_name}'"
    exec_control_plane = "docker exec -it ${var.cluster_name}-control-plane bash"
  }
}

output "installation_status" {
  description = "Installation completion status"
  value = {
    kind_installed    = null_resource.install_kind.id != null ? "completed" : "pending"
    cluster_created   = null_resource.create_kind_cluster.id != null ? "completed" : "pending"
    kubeconfig_ready  = null_resource.download_kubeconfig.id != null ? "completed" : "pending"
  }
}

output "access_info" {
  description = "Information for accessing the KIND cluster"
  value = {
    ssh_to_master = "ssh -i ${var.vm_connection_configs[0].private_key} ${var.vm_connection_configs[0].user}@${var.vm_connection_configs[0].host}"
    kubeconfig_export = "export KUBECONFIG=${path.root}/kubeconfig/kubeconfig-${var.cluster_name}.yaml"
    kubectl_context = "kubectl config use-context kind-${var.cluster_name}"
  }
}