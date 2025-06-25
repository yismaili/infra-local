# vms config
vm_names = ["master", "server-w1"]
vm_ips   = ["192.168.56.110", "192.168.56.111"]

vm_config = {
  memory = "2048"
  cpus   = 2
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

# k3s config
k3s_config = {
  version     = "latest"
  server_args = ["--write-kubeconfig-mode", "644"]
  agent_args  = []
}

# paths
vm_base_path        = "./vms"
setup_script_path   = "./scripts/setup.sh"
destroy_script_path = "./scripts/destroy.sh"

# ssh config
ssh_user    = "vagrant"
ssh_timeout = 300