resource "proxmox_virtual_environment_vm" "vm" {
  for_each = var.vms

  name        = each.key
  description = "Managed by Terraform in the vms-proxmox project."
  node_name   = var.node_name

  started = true
  on_boot = false

  # Preserve a reusable VM from unplanned downtime during ordinary updates.
  # An update that requires power-off fails until the operator stops the VM.
  reboot_after_update = false

  # Destroy still deletes the VM and its referenced disks. These settings avoid
  # force-stopping the guest and deleting unrelated disks or backup-job entries.
  stop_on_destroy                      = false
  purge_on_destroy                     = false
  delete_unreferenced_disks_on_destroy = false

  clone {
    vm_id        = var.template_vm_id
    datastore_id = var.datastore_id
    full         = true
  }

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory_mb
  }

  # The external template contract requires its root disk at scsi0. Resizing a
  # cloned disk can also normalize inherited disk attributes; review the first
  # authenticated plan against the template before any apply.
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = each.value.disk_gb
  }

  network_device {
    bridge  = var.network_bridge
    model   = "virtio"
    vlan_id = var.network_vlan_id
  }

  initialization {
    datastore_id = var.datastore_id
    interface    = "ide2"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = var.guest_username
      keys     = var.ssh_public_keys
    }
  }

  agent {
    enabled = var.qemu_guest_agent_enabled

    wait_for_ip {
      disabled = !var.qemu_guest_agent_enabled
      ipv4     = var.qemu_guest_agent_enabled
    }
  }

  operating_system {
    type = "l26"
  }
}
