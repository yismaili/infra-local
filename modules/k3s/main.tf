resource "null_resource" "k3s_server" {
  connection {
    type        = var.vm_connection_configs[0].type
    host        = var.vm_connection_configs[0].host
    user        = var.vm_connection_configs[0].user
    private_key = var.vm_connection_configs[0].private_key
    timeout     = var.vm_connection_configs[0].timeout
  }

 provisioner "remote-exec" {
  inline = [
    "echo 'Installing k3s server on master node...'",
    "sudo apt-get update",
    "sudo apt-get install -y curl python3",

    # Set variables properly
    "NODE_IP=${var.vm_connection_configs[0].host}",
    "curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --node-ip $NODE_IP",

    "sudo systemctl enable k3s",
    "sudo systemctl start k3s",
    "sleep 30",
    "sudo k3s kubectl get nodes",
    "echo 'K3s server installation completed successfully!'"
  ]
}


  triggers = {
    vm_config_change = var.config_hash
  }
}

# Create the Python server script as a local file first
resource "local_file" "token_server_script" {
  depends_on = [null_resource.k3s_server]
  
  content = <<-PYTHON
#!/usr/bin/env python3
import http.server
import socketserver
import os
import threading
import time

PORT = 8080
TIMEOUT = 300  # 5 minutes timeout

class TokenHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/token':
            try:
                with open('token.txt', 'r') as f:
                    token = f.read().strip()
                self.send_response(200)
                self.send_header('Content-type', 'text/plain')
                self.end_headers()
                self.wfile.write(token.encode())
            except Exception as e:
                self.send_error(500, str(e))
        elif self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(b'OK')
        else:
            self.send_error(404)

def shutdown_server():
    time.sleep(TIMEOUT)
    print('Server timeout reached, shutting down...')
    os._exit(0)

if __name__ == '__main__':
    # Start timeout timer
    timer = threading.Thread(target=shutdown_server)
    timer.daemon = True
    timer.start()
    
    with socketserver.TCPServer(('', PORT), TokenHandler) as httpd:
        print(f'Serving token at port {PORT}')
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print('Server stopped')
PYTHON

  filename = "${path.module}/token_server.py"
}

# Set up HTTP server to serve the token
resource "null_resource" "setup_token_server" {
  depends_on = [null_resource.k3s_server, local_file.token_server_script]

  connection {
    type        = var.vm_connection_configs[0].type
    host        = var.vm_connection_configs[0].host
    user        = var.vm_connection_configs[0].user
    private_key = var.vm_connection_configs[0].private_key
    timeout     = var.vm_connection_configs[0].timeout
  }

  provisioner "file" {
    source      = "${path.module}/token_server.py"
    destination = "/tmp/token_server.py"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Setting up token HTTP server...'",
      
      # Create a secure directory for token serving
      "mkdir -p /tmp/k3s-token-server",
      "cd /tmp/k3s-token-server",
      
      # Copy the token to the server directory
      "sudo cat /var/lib/rancher/k3s/server/node-token > token.txt",
      "sudo chown $(whoami):$(whoami) token.txt",
      "chmod 600 token.txt",
      
      # Move and set up the server script
      "mv /tmp/token_server.py server.py",
      "chmod +x server.py",
      
      # Start the HTTP server in background
      "nohup python3 server.py > server.log 2>&1 &",
      "SERVER_PID=$!",
      "echo $SERVER_PID > server.pid",
      
      # Wait for server to start
      "sleep 5",
      
      # Test if server is running
      "curl -f http://localhost:8080/health || (echo 'Failed to start token server'; exit 1)",
      
      "echo 'Token HTTP server started successfully on port 8080'"
    ]
  }

  triggers = {
    server_setup = null_resource.k3s_server.id
    script_hash  = local_file.token_server_script.content_md5
  }
}

# Retrieve token via HTTP
resource "null_resource" "get_token_http" {
  depends_on = [null_resource.setup_token_server]
  
  provisioner "local-exec" {
    command = <<-EOT
      echo 'Retrieving K3s token via HTTP...'
      
      # Wait a moment to ensure server is ready
      sleep 2
      
      # Download token with retry logic
      MAX_RETRIES=5
      RETRY_COUNT=0
      
      while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if curl -f -s --connect-timeout 10 \
               http://${var.vm_connection_configs[0].host}:8080/token \
               -o ${path.module}/k3s_token.txt; then
          echo 'Token retrieved successfully'
          break
        else
          RETRY_COUNT=$((RETRY_COUNT + 1))
          echo "Retry $RETRY_COUNT/$MAX_RETRIES failed, waiting 5 seconds..."
          sleep 5
        fi
      done
      
      if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo 'Failed to retrieve token after all retries'
        exit 1
      fi
      
      # Verify token file exists and is not empty
      if [ ! -s ${path.module}/k3s_token.txt ]; then
        echo 'Token file is empty or does not exist'
        exit 1
      fi
      
      echo 'K3s token retrieved successfully via HTTP'
    EOT
  }

  triggers = {
    token_server_ready = null_resource.setup_token_server.id
  }
}

