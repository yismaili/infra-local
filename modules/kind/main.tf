resource "null_resource" "install_kind" {
  connection {
    type        = var.vm_connection_configs[0].type
    host        = var.vm_connection_configs[0].host
    user        = var.vm_connection_configs[0].user
    private_key = var.vm_connection_configs[0].private_key
    timeout     = var.vm_connection_configs[0].timeout
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Installing KIND on single VM host...'",
      "sudo apt-get update",
      "sudo apt-get install -y curl",
      
      # install kubectl
      "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\"",
      "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "rm kubectl",
      
      # install KIND
      "[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/${var.kind_version}/kind-linux-amd64",
      "chmod +x ./kind",
      "sudo mv ./kind /usr/local/bin/kind",
      
      "kind version",
      "kubectl version --client",
      
      "echo 'KIND installation completed on single VM host!'"
    ]
  }

  triggers = {
    vm_config_change = var.config_hash
    kind_version     = var.kind_version
  }
}

# Create KIND cluster configuration file
resource "null_resource" "create_kind_config" {
  depends_on = [null_resource.install_kind]
  
  connection {
    type        = var.vm_connection_configs[0].type
    host        = var.vm_connection_configs[0].host
    user        = var.vm_connection_configs[0].user
    private_key = var.vm_connection_configs[0].private_key
    timeout     = var.vm_connection_configs[0].timeout
  }

  provisioner "remote-exec" {
    inline = [
      "cat > /tmp/kind-config.yaml << 'EOF'",
      "kind: Cluster",
      "apiVersion: kind.x-k8s.io/v1alpha4",
      "nodes:",
      "  - role: control-plane",
      "    kubeadmConfigPatches:",
      "    - |",
      "      kind: InitConfiguration",
      "      nodeRegistration:",
      "        kubeletExtraArgs:",
      "          node-ip: ${var.vm_connection_configs[0].host}",
      "    - |",
      "      kind: ClusterConfiguration",
      "      apiServer:",
      "        certSANs:",
      "        - \"${var.vm_connection_configs[0].host}\"",
      "        - \"127.0.0.1\"",
      "        - \"localhost\"",
      "    extraPortMappings:",
      "      - containerPort: ${var.api_server_port}",
      "        hostPort: ${var.api_server_port}",
      "        protocol: TCP",
      "${join("\n", [for i in range(var.worker_node_count) : "  - role: worker"])}",
      "networking:",
      "  podSubnet: \"${var.cluster_config.networking.podSubnet}\"",
      "  serviceSubnet: \"${var.cluster_config.networking.serviceSubnet}\"",
      "EOF"
    ]
  }

  triggers = {
    config_change = var.config_hash
    worker_count  = var.worker_node_count
  }
}

# Create KIND cluster
resource "null_resource" "create_kind_cluster" {
  depends_on = [null_resource.create_kind_config]
  
  connection {
    type        = var.vm_connection_configs[0].type
    host        = var.vm_connection_configs[0].host
    user        = var.vm_connection_configs[0].user
    private_key = var.vm_connection_configs[0].private_key
    timeout     = var.vm_connection_configs[0].timeout
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Creating KIND cluster...'",
      "kind create cluster --name ${var.cluster_name} --config /tmp/kind-config.yaml --image kindest/node:${var.kubernetes_version}",
      "echo 'KIND cluster created successfully!'",
      "echo 'Verifying cluster status...'",
      "docker ps --filter 'label=io.x-k8s.kind.cluster=${var.cluster_name}'",
      "echo 'Getting cluster info using KIND...'",
      "kind get clusters",
      "echo 'Cluster creation completed!'"
    ]
  }

  triggers = {
    config_change = var.config_hash
    cluster_name  = var.cluster_name
    k8s_version   = var.kubernetes_version
  }
}

resource "null_resource" "download_kubeconfig" {
  depends_on = [null_resource.create_kind_cluster]
  
  connection {
    type        = var.vm_connection_configs[0].type
    host        = var.vm_connection_configs[0].host
    user        = var.vm_connection_configs[0].user
    private_key = var.vm_connection_configs[0].private_key
    timeout     = var.vm_connection_configs[0].timeout
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Exporting kubeconfig...'",
      "kind get kubeconfig --name ${var.cluster_name} > /tmp/kubeconfig-${var.cluster_name}.yaml",
      "echo 'Fixing kubeconfig server address...'",
      "sed -i 's|https://0.0.0.0:${var.api_server_port}|https://${var.vm_connection_configs[0].host}:${var.api_server_port}|g' /tmp/kubeconfig-${var.cluster_name}.yaml",
      "echo 'Kubeconfig exported and fixed at /tmp/kubeconfig-${var.cluster_name}.yaml'",
      "echo 'Testing kubectl connection...'",
      "kubectl --kubeconfig=/tmp/kubeconfig-${var.cluster_name}.yaml get nodes",
      "kubectl --kubeconfig=/tmp/kubeconfig-${var.cluster_name}.yaml cluster-info"
    ]
  }

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.root}/kubeconfig
      # Create temporary private key file
      echo '${var.vm_connection_configs[0].private_key}' > /tmp/terraform_key_$
      chmod 600 /tmp/terraform_key_$
      # Download kubeconfig
      scp -o StrictHostKeyChecking=no -i /tmp/terraform_key_$ ${var.vm_connection_configs[0].user}@${var.vm_connection_configs[0].host}:/tmp/kubeconfig-${var.cluster_name}.yaml ${path.root}/kubeconfig/
      # Clean up temporary key file
      rm -f /tmp/terraform_key_$
    EOT
  }

  triggers = {
    cluster_created = null_resource.create_kind_cluster.id
  }
}