terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
  }
}

# create VMs using the vagrant-vm module
module "vagrant_vms" {
  source = "./modules/vagrant-vm"

  vm_names            = var.vm_names
  vm_ips              = var.vm_ips
  vm_base_path        = var.vm_base_path
  setup_script_path   = var.setup_script_path
  destroy_script_path = var.destroy_script_path
  ssh_user            = var.ssh_user
  ssh_timeout         = var.ssh_timeout
  vm_config_hash = md5(jsonencode({
    names  = var.vm_names
    ips    = var.vm_ips
    config = var.vm_config
  }))
}

# module to install docker 
module "docker_provisioner" {
  source = "./modules/docker-provisioner"

  vm_connection_configs  = module.vagrant_vms.vm_connection_configs
  vm_dependencies        = module.vagrant_vms.vm_key_wait_ids
  os_distribution        = var.os_distribution
  test_docker            = var.test_docker
  install_docker_tools   = var.install_docker_tools
  docker_version_trigger = var.docker_version
  config_hash            = md5(jsonencode(var.docker_config))
}

# module to install k3s
module "k3s" {
  source = "./modules/k3s"

  vm_connection_configs = module.vagrant_vms.vm_connection_configs
  vm_dependencies       = module.docker_provisioner.installation_ids
  config_hash          = md5(jsonencode({
    vm_names = var.vm_names
    vm_ips   = var.vm_ips
    k3s_config = var.k3s_config
  }))
  
  k3s_version     = var.k3s_config.version
  k3s_server_args = var.k3s_config.server_args
  k3s_agent_args  = var.k3s_config.agent_args
}