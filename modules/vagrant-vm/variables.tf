# modules/vagrant-vm/variables.tf

variable "vm_names" {
  description = "List of VM names to create"
  type        = list(string)
}

variable "vm_ips" {
  description = "List of IP addresses for the VMs"
  type        = list(string)
}

variable "vm_base_path" {
  description = "Base path where VM directories are created"
  type        = string
  default     = "../../vms"
}

variable "setup_script_path" {
  description = "Path to the setup script"
  type        = string
  default     = "./scripts/setup.sh"
}

variable "destroy_script_path" {
  description = "Path to the destroy script"
  type        = string
  default     = "./scripts/destroy.sh"
}

variable "ssh_user" {
  description = "SSH user for connecting to VMs"
  type        = string
  default     = "vagrant"
}

variable "ssh_timeout" {
  description = "SSH connection timeout in seconds"
  type        = number
  default     = 300
}

variable "vm_config_hash" {
  description = "Hash of VM configuration to trigger recreation when config changes"
  type        = string
  default     = ""
}