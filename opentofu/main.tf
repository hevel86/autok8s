resource "proxmox_vm_qemu" "kube_node" {
  count = 3
  name = "kube${count.index}"
  desc = "Kubernetes node ${count.index} - Created by Terraform"
  
  # Node allocation - distribute across your 3 nodes
  target_node = count.index == 0 ? "node0" : (count.index == 1 ? "node1" : "node2")
  
  # Clone from template VMID (9001) that lives on node0
  clone      = 9001
  clone_node = "node0"
  
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