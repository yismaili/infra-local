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
  description = "Dependencies to wait for before provisioning KIND"
  type        = list(string)
  default     = []
}

variable "config_hash" {
  description = "Hash of configuration to trigger updates"
  type        = string
  default     = ""
}

variable "kind_version" {
  description = "KIND version to install"
  type        = string
  default     = "v0.20.0"
}

variable "cluster_name" {
  description = "Name of the KIND cluster"
  type        = string
  default     = "kind-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for KIND cluster"
  type        = string
  default     = "v1.27.3"
}

variable "worker_node_count" {
  description = "Number of worker nodes in the cluster"
  type        = number
  default     = 1
}

variable "api_server_port" {
  description = "Port for Kubernetes API server"
  type        = number
  default     = 6443
}

variable "install_k8s_tools" {
  description = "Whether to install additional Kubernetes tools (helm, k9s, etc.)"
  type        = bool
  default     = true
}

variable "additional_clusters" {
  description = "Additional KIND clusters to create on the same VM"
  type = list(object({
    name = string
  }))
  default = []
}

variable "cluster_config" {
  description = "Custom KIND cluster configuration"
  type = object({
    networking = optional(object({
      podSubnet     = optional(string, "10.244.0.0/16")
      serviceSubnet = optional(string, "10.96.0.0/12")
    }), {})
    feature_gates = optional(map(bool), {})
    runtime_config = optional(map(string), {})
  })
  default = {}
}