# VM lifecycle behavior

The first managed VM is reusable. Treat every plan that contains replacement or
deletion as potentially destructive to development data.

## Identity and replacement

- A `vms` map key is both the Terraform instance key and Proxmox VM name.
  Changing the key removes one resource address and creates another; it is not a
  safe rename operation.
- Removing a key schedules that VM for destruction.
- The VM ID is allocated by Proxmox and then stored in Terraform state. State
  loss or selecting the wrong empty backend can cause duplicate-create plans.
- Changing `template_vm_id` changes clone identity and should be treated as a
  replacement risk even if a provider version presents different plan details.
- Changing `node_name` on this standalone design is unsupported until the
  topology and provider behavior are reviewed.

## Updates

- CPU and memory changes may be hot-applied only when the inherited VM settings
  and guest support it.
- Root disk size can grow but cannot shrink. It must never be set below the
  template root size or current disk size.
- Root disk management can normalize inherited disk attributes. Compare cache,
  discard, format, I/O-thread, and controller settings in the first plan.
- Bridge or VLAN changes can disconnect the guest. DHCP address changes are
  external to Terraform.
- `reboot_after_update = false` means updates that require automatic shutdown or
  reboot fail. The operator must review the plan and deliberately stop/reboot
  the VM at an approved time.
- No `ignore_changes` masks drift. Out-of-band VM edits should appear in plans
  and must be reconciled intentionally.

## Start, stop, and guest agent

- `started = true` expresses a running desired state after creation.
- `on_boot = false` means PVE host boot does not automatically start these VMs.
- `stop_on_destroy = false` asks PVE for graceful shutdown rather than an
  immediate forced stop. If ACPI or the enabled guest agent is unhealthy,
  destruction can time out and must be investigated, not bypassed casually.
- Guest-agent integration is explicit. When disabled, refresh does not wait for
  an agent and IP output is unavailable. When enabled, a non-running agent can
  block refresh and lifecycle operations.

## Destruction semantics

Destroying the resource deletes the VM and referenced root/cloud-init disks.
The configured safeguards have narrower meanings:

- `delete_unreferenced_disks_on_destroy = false` leaves disks that are already
  unreferenced; it does not retain the VM's active root disk.
- `purge_on_destroy = false` avoids purging related backup-job configuration; it
  does not create or preserve backups.
- No Terraform `prevent_destroy` and no PVE `protection` flag is enabled.

Never use `terraform destroy`, remove/rename a key, or approve a replacement for
the reusable VM without explicit authorization, a reviewed plan, and a tested
backup/restore path. Do not use force-unlock or state-editing commands as a
shortcut around lifecycle errors.

## First authenticated plan review

Review at least:

1. the expected GitLab state and resource addresses;
2. exactly one intended create and no deletes/replacements for an initial VM;
3. source template ID, destination node, datastore, and allocated-ID behavior;
4. the complete `scsi0` and cloud-init disk diff;
5. bridge, VLAN, DHCP, MAC, and guest-agent behavior;
6. unexpected defaults, reboots, power changes, or inherited device removal;
7. the backup and recovery evidence for any existing reusable VM.

The initial implementation has not run an authenticated plan or apply.
