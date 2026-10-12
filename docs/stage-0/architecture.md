# Stage 0 architecture

**Status:** Historical Stage 0 analysis reconciled with later owner decisions; unresolved recommendations remain proposed.  
**Review date:** 2026-10-12.

For the concise current source of truth, see [`../architecture.md`](../architecture.md) and [`../decisions.md`](../decisions.md).

## Classification

- **OBSERVED** — supported by the inspected `rtl-vm` source, its analysis, or current primary documentation.
- **PROPOSED** — recommended target design; not approved yet.
- **UNKNOWN** — information that cannot safely be inferred and blocks some implementation.
- **APPROVED** — explicitly required by the project owner in the Stage 0 brief.

No architecture choice in this document is approved merely because it is recommended.

## Scope and evidence

**OBSERVED:** The complete project skill, `AGENTS.md`, all files in the accessible `rtl-vm` repository, and all 1,436 lines of `RTL_VM_ANALYSIS_FOR_AWS_SKILL.md` were reviewed. The source repository was read only.

**OBSERVED:** Current provider facts were checked against the provider's documentation and release history. As of 2026-10-12, the latest release is `bpg/proxmox` 0.116.0. The provider targets and acceptance-tests Proxmox VE (PVE) 9.x; PVE 8.x has limited support and PVE 7.x is unsupported. The provider is still pre-1.0, so minor releases can contain compatibility changes.

Primary references:

