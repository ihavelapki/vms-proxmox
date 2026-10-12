# Current architecture

This page is the source of truth for the implemented VM builder. Stage 0 files
under [`docs/stage-0/`](stage-0/architecture.md) preserve analysis and are not
runtime instructions or automatic approvals.

## Confirmed owner context

- The target is one standalone Proxmox VE 9.x server; cluster placement and HA
  are outside the initial scope.
- Guests use Ubuntu Server 24.04 LTS.
- The cloud-init template is prepared and maintained outside this Terraform
  stack because no suitable template currently exists.
- VM disks use the existing `local-lvm`, after its ID and capabilities are
  verified.
- GitLab-managed Terraform state is the selected remote-state service, subject
  to endpoint, authentication, TLS, locking, access, and recovery validation.
- The first VM is a reusable development VM, not a disposable test VM.

## Implemented design

These choices were authorized by the implementation task. They are implemented
design choices, not additional owner-approved environment facts.

```text
Operator / automation
  |-- Terraform 1.5+ with GitLab HTTP state
  |-- PROXMOX_VE_ENDPOINT + PROXMOX_VE_API_TOKEN
  `-- verified TLS 1.3 to the Proxmox API
            |
            v
Flat Terraform root using bpg/proxmox ~> 0.116.0
  `-- proxmox_virtual_environment_vm.vm[stable-map-key]
        |-- full clone from external template
        |-- Proxmox-allocated VM ID
        |-- requested cores, dedicated RAM, and scsi0 size
        |-- one VirtIO NIC; DHCP; optional VLAN
        |-- native cloud-init on ide2
        |     `-- username + supplied SSH public keys
        `-- QEMU Guest Agent explicitly off by default
```

The root is intentionally flat: `versions.tf`, `providers.tf`, `variables.tf`,
`main.tf`, and `outputs.tf`. VM names are the `vms` map keys, so callers must keep
keys stable. Shared infrastructure is passed as a small set of variables.

The HTTP backend is partial (`backend "http" {}`); its address, locking methods,
and credentials are supplied externally. The provider has no SSH block, uses an
API token from the environment, enforces certificate verification, and requires
TLS 1.3.

## Ownership boundary

Terraform manages only the VMs and their declared VM-scoped configuration. The
following remain external:

- PVE installation, node configuration, accounts, roles, ACLs, and certificates;
- template image provenance, preparation, updates, and retirement;
- datastore configuration and capacity management;
- bridges, VLANs, DHCP, routing, DNS, firewall policy, and guest reachability;
- GitLab project, state service, credentials, access control, and recovery;
- backup, restore, monitoring, and software installed after first boot.

Provider SSH, custom cloud-init snippets, generated credentials, guest
provisioners, additional data disks, DNS records, firewall resources, CI, HA,
and cluster features are not part of this initial builder.

## Template and clone contract

The source must be an Ubuntu 24.04 cloud-init template on the selected node. Its
root disk must be `scsi0`, its cloud-init disk must use `ide2`, and the requested
root size must be at least the template size. The template's inherited disk
attributes need to match the reviewed provider behavior because resizing a
cloned disk can normalize attributes not repeated in Terraform. See
[template prerequisites](template-prerequisites.md).

The template must also have PVE cloud-init package upgrades disabled. Terraform
does not declare `initialization.upgrade` because PVE restricts that setting to
`root@pam`, which would conflict with the dedicated non-root API-token design.

QEMU Guest Agent support is opt-in. It may be enabled only when the template
installs the package and the service reliably starts. With it disabled, the
provider skips its IP wait and the output intentionally omits IP information.

## Lifecycle posture

VMs start after creation but do not start automatically with the PVE host.
Automatic reboot or power-off for configuration updates is disabled. Destroy
requests a graceful shutdown and deletes the VM and its referenced disks, while
leaving unreferenced disks and backup-job entries alone.

No `ignore_changes`, `prevent_destroy`, or PVE protection flag hides drift or
blocks replacement. This makes plan output honest, but means backups and review
are mandatory for the reusable VM. See [lifecycle behavior](lifecycle.md).

## Runtime unknowns and approvals

Configuration generation is complete, but real planning or creation still
depends on the environment facts and owner decisions listed in
[decisions.md](decisions.md). In particular, no template ID, node name, bridge,
VLAN, public key, token ACL, backend endpoint, or state name has been approved
or invented by this implementation.

## Safety boundary

This implementation does not authorize `terraform apply`, `terraform destroy`,
state migration, import, force-unlock, template preparation, Proxmox host
changes, GitLab configuration, or network changes. A later task must explicitly
authorize any such operation.
