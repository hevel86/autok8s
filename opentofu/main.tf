resource "proxmox_vm_qemu" "kube_node" {
  count = 3
  name = "kube${count.index}"
  desc = "Kubernetes node ${count.index} - Created by Terraform"
  
  # Node allocation - distribute across your 3 nodes
  target_node = count.index == 0 ? "node0" : (count.index == 1 ? "node1" : "node2")
  
  # Clone from template
  clone = var.template_vmid
  full_clone = true
  
  # VM specifications
  cores = 8
  sockets = 1
  cpu = "host"
  memory = 8192
  
  # Use local-zfs for OS disk
  disk {
    type = "scsi"
    storage = "local-zfs"
    size = "64G"
  }
  
  # Network configuration with specific MAC addresses
  network {
    model = "virtio"
    bridge = "vmbr0"
    tag = 2
    macaddr = count.index == 0 ? "bc:24:11:2b:e9:b9" : (count.index == 1 ? "bc:24:11:a4:f9:e7" : "bc:24:11:68:0b:b1")
  }
  
  # Cloud-init settings
  ciuser = "ubuntu"
  sshkeys = var.ssh_public_key
  
  # Static IP configuration
  ipconfig0 = "ip=${var.vm_ips[count.index]}/24,gw=${var.gateway}"

  # Set the nameserver to use your PiHole instances
  nameserver = var.dns_servers
  
  # Ensure the VM starts on boot
  onboot = true
  
  # VM agent
  agent = 1
  
  # Added to prevent terraform from constantly seeing changes
  lifecycle {
    ignore_changes = [
      network,
      qemu_os
    ]
  }
}

# Create inventory.tmpl file for Ansible
resource "local_file" "inventory_template" {
  content = <<-EOT
[kube_masters]
%{ for i, ip in var.vm_ips ~}
kube${i} ansible_host=${ip}
%{ endfor ~}

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  EOT
  filename = "${path.module}/../ansible/inventory/hosts.ini"
}