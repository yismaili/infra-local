
resource "null_resource" "docker_installation" {
  count = length(var.vm_connection_configs)

  connection {
    type        = var.vm_connection_configs[count.index].type
    host        = var.vm_connection_configs[count.index].host
    user        = var.vm_connection_configs[count.index].user
    private_key = var.vm_connection_configs[count.index].private_key
    timeout     = var.vm_connection_configs[count.index].timeout
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Installing Docker on VM ${count.index + 1}...'",
    
      "sudo apt update -y",
      
      "sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release",
      
      "sudo mkdir -p /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/${var.os_distribution}/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${var.os_distribution} $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      
      "sudo apt update -y",
      "sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      
      "sudo usermod -aG docker ${var.vm_connection_configs[count.index].user}",
      
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      
      "sleep 3",
      
      "echo 'Verifying Docker installation...'",
      "sudo docker --version",
      "sudo docker compose version",
      var.test_docker ? "sudo docker run --rm hello-world" : "echo 'Skipping Docker test'"
    ]
  }

  triggers = {
    vm_host = var.vm_connection_configs[count.index].host
    docker_version = var.docker_version_trigger
    config_hash = var.config_hash
  }

  depends_on = [var.vm_dependencies]
}

