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
  
  # For node0 only, add the raw disk passthrough
  dynamic "disk" {
    for_each = count.index == 0 ? [1] : []
    content {
      type = "scsi"
      file = "ata-Seagate_IronWolf_ZA2000NM10002-2ZG103_7TD003Q9"
      format = "passthrough" 
      size = "0"  # Size is ignored for passthrough
    }
  }
  
  # USB Passthrough configuration for node1 and node2
  # Note: This is done via custom parameters since the provider doesn't support this directly
  dynamic "usb" {
    for_each = count.index == 1 || count.index == 2 ? [1] : []
    content {
      host = "174c:55aa"  # ASMedia SATA-to-USB bridge
    }
  }
  
  # Network configuration
  network {
    model = "virtio"
    bridge = "vmbr0"
    tag = 2
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
