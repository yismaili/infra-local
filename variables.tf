variable "vm_names" {
  type    = list(string)
  default = ["null", "null", "null", "null"]
}

variable "vm_ips" {
  type    = list(string)
  default = ["0.0.0.0", "0.0.0.0", "0.0.0.0", "0.0.0.0"]
}
