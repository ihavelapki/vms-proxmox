variable "node_name" {
  description = "Name of the standalone Proxmox VE node on which VMs are created."
  type        = string

  validation {
    condition     = length(trimspace(var.node_name)) > 0
    error_message = "node_name must not be empty."
  }
}

variable "template_vm_id" {
  description = "VM ID of the external Ubuntu 24.04 cloud-init template."
  type        = number

  validation {
    condition     = var.template_vm_id >= 100 && var.template_vm_id <= 999999999 && floor(var.template_vm_id) == var.template_vm_id
    error_message = "template_vm_id must be an integer from 100 through 999999999."
  }
}

variable "datastore_id" {
  description = "Existing Proxmox datastore used for full-clone, root, and cloud-init disks."
  type        = string
  default     = "local-lvm"

  validation {
    condition     = length(trimspace(var.datastore_id)) > 0
    error_message = "datastore_id must not be empty."
  }
}

variable "network_bridge" {
  description = "Existing Proxmox bridge connected to a network with IPv4 DHCP."
  type        = string

  validation {
    condition     = length(trimspace(var.network_bridge)) > 0
    error_message = "network_bridge must not be empty."
  }
}

variable "network_vlan_id" {
  description = "Optional VLAN tag for the single VM network interface; null means untagged."
  type        = number
  default     = null

  validation {
    condition = var.network_vlan_id == null ? true : (
      var.network_vlan_id >= 1 &&
      var.network_vlan_id <= 4094 &&
      floor(var.network_vlan_id) == var.network_vlan_id
    )
    error_message = "network_vlan_id must be null or an integer from 1 through 4094."
  }
}

variable "guest_username" {
  description = "Linux account configured by native Proxmox cloud-init."
  type        = string
  default     = "ubuntu"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]*$", var.guest_username))
    error_message = "guest_username must be a lower-case Linux account name."
  }
}

variable "ssh_public_keys" {
  description = "SSH public keys installed for guest_username; never provide private keys."
  type        = list(string)

  validation {
    condition = (
      length(var.ssh_public_keys) > 0 &&
      alltrue([for key in var.ssh_public_keys : length(trimspace(key)) > 0])
    )
    error_message = "ssh_public_keys must contain at least one non-empty public key."
  }
}

variable "qemu_guest_agent_enabled" {
  description = "Enable QEMU Guest Agent integration and IPv4 discovery only when the template installs and starts the agent."
  type        = bool
  default     = false
}

variable "vms" {
  description = "VMs keyed by stable Proxmox VM name. Disk sizes must not be smaller than the template root disk."
  type = map(object({
    cores     = number
    memory_mb = number
    disk_gb   = number
  }))

  validation {
    condition = alltrue([
      for name in keys(var.vms) :
      length(name) <= 63 && can(regex("^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$", name))
    ])
    error_message = "Each vms key must be a 1-63 character VM name using letters, digits, dots, or hyphens."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) :
      vm.cores >= 1 && floor(vm.cores) == vm.cores &&
      vm.memory_mb >= 512 && floor(vm.memory_mb) == vm.memory_mb &&
      vm.disk_gb >= 1 && floor(vm.disk_gb) == vm.disk_gb
    ])
    error_message = "Each VM needs integer cores >= 1, memory_mb >= 512, and disk_gb >= 1."
  }
}
