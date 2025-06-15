#!/bin/bash

index=$1

# Match index to name manually
case $index in
  0) vm_name="server-w0" ;;
  1) vm_name="server-w1" ;;
  2) vm_name="server-w2" ;;
  3) vm_name="server-w3" ;;
  *) echo "Invalid index $index"; exit 1 ;;
esac

echo "Destroying VM: $vm_name"
cd "vms/$vm_name" && vagrant destroy -f
