vm_names = ["kind-host"]
vm_ips   = ["192.168.56.110"]

vm_config = {
  memory = "6144"  # More memory for single VM running multiple containers
  cpus   = 4       # More CPUs for better performance
  box    = "debian/bullseye64"
}

# docker config
os_distribution      = "debian"
test_docker          = true
install_docker_tools = false

docker_config = {
  enable_experimental = false
  log_driver          = "json-file"
  log_max_size        = "10m"
}

# KIND config - Single VM with multi-node cluster
kind_config = {
  version           = "v0.20.0"
  cluster_name      = "single-vm-cluster"
  kubernetes_version = "v1.27.3"
  worker_node_count = 3  # 1 control-plane + 3 worker nodes (all as containers)
  api_server_port   = 6443
  install_k8s_tools = true
  additional_clusters = []  # No additional clusters needed
  cluster_config = {
    networking = {
      podSubnet     = "10.244.0.0/16"
      serviceSubnet = "10.96.0.0/12"
    }
    feature_gates = {}
    runtime_config = {}
  }
}

# paths
vm_base_path        = "./vms"
setup_script_path   = "./scripts/setup.sh"
destroy_script_path = "./scripts/destroy.sh"

# ssh config
ssh_user    = "vagrant"
ssh_timeout = 300