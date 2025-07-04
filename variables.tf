variable "vm_names" {
  description = "List of VM names to create"
  type        = list(string)
  default     = ["kind-host"]
}

variable "vm_ips" {
  description = "List of IP addresses for the VMs"
  type        = list(string)
  default     = ["0.0.0.0", "0.0.0.0", "0.0.0.0"]
}

variable "vm_base_path" {
  description = "Base path where VM directories are created"
  type        = string
  default     = null
}

variable "setup_script_path" {
  description = "Path to the setup script"
  type        = string
  default     = null
}

variable "destroy_script_path" {
  description = "Path to the destroy script"
  type        = string
  default     = null
}

variable "ssh_user" {
  description = "SSH user for connecting to VMs"
  type        = string
  default     = null
}

variable "ssh_timeout" {
  description = "SSH connection timeout in seconds"  
  type        = number
  default     = 0
}

# vms config
variable "vm_config" {
  description = "VM configuration settings"
  type = object({
    memory = optional(string, "2048")
    cpus   = optional(number, 2)
    box    = optional(string, "debian/bullseye64")
  })
  default = {}
}

# docker config
variable "os_distribution" {
  description = "Linux distribution for Docker installation"
  type        = string
  default     = null

  validation {
    condition     = contains(["debian", "ubuntu"], var.os_distribution)
    error_message = "OS distribution must be either 'debian' or 'ubuntu'."
  }
}

variable "test_docker" {
  description = "Whether to run Docker hello-world test after installation"
  type        = bool
  default     = true
}

variable "install_docker_tools" {
  description = "Whether to install additional Docker tools"
  type        = bool
  default     = false
}

variable "docker_version" {
  description = "Docker version identifier for triggering updates"
  type        = string
  default     = "latest"
}

variable "docker_config" {
  description = "Docker-specific configuration"
  type = object({
    enable_experimental = optional(bool, false)
    log_driver          = optional(string, "json-file")
    log_max_size        = optional(string, "10m")
  })
  default = {}
}

# KIND config
variable "kind_config" {
  description = "KIND cluster configuration"
  type = object({
    version           = optional(string, "v0.20.0")
    cluster_name      = optional(string, "kind-cluster")
    kubernetes_version = optional(string, "v1.27.3")
    worker_node_count = optional(number, 1)
    api_server_port   = optional(number, 6443)
    install_k8s_tools = optional(bool, true)
    additional_clusters = optional(list(object({
      name = string
      vm_index = number
    })), [])
    cluster_config = optional(object({
      networking = optional(object({
        podSubnet     = optional(string, "10.244.0.0/16")
        serviceSubnet = optional(string, "10.96.0.0/12")
      }), {})
      feature_gates = optional(map(bool), {})
      runtime_config = optional(map(string), {})
    }), {})
  })
  default = {}
}