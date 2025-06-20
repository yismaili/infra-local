#!/bin/bash

index=$1

case $index in
  0) vm_name="master" ;;
  1) vm_name="server-w1" ;;
  2) vm_name="server-w2" ;;
  3) vm_name="server-w3" ;;
  *) echo "Invalid index $index"; exit 1 ;;
esac

echo "Destroying VM: $vm_name"
cd "vms/$vm_name" && vagrant destroy -f