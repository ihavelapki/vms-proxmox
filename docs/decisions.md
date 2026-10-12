# Current decisions

This page is the concise source of truth for owner-approved project decisions. Stage 0 documents preserve discovery and recommendations, but a recommendation is not approved unless recorded here or in a later explicit owner instruction.

## Approved

| ID | Decision | Status | Approver/source |
|---|---|---|---|
| C-01 | Target Proxmox VE 9.x | **APPROVED** | Owner; documentation reconciliation request |
| C-02 | Use one standalone Proxmox server; cluster and HA are not initial requirements | **APPROVED** | Owner; documentation reconciliation request |
| C-03 | Guest OS is Ubuntu Server 24.04 LTS | **APPROVED** | Owner; documentation reconciliation request |
| C-04 | No suitable cloud-init template exists; prepare it outside the Terraform VM stack | **APPROVED** | Owner; documentation reconciliation request |
| C-05 | Use existing `local-lvm` for VM disks, after verifying its actual ID and capabilities | **APPROVED** | Owner; documentation reconciliation request |
| C-06 | Proxmox administration is available through Web UI and SSH; this does not authorize Terraform provider SSH or host changes | **APPROVED** | Owner; documentation reconciliation request |
| C-07 | Use GitLab-managed Terraform state through the HTTP backend, pending endpoint/authentication/TLS/locking/recovery validation | **APPROVED** | Owner; documentation reconciliation request |
| C-08 | The first VM is a reusable development VM, not a disposable sandbox | **APPROVED** | Owner; documentation reconciliation request |

No approval date is recorded because the decisions were summarized from earlier ChatGPT discussion rather than tied to a reliably established original approval date.

## Proposed, not approved

- Flat root Terraform configuration with a small `vms` map and stable `for_each` keys.
- Reviewed and pinned `bpg/proxmox` provider.
- `proxmox_virtual_environment_vm` with a full clone.
- One private VirtIO NIC on an existing bridge.
- DHCP or static IPv4 after network discovery.
- Native cloud-init, SSH public keys, and QEMU Guest Agent when installed and running.
- Dedicated least-privilege API token and verified TLS.
- Proxmox-allocated VM IDs with an explicit node and datastore.
- DNS, additional `/opt` disk, CI, Terraform-managed firewall resources, and HA outside the initial scope.
- A separate disposable test VM for destructive lifecycle experiments.

## Unknowns blocking VM implementation

- Exact PVE patch version, node name, API endpoint, and certificate chain.
- Compatible Terraform and provider versions.
- Template ID, source/checksum, build process, and guest-agent state.
- Verified `local-lvm` capacity and relevant capabilities.
- Bridge/VLAN/addressing/DNS details and the guest SSH access route.
- VM sizing, CPU model, root size, name, guest username, and SSH public-key source.
- Replacement, deletion, protection, backup, and recovery policy.
- GitLab project/state/backend details, credentials, access controls, locking, and restore process.

See [current architecture](architecture.md) and the detailed [Stage 0 decision history](stage-0/decisions.md).
