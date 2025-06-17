variable "vm_names" {
  description = "List of VM names to create"
  type        = list(string)
  default     = ["null", "null", "null"]
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

# k3s config
variable "k3s_config" {
  description = "K3s cluster configuration"
  type = object({
    version     = optional(string, "latest")
    server_args = optional(list(string), [])
    agent_args  = optional(list(string), [])
  })
  default = {}
}