- [bpg/proxmox compatibility and security notes](https://github.com/bpg/terraform-provider-proxmox)
- [bpg/proxmox 0.116.0 release](https://github.com/bpg/terraform-provider-proxmox/releases/tag/v0.116.0)
- [VM resource](https://bpg.sh/docs/resources/virtual_environment_vm/)
- [Clone a VM](https://bpg.sh/docs/guides/clone-vm/)
- [Cloud-init guide](https://bpg.sh/docs/guides/cloud-init/)
- [VM lifecycle guide](https://bpg.sh/docs/guides/vm-lifecycle/)
- [Proxmox VE administration guide](https://pve.proxmox.com/pve-docs/pve-admin-guide.html)

## Approved project boundaries

- **APPROVED:** Build a simple, secure, well-documented Terraform VM builder for Proxmox VE.
- **APPROVED:** Stage 0 is documentation-only. Do not implement Terraform resources yet.
- **APPROVED:** Do not modify the original `rtl-vm` repository.
- **APPROVED:** Do not run `terraform apply`, `terraform destroy`, or destructive state operations.
- **APPROVED:** Stop after Stage 0 and obtain architecture approval before implementation.

## Owner-confirmed target context

- **APPROVED:** Proxmox VE 9.x on one standalone server; no initial cluster or HA requirement.
- **APPROVED:** Ubuntu Server 24.04 LTS guests.
- **APPROVED:** A suitable cloud-init VM template does not yet exist. It must be prepared outside this Terraform VM stack.
- **APPROVED:** VM disks use existing `local-lvm`, after verifying its actual ID, capacity, content types, and clone/disk capabilities.
- **APPROVED:** Administrators can use the Proxmox Web UI and SSH. This does not authorize Terraform provider SSH or host changes.
- **APPROVED:** Remote state uses GitLab-managed Terraform state via HTTP, pending endpoint, authentication, TLS, locking, access-control, and recovery validation.
- **APPROVED:** The first VM is a reusable development VM, not a disposable sandbox.

## Confirmed source-project facts

- **OBSERVED:** `rtl-vm` uses a `vms` map and `for_each`; the checked-in keys are `master` and `worker`.
- **OBSERVED:** Each entry creates an image-backed 20 GB root disk, a separate empty 30 GB disk intended by name for `/opt`, one VM, one private IPv4 NIC, and a DNS record in an existing zone.
- **OBSERVED:** The root project consumes an existing folder, subnet, DNS zone, and image family. It does not create shared network or DNS infrastructure.
- **OBSERVED:** Both disks are separate Terraform resources. `auto_delete = false` prevents deletion as a side effect of VM deletion in the compute API, but Terraform still owns and can destroy both disk resources.
- **OBSERVED:** CPU and RAM are explicit per VM, while `platform_id = "standard-v3"` and `preemptible = true` are hidden active child-module defaults.
- **OBSERVED:** VMs have no public address (`nat = false`) and IPv6 is disabled.
- **OBSERVED:** `ssh-keys.metadata`, `user-data.metadata`, and the provider credential file are absent. The contents and operational behavior of the metadata files cannot be inferred.
- **OBSERVED:** The second disk is not formatted or mounted by visible Terraform. The `/opt` behavior is unproven.
- **OBSERVED:** The empty `http` backend block proves intent to use remote HTTP state but does not prove endpoint, TLS, authentication, locking, backup, or access controls.
- **OBSERVED:** There is no provider lock file, CI configuration, test suite, or complete operating documentation.

## Proposed target architecture

```text
Operator or protected CI
  |
  +-- supplies PROXMOX_VE_ENDPOINT and a dedicated API token
  +-- trusts the PVE API certificate/issuing CA
  +-- initializes validated GitLab-managed Terraform HTTP state
  |
Terraform flat root module
  |
  +-- bpg/proxmox provider, reviewed bounded version, committed lock file
  |
  +-- proxmox_virtual_environment_vm.vm[stable map key]
        +-- full clone of an externally prepared Ubuntu 24.04 cloud-init template
        +-- explicit target node and optional approved VM ID
        +-- explicit CPU, RAM, root size, and target datastore
        +-- one VirtIO NIC on an existing bridge; optional VLAN tag
        +-- native cloud-init initialization
        |     +-- approved SSH public key(s)
        |     +-- DHCP or explicit static IPv4 settings
        |     +-- minimal guest initialization only
        +-- QEMU Guest Agent enabled only when installed and started in template
        +-- optional data disk added in a later stage after lifecycle approval
  |
  +-- concise nonsecret outputs
        +-- VM ID, name, node, MAC address
        +-- IP only when its source is reliable and documented

Existing platform dependencies, not managed here
  +-- standalone PVE host, local-lvm, bridges/VLANs, routing/DHCP/DNS
  +-- approved VM template library and its image-maintenance process
  +-- Proxmox firewall baseline and guest firewall policy
  +-- API user/token/ACLs and TLS PKI
  +-- GitLab-managed state service and credentials
  +-- backup/snapshot service and restore policy
```

### Terraform shape

- **PROPOSED:** Use a flat root module and one VM resource with `for_each`. A child module is unnecessary until the same complete VM contract is reused by another root configuration.
- **PROPOSED:** Keep `vms` as a small `map(object(...))`. The map key is the stable Terraform identity; do not duplicate it with a required `name` field. Renaming a key is a high-risk change that can propose replacement.
- **PROPOSED:** Keep shared settings—template VM ID, default datastore, bridge, optional VLAN, and addressing mode—explicit and small. Put per-VM placement and sizing in each map entry only when they genuinely vary.
- **PROPOSED:** Start with `proxmox_virtual_environment_vm` and a `clone` block because it supports clone plus per-VM `initialization` and `agent` settings. The newer `proxmox_cloned_vm` is currently experimental and cannot manage cloud-init initialization or QEMU Guest Agent configuration.
- **PROPOSED:** Before Stage 1, re-check the provider release notes and version-matched schema. If 0.116.0 remains the approved release, use a bounded constraint such as `~> 0.116.0` and commit `.terraform.lock.hcl`.
- **UNKNOWN:** The team's supported Terraform version. Select and bound it in Stage 1 only after checking provider requirements and the execution environment.

### Proxmox and VM placement

- **PROPOSED:** Treat nodes, clusters, pools, HA groups, and placement policy as external platform concerns. This repository selects an existing node; it does not configure the cluster.
- **APPROVED:** The initial target is one standalone PVE 9.x server; cluster and HA behavior are out of scope.
- **PROPOSED:** Pin each VM to the explicit standalone node and omit automatic placement or HA resources.
- **PROPOSED:** Let PVE allocate VM IDs unless the platform has an approved reserved range. If IDs must be explicit, put them in reviewed environment configuration and validate uniqueness operationally.
- **UNKNOWN:** Exact PVE patch version, node name, CPU model, maintenance expectations, pools, and reserved VM ID ranges.

### Template and clone model

- **APPROVED:** The guest OS is Ubuntu Server 24.04 LTS. A suitable cloud-init template does not exist yet and must be prepared outside this Terraform VM stack.
- **PROPOSED:** After external preparation, consume the approved template without building, downloading, mutating, or deleting it from this repository.
- **PROPOSED:** Use a full clone initially. It is easier to reason about and avoids a runtime dependency on the template's backing disks. Linked clones can be considered later only after storage capabilities, template retention, performance, backup, and migration behavior are documented.
- **PROPOSED:** The template contract must record: source image URL/vendor, immutable checksum or build reference, OS/version/architecture, update date, BIOS/machine type, boot disk/controller, cloud-init package and drive, QEMU Guest Agent installation/startup, default user, and cleanup steps such as machine-id and SSH host-key regeneration.
- **PROPOSED:** Never resolve an unchecked “latest” template inside the VM stack. Template promotion and patching belong to an external, reviewed image lifecycle.
- **UNKNOWN:** Future template ID/name, source image checksum, build process, architecture, guest-agent status, cloud-init behavior, and update owner.

### Storage

- **PROPOSED:** Consume existing datastore IDs. Do not create or reconfigure directory, LVM-thin, ZFS, Ceph, NFS, CIFS, or replication storage here.
- **APPROVED:** VM disk storage is the existing `local-lvm`.
- **PROPOSED:** Verify the actual storage ID and capabilities, then reference it explicitly for cloned root and cloud-init disks rather than relying on provider defaults.
- **PROPOSED:** Use a full clone. Do not treat the reusable development VM's root disk as disposable; retention, PVE protection, backup, and destroy behavior require explicit approval.
- **PROPOSED:** Defer the additional data disk until its purpose, filesystem, `/opt` mount, retention, backup, resize, replacement, and recovery contract is approved. A disk attachment does not create a filesystem or mount it.
- **OBSERVED:** The VM resource currently defaults `delete_unreferenced_disks_on_destroy = true`; this can delete disks attached outside Terraform. The final implementation must set and document this argument explicitly rather than inherit the default.
- **UNKNOWN:** Actual storage ID confirmation, content/clone support, available capacity, thin provisioning, discard, backup coverage, and deletion/retention requirements.

### Networking

- **PROPOSED:** Attach one VirtIO NIC to an existing bridge. Set VLAN ID only when the platform owner supplies it and confirms the bridge is VLAN-aware.
- **PROPOSED:** Preserve the private-only intent. Terraform will not create bridges, VLANs, DHCP, routing, NAT, VPN, authoritative DNS, or public exposure.
- **PROPOSED:** Prefer DHCP for the first development VM when the target segment has reliable DHCP and lease discovery. Otherwise use explicit static IPv4 address/prefix, gateway, and DNS servers through cloud-init. Do not implement both as a generic framework.
- **PROPOSED:** Make firewall ownership explicit. Enabling the NIC firewall flag alone does not create a safe policy. The initial VM stack should consume the existing approved firewall baseline; VM-specific rules are a later feature only if ownership is assigned here.
- **UNKNOWN:** Bridge, VLAN, MTU, DHCP, static address allocation, gateway, DNS, routes, management access path, egress, firewall ownership, and application port matrix.

### Cloud-init and guest access

- **PROPOSED:** Use native provider `initialization` for a minimal user, approved SSH public keys, and network configuration. This path avoids provider SSH access to PVE nodes.
- **PROPOSED:** Do not upload custom snippets until native initialization is proven insufficient. Snippet upload may require provider SSH access and a datastore with `snippets` content enabled, expanding privileges and operational surface.
- **PROPOSED:** Keep application deployment outside this repository. Cloud-init may establish access, hostname/networking, the QEMU Guest Agent, and an approved idempotent data-disk mount; it should not become a general configuration-management system.
- **PROPOSED:** Enable the provider's guest-agent setting only when the template starts `qemu-guest-agent`. When enabled, request IPv4 explicitly if outputs or readiness depend on it. A mismatched setting can cause long create/refresh/shutdown timeouts.
- **PROPOSED:** Use public keys only. Do not generate or store private keys or guest passwords in Terraform/state.
- **UNKNOWN:** Approved Linux user, SSH public keys and rotation owner, original user-data intent, package/egress needs, guest-agent readiness, and `/opt` behavior.

### Naming, identity, and outputs

- **PROPOSED:** Use the map key as the stable logical identity and derive one documented DNS-compatible VM name. Do not preserve the hidden special case in which `master` receives only `project_name` unless compatibility requires it.
- **PROPOSED:** Output only VM ID, name, node, and stable addresses that the provider can obtain reliably. QEMU Guest Agent is required for provider-reported IP addresses; static addresses may instead be returned from configuration.
- **PROPOSED:** DNS records are out of scope initially. If stable FQDNs are required, identify the external DNS provider and record owner in a later approved stage.
- **UNKNOWN:** Hostname/FQDN compatibility, DNS ownership, TTL, naming constraints, explicit VM IDs, and consumers of current outputs.

### API access and TLS

- **APPROVED:** Human Proxmox administration is available through the Web UI and SSH; this grants no provider SSH or host-change authority.
- **PROPOSED:** Use a dedicated PVE user and API token, delivered through `PROXMOX_VE_API_TOKEN`; supply the endpoint through `PROXMOX_VE_ENDPOINT`. Do not put the token in `.tf`, tracked `.tfvars`, CLI examples, or logs.
- **PROPOSED:** Keep token privilege separation enabled and grant both the user and token only the required ACLs on the narrowest practical VM, pool, datastore, and bridge paths. Validate the exact matrix against the selected PVE version and planned operations on an explicitly authorized test target.
- **PROPOSED:** Use API-only operations initially. Do not grant node SSH or sudo unless a later approved feature demonstrably needs it.
- **PROPOSED:** Verify TLS. Trust the internal CA or pinned issuing chain; never make `insecure = true` the project default.
- **UNKNOWN:** API endpoint, CA chain, token lifecycle/rotation, PVE realm, ACL layout, and whether PVE 9 privilege changes affect the chosen operations.

### Terraform state and delivery

- **APPROVED:** Use GitLab-managed Terraform state through the HTTP backend, pending validation.
- **PROPOSED:** Keep GitLab/backend configuration external to this state and use it only after HTTPS certificate validation, authentication, locking, access control, backup/versioning, and recovery checks pass.
- **PROPOSED:** Use local/backend-disabled initialization only for Stage 1 structural validation; it is not the production collaboration design.
- **PROPOSED:** Treat state and saved plans as sensitive. State is a resource mapping and attribute store, not a backup of VM disk data.
- **UNKNOWN:** GitLab project ID, state name, HTTP/lock endpoints, credentials, TLS, access controls, backup, retention, restore testing, environment separation, and approval workflow.

## Ownership boundary

| Concern | Proposed owner | Reason |
|---|---|---|
| VM clone, VM CPU/RAM, VM NIC attachment, cloud-init inputs | `proxmox-vms` | Direct purpose of this repository |
| Optional VM data disk | `proxmox-vms`, after approval | VM-scoped but deletion and guest-mount semantics must be explicit |
| PVE host/node configuration | Platform owner | High-blast-radius infrastructure; cluster/HA are not in initial scope |
| Datastores and replication | Storage/platform owner | Shared capacity, performance, and recovery policy |
| Bridges/VLANs/routes/DHCP | Network/platform owner | Shared network and access boundary |
| Proxmox firewall baseline | Security/platform owner unless delegated | A NIC flag alone is not a policy |
| Template build and promotion | Image/platform owner | Provenance and patch lifecycle are independent of VM instances |
| DNS zone | DNS owner | Proxmox does not provide authoritative DNS for this workflow |
| API identity, token, ACLs, TLS PKI | PVE/security owner | Privileged shared control plane |
| Remote-state service and CI federation | Platform/CI owner | Must exist independently from the state it stores |
| VM backups and restore testing | Backup/workload owner | Terraform state does not contain guest data |

## Explicit non-goals for the initial implementation

- Managing PVE nodes, cluster configuration, bridges, VLANs, storage, DNS zones, template creation, backup servers, or firewall baselines.
- Supporting every storage type, multiple NICs, arbitrary disks, PCI/USB passthrough, HA, live migration, linked clones, or public exposure.
- Recreating Yandex concepts mechanically, including folders, core fractions, preemptibility, image-family lookup, or NIC-integrated DNS.
- Uploading arbitrary cloud-init snippets, running provisioners, or deploying applications.
- Hiding destructive behavior with blanket `ignore_changes` or broad lifecycle rules.

## Architecture approval gate

This Stage 0 document is non-binding background. The project task sequence and authorization are decided in ChatGPT and supplied in each current Codex prompt. A future implementation prompt must resolve the unknowns needed for its scope; documentation alone does not authorize Terraform, template, host, GitLab, network, or state operations.
