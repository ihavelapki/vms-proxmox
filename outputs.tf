output "managed_vms" {
  description = "Managed VM identity and guest-agent IPv4 data when agent integration is enabled."
  value = {
    for name, vm in proxmox_virtual_environment_vm.vm : name => {
      id             = vm.vm_id
      name           = vm.name
      node           = vm.node_name
      ipv4_addresses = var.qemu_guest_agent_enabled ? vm.ipv4_addresses : null
    }
  }
}
