resource "null_resource" "vagrant_vm" {
  count = length(var.vm_names)

  # create/configure VM using setup script
  provisioner "local-exec" {
    command = "VAGRANT_VM_NAME=${var.vm_names[count.index]} VAGRANT_VM_IP=${var.vm_ips[count.index]} ${var.setup_script_path}"
  }

  # wait for VM to be ready
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

  # destroy vms
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

# wait for private keys to be generated
resource "null_resource" "wait_for_keys" {
  count = length(var.vm_names)
  
  depends_on = [null_resource.vagrant_vm]
  
  provisioner "local-exec" {
    command = <<-EOF
      echo "Waiting for private key to be generated for ${var.vm_names[count.index]}..."
      for i in {1..30}; do
        if [ -f "${var.vm_base_path}/${var.vm_names[count.index]}/.vagrant/machines/${var.vm_names[count.index]}/virtualbox/private_key" ]; then
          echo "Private key found for ${var.vm_names[count.index]}"
          exit 0
        fi
        echo "Attempt $i: Private key not found, waiting..."
        sleep 5
      done
      echo "Timeout waiting for private key for ${var.vm_names[count.index]}"
      exit 1
    EOF
  }
}

# get private keys after VMs are created
data "local_file" "private_keys" {
  count    = length(var.vm_names)
  filename = "${var.vm_base_path}/${var.vm_names[count.index]}/.vagrant/machines/${var.vm_names[count.index]}/virtualbox/private_key"
  
  depends_on = [null_resource.wait_for_keys]
}

# connection configuration for other provisioners to use
locals {
  connection_configs = [
    for i in range(length(var.vm_names)) : {
      type        = "ssh"
      host        = var.vm_ips[i]
      user        = var.ssh_user
      private_key = data.local_file.private_keys[i].content
      timeout     = "${var.ssh_timeout}s"
    }
  ]
}