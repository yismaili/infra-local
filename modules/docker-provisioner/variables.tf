variable "vm_connection_configs" {
  description = "List of connection configurations for VMs"
  type = list(object({
    type        = string
    host        = string
    user        = string
    private_key = string
    timeout     = string
  }))
}


variable "vm_dependencies" {
  description = "Dependencies to wait for before provisioning Docker"
  type        = list(string)
  default     = []
}

variable "os_distribution" {
  description = "Linux distribution (debian, ubuntu, etc.)"
  type        = string
  default     = "debian"
}

variable "test_docker" {
  description = "Whether to run Docker hello-world test"
  type        = bool
  default     = true
}

variable "install_docker_tools" {
  description = "Whether to install additional Docker tools"
  type        = bool
  default     = false
}

variable "docker_version_trigger" {
  description = "Trigger for Docker version changes"
  type        = string
  default     = "latest"
}

variable "config_hash" {
  description = "Hash of configuration to trigger recreation"
  type        = string
  default     = ""
}