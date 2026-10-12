# Current architecture

This page is the concise source of truth for the current `vms-proxmox` architecture. Detailed discovery and historical recommendations remain under [`docs/stage-0/`](stage-0/architecture.md); they are background, not automatic approvals.

## Approved context

- **APPROVED:** The target is Proxmox VE 9.x on one standalone Proxmox server. Cluster placement and HA are not requirements for the initial project.
- **APPROVED:** Guest VMs use Ubuntu Server 24.04 LTS.
- **APPROVED:** No suitable cloud-init VM template exists yet. It must be prepared before a VM can be cloned, but template creation remains outside this Terraform VM stack.
- **APPROVED:** VM disks use the existing `local-lvm` storage, subject to verifying its actual storage ID, capacity, content types, and clone/disk capabilities before implementation.
- **APPROVED:** Proxmox administrators can use the Web UI and SSH. This does not authorize Terraform provider SSH or host changes.
- **APPROVED:** Remote state will use GitLab-managed Terraform state through Terraform's HTTP backend, after endpoint, authentication, TLS, locking, access-control, and recovery validation.
- **APPROVED:** The first managed VM is a reusable development VM, not a disposable sandbox.

## Proposed VM-stack design

The following remains **PROPOSED**, not owner-approved architecture:

```text
Operator
  |
  +-- verified HTTPS to the PVE 9.x API
  +-- dedicated API token (proposed)
  +-- validated GitLab-managed HTTP state
  |
Terraform VM stack
  |
  +-- reviewed, pinned bpg/proxmox provider
  +-- small vms map with stable for_each keys
  +-- VM clone on the one standalone node
        +-- full clone from an external Ubuntu 24.04 cloud-init template
        +-- root/cloud-init disks on verified local-lvm
        +-- one private VirtIO NIC on an existing bridge
        +-- native cloud-init with approved SSH public keys
        +-- QEMU Guest Agent only when installed and running

External ownership
  +-- PVE host configuration and administration
  +-- template preparation and maintenance
  +-- local-lvm configuration
  +-- bridge, VLAN, DHCP, routing, DNS, and shared firewall policy
  +-- GitLab state service and credentials
  +-- VM backup and restore policy
```

Proposed implementation choices:

- Flat root Terraform configuration with a small `vms` map and stable `for_each` keys.
- A version-compatible, bounded `bpg/proxmox` provider and committed dependency lock file.
- `proxmox_virtual_environment_vm` with a full clone, subject to version-matched provider verification.
- An explicit node and datastore, with VM IDs allocated by Proxmox unless a different policy is approved.
- One private VirtIO NIC; DHCP or static IPv4 will be selected after network discovery.
- Native cloud-init, approved SSH public keys, and API-only provider operations.
- A dedicated least-privilege API token and verified TLS.
- DNS, an additional `/opt` disk, Terraform-managed firewall rules, CI, cluster features, and HA remain outside the initial scope.

## Ownership boundaries

Terraform is intended to manage VM-scoped configuration only. It must not create or modify the Proxmox host, `local-lvm`, bridges/VLANs, the template library, GitLab, or shared security policy unless a later owner decision explicitly changes that boundary.

The external Ubuntu template must have documented provenance and a verified cloud-init/guest-agent contract. Administrative SSH to the Proxmox host is for authorized human administration; it is not a Terraform transport by default.

Because the first VM is reusable, its replacement or deletion may destroy useful development state. Destructive lifecycle experiments must use a separately authorized disposable test VM.

## Unresolved implementation inputs

- Exact PVE 9 patch version, node name, API hostname/port, and certificate chain.
- Terraform and `bpg/proxmox` version compatibility.
- Template ID, source checksum, build procedure, cloud-init configuration, and QEMU Guest Agent status.
- Verified `local-lvm` storage ID, capacity, content support, and lifecycle behavior.
- Bridge, VLAN, DHCP availability, subnet, gateway, DNS, and guest SSH route.
- Initial VM CPU, RAM, root size, CPU model, name, and guest username.
- Approved SSH public-key source and rotation owner.
- VM replacement/deletion/protection policy and backup/recovery requirements.
- GitLab project ID, state name, backend endpoints, credentials, permissions, locking, and restore procedure.

These values must be discovered or approved in the prompt that authorizes the corresponding implementation. They must not be guessed.

## Safety boundary

No prompt or document implicitly authorizes `terraform apply`, `terraform destroy`, state changes, template preparation, Proxmox host changes, GitLab configuration, or network changes. Each task is authorized separately in the current Codex prompt.

See [current decisions](decisions.md) and the [Stage 0 architecture background](stage-0/architecture.md).
