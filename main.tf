resource "null_resource" "vms" {
  count = length(var.vm_names)

  provisioner "local-exec" {
    command = "VAGRANT_VM_NAME=${var.vm_names[count.index]} VAGRANT_VM_IP=${var.vm_ips[count.index]} ./scripts/setup.sh"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "./scripts/destroy.sh ${count.index}"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}
