# vms-proxmox

A small Terraform root configuration that creates Proxmox VE 9.x virtual
machines as full clones of an externally maintained Ubuntu Server 24.04
cloud-init template.

The stack manages VM-scoped settings only. It does not build templates, change
the Proxmox host, create storage or bridges, configure GitLab, install software
inside guests, or manage backups.

## Architecture

`proxmox_virtual_environment_vm.vm` uses stable keys from `var.vms` as both the
Terraform instance key and VM name. Every VM gets:

- a full clone on one explicitly selected node and datastore;
- per-VM CPU, memory, and root disk size;
- one VirtIO NIC using IPv4 DHCP and an optional VLAN tag;
- native Proxmox cloud-init with a Linux username and SSH public keys; and
- optional QEMU Guest Agent integration, disabled by default.

The provider uses only the Proxmox HTTPS API. Provider SSH and custom cloud-init
snippets are deliberately absent. See [the current architecture](docs/architecture.md)
and [the decision record](docs/decisions.md).

## Requirements

- Proxmox VE 9.x on the approved standalone server.
- Terraform `>= 1.5.0, < 2.0.0`.
- `bpg/proxmox` `~> 0.116.0` (PVE 9.x target; the 0.x minor is intentionally
  bounded).
- A trusted certificate chain for the Proxmox API, with TLS 1.3 available.
- An existing datastore (currently expected to be `local-lvm`) verified for VM
  images, free capacity, full cloning, and cloud-init disks.
- An existing bridge with IPv4 DHCP; if a VLAN is set, the bridge and upstream
  network must carry that VLAN.
- A prepared external Ubuntu 24.04 template satisfying
  [the template contract](docs/template-prerequisites.md).
- A dedicated API token with only the ACLs validated for this stack; see
  [security](docs/security.md).
- A validated GitLab-managed HTTP state endpoint; see
  [remote state](docs/gitlab-state.md).

The actual node, template, storage, bridge, VLAN, DHCP path, token ACLs,
certificate chain, backup policy, and GitLab state settings must be verified
before an authenticated plan or apply.

## Provider authentication

Keep connection details and credentials out of Terraform files and shell
history where practical. Export them through the operator's secret-management
workflow:

```sh
export PROXMOX_VE_ENDPOINT="https://<pve-api-host>:8006/"
export PROXMOX_VE_API_TOKEN="<user>@<realm>!<token-id>=<token-secret>"
```

TLS certificate verification is explicitly enabled and the provider minimum is
TLS 1.3. Do not set `PROXMOX_VE_INSECURE=true`. The endpoint must not include
`/api2/json`.

No username, password, API token, private SSH key, or backend credential belongs
in `*.tf`, `*.tfvars`, a saved plan, or version control.

## Inputs and example

Copy the tracked example to the ignored local variable file, then replace every
placeholder with discovered values:

```sh
cp terraform.tfvars.example terraform.tfvars
```

The main inputs are:

| Input | Meaning |
|---|---|
| `node_name` | Existing standalone PVE node |
| `template_vm_id` | External Ubuntu 24.04 template VM ID |
| `datastore_id` | Full-clone, root-disk, and cloud-init datastore; defaults to `local-lvm` |
| `network_bridge` | Existing bridge with IPv4 DHCP |
| `network_vlan_id` | Optional VLAN tag; defaults to untagged |
| `guest_username` | Cloud-init Linux username; defaults to `ubuntu` |
| `ssh_public_keys` | One or more public keys; private keys are forbidden |
| `qemu_guest_agent_enabled` | Opt in only after template agent validation |
| `vms` | Stable VM names mapped to cores, memory MB, and root disk GB |

`terraform.tfvars.example` contains one reusable development VM and a commented
second example. Its node, bridge, template ID, and SSH key are placeholders, not
environment facts. The initial implementation supports DHCP only; static IPv4
can be designed later after the network inputs are approved.

## Safe validation and operation

Static checks do not contact Proxmox or GitLab:

```sh
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

`init -backend=false` downloads the pinned provider and validates its schema
without configuring or reading remote state. It can update the dependency lock
file but does not create infrastructure.

Before any authenticated plan:

1. Verify every prerequisite and replace every placeholder.
2. Validate the template contract, datastore, bridge/VLAN, DHCP, API token ACLs,
   TLS chain, and guest-agent setting.
3. Configure and test the GitLab HTTP backend, including locking and recovery,
   then run a normal `terraform init`.
4. Confirm that the selected state is the intended state and is not empty due
   to an endpoint or credential mistake.

An authenticated `terraform plan` reads real state and Proxmox configuration;
review it for replacement, deletion, inherited disk normalization, network
changes, and unexpected provider defaults. Run `terraform apply` only after the
plan, backup/recovery readiness, and destructive effects have been explicitly
approved. This repository's implementation and validation do not authorize an
apply or destroy.

## Lifecycle warnings

The first VM is reusable and may contain valuable development data. Removing a
map key, changing its key, changing clone identity, or running destroy can delete
the VM and its referenced root disk. `delete_unreferenced_disks_on_destroy =
false` protects only unreferenced disks; it is not VM retention or backup.

Automatic reboot/power-off during updates is disabled. Updates that need the VM
offline fail until an operator intentionally stops it. VM protection is not
enabled, and no lifecycle ignore rules hide drift. Read the full
[lifecycle contract](docs/lifecycle.md) before planning against Proxmox.

## Outputs

`managed_vms` returns each managed VM's ID, name, and node. IPv4 address lists
are returned only when guest-agent integration is enabled; otherwise the field
is `null`. DHCP leases are not discoverable reliably through this provider when
the guest agent is disabled.

## Documentation

- [Current architecture](docs/architecture.md)
- [Current decisions and unresolved approvals](docs/decisions.md)
- [External template contract](docs/template-prerequisites.md)
- [GitLab HTTP state](docs/gitlab-state.md)
- [Security and API permissions](docs/security.md)
- [VM lifecycle behavior](docs/lifecycle.md)
- [Stage 0 analysis](docs/stage-0/architecture.md)

Official references: [provider configuration](https://bpg.sh/docs/),
[VM resource](https://bpg.sh/docs/resources/virtual_environment_vm/),
[HTTP backend](https://developer.hashicorp.com/terraform/language/backend/http),
and [GitLab-managed state](https://docs.gitlab.com/user/infrastructure/iac/terraform_state/).
