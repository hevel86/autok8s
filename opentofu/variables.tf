variable "proxmox_api_url" {
  description = "The Proxmox API URL"
  type = string
  default = "https://datto2.torquasmvo.internal:8006/api2/json"
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID"
  type = string
  default = "root@pam!terraform"  # Change this to match your actual token ID format
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type = string
  sensitive = true
  default = "b66d8390-637a-4366-a6d5-62dd31736bbf"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type = string
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDxUUwSrhfd6u9iZ31SaCGdqgf/TsgEMBh7EFS7QzOlL"
}

variable "vm_ips" {
  description = "IPs for Kubernetes nodes"
  type = list(string)
  default = ["10.0.0.31", "10.0.0.32", "10.0.0.33"]
}

variable "gateway" {
  description = "Network gateway"
  type = string
  default = "192.168.1.1"
}

variable "dns_servers" {
  description = "DNS servers"
  type = list(string)
  default = ["192.168.1.8, 192.168.1.7"]
}
