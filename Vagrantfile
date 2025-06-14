# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
    # Set up the Server
    config.vm.box = "bento/debian-11"
    config.vm.define 'server-w0' do |server|
      server.vm.hostname = 'server-w0'
      server.vm.network 'private_network', ip: '192.168.56.110'
      # VirtualBox provider settings
      server.vm.provider 'virtualbox' do |vb|
        vb.name = "server-w0"
        vb.cpus = 2
        vb.memory = 2048
      end
    #   server.vm.provision "shell", path: "script/setup-server.sh"
    end
  
    config.vm.define 'server-w1' do |server_w1|
        server_w1.vm.hostname = 'server-w1'
        server_w1.vm.network 'private_network', ip: '192.168.56.111'
        server_w1.vm.provider 'virtualbox' do |vb|
          vb.name = "server-w1"
          vb.cpus = 2
          vb.memory = 2048
        end
      end

      config.vm.define 'server-w2' do |server_w2|
        server_w2.vm.hostname = 'server-w2'
        server_w2.vm.network 'private_network', ip: '192.168.56.112'
        server_w2.vm.provider 'virtualbox' do |vb|
          vb.name = "server-w2"
          vb.cpus = 2
          vb.memory = 2048
        end
      end
  end