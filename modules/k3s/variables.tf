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
  description = "Dependencies to wait for before provisioning k3s"
  type        = list(string)
  default     = []
}

variable "config_hash" {
  description = "Hash of configuration to trigger updates"
  type        = string
  default     = ""
}

variable "k3s_version" {
  description = "K3s version to install"
  type        = string
  default     = "latest"
}

variable "k3s_server_args" {
  description = "Additional arguments for k3s server"
  type        = list(string)
  default     = []
}

variable "k3s_agent_args" {
  description = "Additional arguments for k3s agents"
  type        = list(string)
  default     = []
}