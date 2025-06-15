resource "null_resource" "vms" {
  count = length(var.vm_names)

  # First, run local setup script to create/configure VM
  provisioner "local-exec" {
    command = "VAGRANT_VM_NAME=${var.vm_names[count.index]} VAGRANT_VM_IP=${var.vm_ips[count.index]} ./scripts/setup.sh"
  }

  # Wait for VM to be ready before proceeding
  provisioner "local-exec" {
    command = <<-EOF
      start_time=$(date +%s)
      while ! nc -z ${var.vm_ips[count.index]} 22; do
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        if [ $elapsed -gt 300 ]; then
          echo "Timeout waiting for SSH on ${var.vm_ips[count.index]}:22"
          exit 1
        fi
        echo "Waiting for SSH on ${var.vm_ips[count.index]}:22... ($elapsed/300s)"
        sleep 5
      done
      echo "SSH is available on ${var.vm_ips[count.index]}:22"
    EOF
  }

  connection {
    type        = "ssh"
    host        = self.triggers.vm_ip
    user        = "vagrant"
    private_key = file("./vms/${self.triggers.vm_name}/.vagrant/machines/${self.triggers.vm_name}/virtualbox/private_key")
    timeout     = "5m"
  }

  # Install Docker and Docker Compose
  provisioner "remote-exec" {
    inline = [
      "echo 'Installing Docker on ${var.vm_names[count.index]}'",
      "sudo apt update -y",
      "sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release",
      
      # Add Docker's official GPG key
      "sudo mkdir -p /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      
      # Set up the repository
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      
      # Install Docker Engine
      "sudo apt update -y",
      "sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      
      # Add user to docker group
      "sudo usermod -aG docker vagrant",
      
      # Enable and start Docker service
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      
      # Verify installation
      "echo 'Verifying Docker installation...'",
      "sudo docker --version",
      "sudo docker compose version",
      
      # Test Docker without sudo (requires re-login, but we can test with sudo for now)
      "sudo docker run --rm hello-world"
    ]
  }

  # Cleanup script on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "./scripts/destroy.sh ${count.index}"
  }

  # Only recreate if VM configuration changes, not on every apply
  triggers = {
    vm_name = var.vm_names[count.index]
    vm_ip   = var.vm_ips[count.index]
    # Add other relevant variables that should trigger recreation
    # vm_config_hash = md5(jsonencode(var.vm_configs[count.index]))
  }
}