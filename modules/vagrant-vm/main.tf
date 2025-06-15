# modules/vagrant-vm/main.tf

resource "null_resource" "vagrant_vm" {
  count = length(var.vm_names)

  # Create/configure VM using setup script
  provisioner "local-exec" {
    command = "VAGRANT_VM_NAME=${var.vm_names[count.index]} VAGRANT_VM_IP=${var.vm_ips[count.index]} ${var.setup_script_path}"
  }

  # Wait for VM to be ready
  provisioner "local-exec" {
    command = <<-EOF
      start_time=$(date +%s)
      while ! nc -z ${var.vm_ips[count.index]} 22; do
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        if [ $elapsed -gt ${var.ssh_timeout} ]; then
          echo "Timeout waiting for SSH on ${var.vm_ips[count.index]}:22"
          exit 1
        fi
        echo "Waiting for SSH on ${var.vm_ips[count.index]}:22... ($elapsed/${var.ssh_timeout}s)"
        sleep 5
      done
      echo "SSH is available on ${var.vm_ips[count.index]}:22"
    EOF
  }

  # Cleanup on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "./scripts/destroy.sh ${count.index}"
  }

  triggers = {
    vm_name = var.vm_names[count.index]
    vm_ip   = var.vm_ips[count.index]
    vm_config_hash = var.vm_config_hash
    destroy_script = var.destroy_script_path
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Connection configuration for other provisioners to use
locals {
  connection_configs = [
    for i in range(length(var.vm_names)) : {
      type        = "ssh"
      host        = var.vm_ips[i]
      user        = var.ssh_user
      private_key = try(file("${var.vm_base_path}/${var.vm_names[i]}/.vagrant/machines/${var.vm_names[i]}/virtualbox/private_key"), "")
      timeout     = "${var.ssh_timeout}s"
    }
  ]
}