# Alternative: Using external data source with HTTP
data "external" "k3s_token_http" {
  depends_on = [null_resource.setup_token_server]
  
  program = ["bash", "-c", <<-EOT
    # Retrieve token via HTTP with error handling
    TOKEN=$(curl -f -s --connect-timeout 10 \
                 --retry 3 --retry-delay 5 \
                 http://${var.vm_connection_configs[0].host}:8080/token)
    
    if [ -z "$TOKEN" ]; then
      echo '{"error": "Failed to retrieve token"}' >&2
      exit 1
    fi
    
    echo "{\"token\": \"$TOKEN\"}"
  EOT
  ]
}

# Install k3s agents using HTTP-retrieved token
resource "null_resource" "k3s_agents" {
  count = length(var.vm_connection_configs) - 1
  
  depends_on = [null_resource.get_token_http]

  connection {
    type        = var.vm_connection_configs[count.index + 1].type
    host        = var.vm_connection_configs[count.index + 1].host
    user        = var.vm_connection_configs[count.index + 1].user
    private_key = var.vm_connection_configs[count.index + 1].private_key
    timeout     = var.vm_connection_configs[count.index + 1].timeout
  }

  provisioner "file" {
    source      = "${path.module}/k3s_token.txt"
    destination = "/tmp/k3s_token.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Installing k3s agent on worker node ${count.index + 1}...'",
      "sudo apt-get update",
      "sudo apt-get install -y curl",
      
      # Get the token and set up variables
      "K3S_TOKEN=$(cat /tmp/k3s_token.txt | tr -d '\\n\\r')",
      "K3S_SERVER_IP=${var.vm_connection_configs[0].host}",
      "NODE_IP=${var.vm_connection_configs[count.index + 1].host}",
      
      # Validate token
      "if [ -z \"$K3S_TOKEN\" ]; then echo 'Token is empty'; exit 1; fi",
      
      # Install k3s agent
      "curl -sfL https://get.k3s.io | K3S_URL=https://$K3S_SERVER_IP:6443 K3S_TOKEN=$K3S_TOKEN sh -s - --node-ip $NODE_IP",
      
      # Enable and start k3s-agent
      "sudo systemctl enable k3s-agent",
      "sudo systemctl start k3s-agent",
      "sleep 15",
      
      # Clean up token file
      "rm -f /tmp/k3s_token.txt",
      
      "echo 'K3s agent installation completed successfully!'"
    ]
  }

  triggers = {
    vm_config_change = var.config_hash
    token_retrieved  = null_resource.get_token_http.id
  }
}

# Alternative agents using external data source
resource "null_resource" "k3s_agents_external" {
  count = length(var.vm_connection_configs) - 1
  
  depends_on = [data.external.k3s_token_http]

  connection {
    type        = var.vm_connection_configs[count.index + 1].type
    host        = var.vm_connection_configs[count.index + 1].host
    user        = var.vm_connection_configs[count.index + 1].user
    private_key = var.vm_connection_configs[count.index + 1].private_key
    timeout     = var.vm_connection_configs[count.index + 1].timeout
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Installing k3s agent on worker node ${count.index + 1}...'",
      "sudo apt-get update",
      "sudo apt-get install -y curl",
      
      # Use token directly from HTTP data source
      "K3S_TOKEN='${data.external.k3s_token_http.result.token}'",
      "K3S_SERVER_IP=${var.vm_connection_configs[0].host}",
      "NODE_IP=${var.vm_connection_configs[count.index + 1].host}",
      
      # Install k3s agent
      "curl -sfL https://get.k3s.io | K3S_URL=https://$K3S_SERVER_IP:6443 K3S_TOKEN=$K3S_TOKEN sh -s - --node-ip $NODE_IP",
      
      # Enable and start k3s-agent
      "sudo systemctl enable k3s-agent",
      "sudo systemctl start k3s-agent",
      "sleep 15",
      
      "echo 'K3s agent installation completed successfully!'"
    ]
  }

  triggers = {
    vm_config_change = var.config_hash
    token_change     = data.external.k3s_token_http.result.token
  }
}

# Clean up HTTP server after deployment
resource "null_resource" "cleanup_token_server" {
  depends_on = [null_resource.k3s_agents]

  connection {
    type        = var.vm_connection_configs[0].type
    host        = var.vm_connection_configs[0].host
    user        = var.vm_connection_configs[0].user
    private_key = var.vm_connection_configs[0].private_key
    timeout     = var.vm_connection_configs[0].timeout
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Cleaning up token HTTP server...'",
      
      # Stop the HTTP server
      "cd /tmp/k3s-token-server || true",
      "if [ -f server.pid ]; then",
      "  SERVER_PID=$(cat server.pid)",
      "  kill $SERVER_PID 2>/dev/null || true",
      "  rm -f server.pid",
      "fi",
      
      # Clean up files
      "rm -rf /tmp/k3s-token-server",
      
      "echo 'Token server cleanup completed'"
    ]
  }

  # Also clean up local files
  provisioner "local-exec" {
    command = "rm -f ${path.module}/k3s_token.txt ${path.module}/token_server.py"
  }

  triggers = {
    cleanup_after = join(",", null_resource.k3s_agents[*].id)
  }
}

# verify cluster status
resource "null_resource" "cluster_verification" {
  depends_on = [null_resource.k3s_agents, null_resource.cleanup_token_server]

  connection {
    type        = var.vm_connection_configs[0].type
    host        = var.vm_connection_configs[0].host
    user        = var.vm_connection_configs[0].user
    private_key = var.vm_connection_configs[0].private_key
    timeout     = var.vm_connection_configs[0].timeout
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Verifying k3s cluster status...'",
      "sleep 30", # Wait for all nodes to join
      "sudo k3s kubectl get nodes -o wide",
      "sudo k3s kubectl get pods -A",
      "echo 'K3s cluster verification completed!'"
    ]
  }

  triggers = {
    cluster_ready = "${null_resource.k3s_server.id}-${join(",", null_resource.k3s_agents[*].id)}"
  }
}