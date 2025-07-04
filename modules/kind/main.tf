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

resource "local_file" "kind_config" {
  content = yamlencode({
    kind       = "Cluster"
    apiVersion = "kind.x-k8s.io/v1alpha4"
    name       = var.cluster_name
    nodes = concat(
      [
        {
          role = "control-plane"
          extraPortMappings = [
            {
              containerPort = 6443
              hostPort      = var.api_server_port
              protocol      = "TCP"
            }
          ]
        }
      ],
      [
        for i in range(var.worker_node_count) : {
          role = "worker"
        }
      ]
    )
    networking = {
      apiServerAddress = var.vm_connection_configs[0].host
      apiServerPort    = var.api_server_port
    }
  })
  
  filename = "${path.module}/kind-config.yaml"
}

resource "null_resource" "create_kind_cluster" {
  depends_on = [null_resource.install_kind, local_file.kind_config]

  connection {
    type        = var.vm_connection_configs[0].type
    host        = var.vm_connection_configs[0].host
    user        = var.vm_connection_configs[0].user
    private_key = var.vm_connection_configs[0].private_key
    timeout     = var.vm_connection_configs[0].timeout
  }

  provisioner "file" {
    source      = "${path.module}/kind-config.yaml"
    destination = "/tmp/kind-config.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Creating KIND cluster ${var.cluster_name}...'",
      
      "kind delete cluster --name ${var.cluster_name} 2>/dev/null || true",
      
      "kind create cluster --config /tmp/kind-config.yaml --name ${var.cluster_name}",
      
      "sleep 30",
      
      "kubectl cluster-info --context kind-${var.cluster_name}",
      "kubectl get nodes --context kind-${var.cluster_name}",
      
      "kind get kubeconfig --name ${var.cluster_name} > /tmp/kubeconfig-${var.cluster_name}.yaml",
      
      "sed -i 's|https://127.0.0.1:${var.api_server_port}|https://${var.vm_connection_configs[0].host}:${var.api_server_port}|g' /tmp/kubeconfig-${var.cluster_name}.yaml",
      
      "echo 'KIND cluster ${var.cluster_name} created successfully!'"
    ]
  }

  triggers = {
    cluster_config = local_file.kind_config.content_md5
    vm_ready       = null_resource.install_kind.id
  }
}


resource "null_resource" "download_kubeconfig" {
  depends_on = [null_resource.create_kind_cluster]

  provisioner "local-exec" {
    command = <<-EOT
      echo 'Downloading kubeconfig from master node...'
      
      # Create local kubeconfig directory
      mkdir -p ${path.root}/kubeconfig
      
      # Download kubeconfig using scp
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
          -i ${var.vm_connection_configs[0].private_key} \
          ${var.vm_connection_configs[0].user}@${var.vm_connection_configs[0].host}:/tmp/kubeconfig-${var.cluster_name}.yaml \
          ${path.root}/kubeconfig/kubeconfig-${var.cluster_name}.yaml
      
      echo 'Kubeconfig downloaded to ${path.root}/kubeconfig/kubeconfig-${var.cluster_name}.yaml'
    EOT
  }

  triggers = {
    cluster_ready = null_resource.create_kind_cluster.id
  }
}

resource "null_resource" "additional_test_clusters" {
  count = length(var.additional_clusters)
  
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
      "echo 'Creating additional KIND cluster ${var.additional_clusters[count.index].name}...'",
      
      "kind delete cluster --name ${var.additional_clusters[count.index].name} 2>/dev/null || true",
      
      "kind create cluster --name ${var.additional_clusters[count.index].name}",
      
      "kubectl cluster-info --context kind-${var.additional_clusters[count.index].name}",
      
      "echo 'Additional KIND cluster ${var.additional_clusters[count.index].name} created!'"
    ]
  }

  triggers = {
    vm_ready        = null_resource.install_kind.id
    cluster_config  = jsonencode(var.additional_clusters[count.index])
  }
}

resource "null_resource" "install_k8s_tools" {
  count = var.install_k8s_tools ? 1 : 0
  
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
      "echo 'Installing Kubernetes tools...'",
      
      "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash",
      
      "wget https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz",
      "tar -xzf k9s_Linux_amd64.tar.gz",
      "sudo mv k9s /usr/local/bin/",
      "rm k9s_Linux_amd64.tar.gz",
      
      "sudo apt-get install -y git",
      "git clone https://github.com/ahmetb/kubectx /opt/kubectx",
      "sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx",
      "sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens",
      
      "echo 'Kubernetes tools installation completed!'"
    ]
  }

  triggers = {
    cluster_ready = null_resource.create_kind_cluster.id
    tools_flag    = var.install_k8s_tools
  }
}

resource "null_resource" "cluster_verification" {
  depends_on = [
    null_resource.create_kind_cluster,
    null_resource.download_kubeconfig
  ]

  connection {
    type        = var.vm_connection_configs[0].type
    host        = var.vm_connection_configs[0].host
    user        = var.vm_connection_configs[0].user
    private_key = var.vm_connection_configs[0].private_key
    timeout     = var.vm_connection_configs[0].timeout
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Verifying KIND cluster status...'",
      "sleep 15",
      
      "kubectl get nodes --context kind-${var.cluster_name} -o wide",
      "kubectl get pods -A --context kind-${var.cluster_name}",
      "kubectl get services --context kind-${var.cluster_name}",
      
      "kind get clusters",
      "docker ps --filter 'label=io.x-k8s.kind.cluster=${var.cluster_name}'",
      
      "echo 'KIND cluster verification completed!'"
    ]
  }

  triggers = {
    cluster_ready = null_resource.create_kind_cluster.id
  }
}