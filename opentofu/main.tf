###############################################################################
# Clone your ubuntu-cloud template (9001) onto three Proxmox nodes
###############################################################################

resource "proxmox_vm_qemu" "kube_node" {
  count = 3
  name  = "kube${count.index}"
  desc  = "Kubernetes node ${count.index} - Created by Terraform"

  # Distribute across your 3 Proxmox hosts
  target_node = count.index == 0 ? "node0" : (count.index == 1 ? "node1" : "node2")

  # ─── Use the numeric VMID for cloning ────────────────────────────────────────
  clone_id   = 9001    # your ubuntu‑cloud template now on nfs‑datastore‑truenas0
  full_clone = true

  # ─── CPU / RAM ──────────────────────────────────────────────────────────────
  cores     = 8
  sockets   = 1
  cpu_type  = "host"    # renamed from cpu = "host"
  memory    = 8192

  # ─── Root disk override to local-zfs (slot 0) ──────────────────────────────
  disk {
    slot    = 0
    type    = "scsi"
    storage = "local-zfs"
    size    = "64G"
  }

  # ─── Network (slot 0) ──────────────────────────────────────────────────────
  network {
    id      = 0
    model   = "virtio"
    bridge  = "vmbr0"
    tag     = 2
    macaddr = count.index == 0 ? "bc:24:11:2b:e9:b9"
            : (count.index == 1 ? "bc:24:11:a4:f9:e7"
                                 : "bc:24:11:68:0b:b1")
  }

  # ─── Cloud‑Init ────────────────────────────────────────────────────────────
  ciuser     = "ubuntu"
  sshkeys    = var.ssh_public_key
  ipconfig0  = "ip=${var.vm_ips[count.index]}/24,gw=${var.gateway}"
  nameserver = var.dns_servers

  # ─── Boot & QEMU Agent ─────────────────────────────────────────────────────
  onboot = true
  agent  = 1

  # ─── Prevent spurious diffs on network & OS defaults ────────────────────────
  lifecycle {
    ignore_changes = [
      network,
      qemu_os,
    ]
  }
}
