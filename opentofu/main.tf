###############################################################################
# Clone your ubuntu-cloud template (VMID 9001, name "ubuntu-cloud")
###############################################################################

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
  desc        = "Kubernetes node ${count.index} - Created by Terraform"
  target_node = local.kube_nodes[count.index]

  # ─── Clone using the template’s NAME (not clone_id) ─────────────────────────
  clone      = "kubernetes-cloud"
  full_clone = true

  # ─── CPU / RAM ──────────────────────────────────────────────────────────────
  cores   = 8
  sockets = 1
  cpu_type = "host"    # older versions expect `cpu`, not `cpu_type`
  memory  = 8192

  # ─── Root disk override (slot is implied to be 0) ───────────────────────────
  # disk {
  #   type    = "scsi"
  #   storage = "local-zfs"
  #   size    = "64G"
  # }
  # Root disk is not overwritten since we're now using a template with a 64GB base disk

  # ─── Network (first NIC only; `id = 0` is implicit) ────────────────────────
  network {
    id      = 0
    model   = "virtio"
    bridge  = "vmbr0"
    tag     = 2
    macaddr = local.mac_addrs[count.index]
  }

  # ─── Cloud‑Init ────────────────────────────────────────────────────────────
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
  ipconfig0  = "ip=${var.vm_ips[count.index]}/24,gw=${var.gateway}"
  nameserver = var.dns_servers    # now a comma‐separated string

  # ─── Boot & QEMU Agent ─────────────────────────────────────────────────────
  onboot = true
  agent  = 1

  lifecycle {
    ignore_changes = [
      network,
      qemu_os,
    ]
  }
}
