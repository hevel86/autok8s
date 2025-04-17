# File: outputs.tf

output "vm_ids" {
  value = proxmox_vm_qemu.kube_node.*.id
  description = "The IDs of the created VMs"
}

output "vm_ips" {
  value = var.vm_ips
  description = "The IP addresses of the created VMs"
}

output "ssh_commands" {
  value = [
    for i, ip in var.vm_ips : "ssh ubuntu@${ip}"
  ]
  description = "SSH commands to connect to the VMs"
}

output "usb_passthrough_instructions" {
  value = <<-EOT
If USB passthrough doesn't work automatically, use these commands:

For kube1 (on node1):
qm set <VMID_for_kube1> -usb0 host=174c:55aa

For kube2 (on node2):
qm set <VMID_for_kube2> -usb0 host=174c:55aa

Replace <VMID_for_kubeX> with the actual VM ID shown in the vm_ids output.
  EOT
  description = "Instructions for manual USB passthrough if needed"
}

output "microk8s_setup_instructions" {
  value = <<-EOT
After the VMs are created:

1. SSH into the first node:
   ssh ubuntu@${var.vm_ips[0]}

2. Install MicroK8s:
   sudo snap install microk8s --classic

3. Add user to microk8s group:
   sudo usermod -a -G microk8s ubuntu
   mkdir -p ~/.kube
   sudo chown -f -R ubuntu ~/.kube
   newgrp microk8s

4. Wait for microk8s to be ready:
   microk8s status --wait-ready

5. Get the join command:
   microk8s add-node

6. On the other nodes, install microk8s and join the cluster:
   sudo snap install microk8s --classic
   sudo usermod -a -G microk8s ubuntu
   newgrp microk8s
   microk8s join <join-command-from-step-5>

7. On the first node, enable necessary addons:
   microk8s enable dns storage ingress
  EOT
  description = "Instructions for setting up MicroK8s after VM creation"
}

output "microceph_setup_instructions" {
  value = <<-EOT
After setting up MicroK8s:

1. On all nodes, install MicroCeph:
   sudo snap install microceph

2. On the first node, bootstrap the cluster:
   sudo microceph cluster bootstrap

3. Get the join token:
   sudo microceph cluster add

4. On the other nodes, join the cluster:
   sudo microceph cluster join <token-from-step-3>

5. Add the disk devices on each node:
   # On node0:
   sudo microceph disk add /dev/sdb --wipe

   # On node1 and node2, find the USB disk device:
   lsblk -o NAME,SIZE,MODEL,SERIAL
   # Then add it (assuming it's /dev/sdb):
   sudo microceph disk add /dev/sdb --wipe
  EOT
  description = "Instructions for setting up MicroCeph after MicroK8s is configured"
}
