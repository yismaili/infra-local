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

output "kind_cluster" {
  description = "KIND cluster information"
  value = {
    master_ip         = module.kind.master_node_ip
    cluster_name      = module.kind.cluster_name
    cluster_endpoint  = module.kind.cluster_endpoint
    kubeconfig_path   = module.kind.kubeconfig_path
    kubeconfig_cmd    = module.kind.kubeconfig_command
    kubectl_commands  = module.kind.kubectl_commands
    kind_commands     = module.kind.kind_commands
    docker_commands   = module.kind.docker_commands
    status           = module.kind.installation_status
    access_info      = module.kind.access_info
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
  description = "Commands to access the KIND cluster"
  value = {
    ssh_to_master     = "ssh -i ${var.vm_base_path}/${var.vm_names[0]}/.vagrant/machines/${var.vm_names[0]}/virtualbox/private_key vagrant@${var.vm_ips[0]}"
    export_kubeconfig = "export KUBECONFIG=${module.kind.kubeconfig_path}"
    kubectl_nodes     = "kubectl get nodes --kubeconfig=${module.kind.kubeconfig_path}"
    kubectl_pods      = "kubectl get pods -A --kubeconfig=${module.kind.kubeconfig_path}"
    kind_info         = "kind get clusters"
    docker_containers = "docker ps --filter 'label=io.x-k8s.kind.cluster=${module.kind.cluster_name}'"
  }
}