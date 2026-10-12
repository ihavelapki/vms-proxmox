# Security and API permissions

## Credential and transport rules

- Use a dedicated Proxmox automation user and API token, not `root@pam` and not
  a human user's token.
- Supply the endpoint and token only through `PROXMOX_VE_ENDPOINT` and
  `PROXMOX_VE_API_TOKEN`.
- Keep token privilege separation enabled unless a documented PVE 9 limitation
  proves a narrower alternative impossible. ACLs must apply to the token as well
  as its owning user.
- Keep TLS verification enabled. Trust the PVE certificate chain on the runner;
  do not use `insecure` or `PROXMOX_VE_INSECURE=true`.
- Do not configure provider SSH. The selected VM clone, native cloud-init, and
  API operations do not require it.
- Store only SSH public keys. Passwords and private keys are outside the stack.
- Treat state and saved plans as sensitive even though this configuration does
  not intentionally write provider or backend tokens into state.

## Candidate least-privilege operations

The final PVE 9 role must be derived and tested against the actual ACL paths.
Do not copy the provider's broad example role. For this resource, expect to need
the narrow PVE equivalents of:

- audit/read access for the node, source template, target VMs, datastore, and
  selected bridge;
- VM allocation and cloning from the approved template;
- VM CPU, memory, disk, network, cloud-init, hardware/options, and power
  management for managed VM IDs;
- datastore audit and allocation on only the approved datastore; and
- the PVE 9 `SDN.Audit` or `SDN.Use` access needed to see only the selected
  local-network bridge.

Likely privilege names include `Sys.Audit`, `VM.Audit`, `VM.Allocate`,
`VM.Clone`, `VM.Config.CPU`, `VM.Config.Memory`, `VM.Config.Disk`,
`VM.Config.Network`, `VM.Config.Cloudinit`, `VM.Config.HWType`,
`VM.Config.Options`, `VM.Config.CDROM`, `VM.PowerMgmt`,
`VM.GuestAgent.Audit` when agent output is enabled, `Datastore.Audit`,
`Datastore.AllocateSpace`, and scoped `SDN.Audit`/`SDN.Use`. This is a candidate
set, not a ready-to-run role definition. PVE permission checks can vary by
operation and inherited template settings.

Do not explicitly manage cloud-init `upgrade` with this token: PVE restricts
`ciupgrade` changes to `root@pam`. The external template must carry the approved
disabled value so first boot does not perform an unreviewed package upgrade.

Test the token against a separately authorized disposable VM for read, full
clone, configure, start, graceful shutdown, and delete. Record every required
ACL path and remove any privilege not exercised. Do not grant realm, user,
permission, host-modification, backup, snapshot, migration, HA, or cluster-wide
administration privileges merely to make an error disappear.

## Security boundaries and residual risks

- A token able to clone and delete VMs is materially privileged; rotate and
  revoke it through the external secret-management process.
- The provider's version is bounded because pre-1.0 minor releases can include
  breaking behavior. Review release notes before changing the constraint and
  commit the resulting lock-file update.
- Terraform state access can disclose VM inventory, public keys, and other
  provider-returned metadata. GitLab access and backups require the same care as
  infrastructure administration.
- Cloud-init public keys do not establish authorization ownership or rotation;
  both remain owner decisions.
- PVE VM protection and Terraform `prevent_destroy` are not enabled. Neither
  would replace verified backups in any case.

Reference: [provider authentication and PVE 9 permission notes](https://bpg.sh/docs/).
