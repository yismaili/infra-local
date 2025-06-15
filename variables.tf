variable "vm_names" {
  type    = list(string)
  default = ["server-w0", "server-w1", "server-w2"]
}

variable "vm_ips" {
  type    = list(string)
  default = ["192.168.56.110", "192.168.56.111", "192.168.56.112"]
}
