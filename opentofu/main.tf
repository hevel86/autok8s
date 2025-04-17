locals {
  kube_nodes = ["node0", "node1", "node2"]
  mac_addrs  = [
    "BC:24:11:2B:E9:B9",
    "BC:24:11:A4:F9:E7",
    "BC:24:11:68:0B:B1"
  ]
}

resource "proxmox_vm_qemu" "kube_node" {
  count       = length(local.kube_nodes)
  name        = "kube${count.index}"
  desc        = "Kubernetes node ${count.index}"
  target_node = local.kube_nodes[count.index]

  clone_id   = 9001
  full_clone = true

  cores     = 8
  sockets   = 1
  cpu_type  = "host"
  memory    = 8192

  disk {
    slot    = 0
    type    = "scsi"
    storage = "local-zfs"
    size    = "64G"
  }

  network {
    id      = 0
    model   = "virtio"
    bridge  = "vmbr0"
    tag     = 2
    macaddr = local.mac_addrs[count.index]
  }

  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
  ipconfig0  = "ip=${var.vm_ips[count.index]}/24,gw=${var.gateway}"
  nameserver = var.dns_servers

  onboot = true
  agent  = 1

  lifecycle {
    ignore_changes = [
      network,
      qemu_os,
    ]
  }
}
