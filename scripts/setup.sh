#!/bin/bash

VM_NAME=$VAGRANT_VM_NAME
VM_IP=$VAGRANT_VM_IP
WORK_DIR="./vms/$VM_NAME"

mkdir -p "$WORK_DIR"

cat <<EOF > "$WORK_DIR/Vagrantfile"
Vagrant.configure("2") do |config|
  config.vm.box = "bento/debian-11"
  config.vm.define "$VM_NAME" do |vm|
    vm.vm.hostname = "$VM_NAME"
    vm.vm.network "private_network", ip: "$VM_IP"
    vm.vm.provider "virtualbox" do |vb|
      vb.name = "$VM_NAME"
      vb.cpus = 2
      vb.memory = 1024
    end
    vm.vm.provision "shell", inline: <<-SHELL
      apt update
      apt install -y nginx
    SHELL
  end
end
EOF

cd "$WORK_DIR"
vagrant up
