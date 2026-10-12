# Current decisions

This record separates owner-approved context, choices implemented by the current
task, and unresolved environment decisions. Implementation is not evidence that
an environment-specific value was approved.

## Owner-approved context

| ID | Decision | Status | Source |
|---|---|---|---|
| C-01 | Target Proxmox VE 9.x | **APPROVED** | Owner Stage 0 reconciliation |
| C-02 | Use one standalone server; no initial cluster or HA | **APPROVED** | Owner Stage 0 reconciliation |
| C-03 | Use Ubuntu Server 24.04 LTS guests | **APPROVED** | Owner Stage 0 reconciliation |
| C-04 | Prepare the missing cloud-init template outside the VM stack | **APPROVED** | Owner Stage 0 reconciliation |
| C-05 | Use existing `local-lvm` after verifying its real ID and capabilities | **APPROVED** | Owner Stage 0 reconciliation |
| C-06 | Human Web UI and SSH administration does not authorize provider SSH or host changes | **APPROVED** | Owner Stage 0 reconciliation |
| C-07 | Use GitLab-managed HTTP state after endpoint, auth, TLS, locking, and recovery validation | **APPROVED** | Owner Stage 0 reconciliation |
| C-08 | Treat the first VM as reusable development state | **APPROVED** | Owner Stage 0 reconciliation |

## Implemented design choices

The implementation task directed or authorized these choices. They can be
revisited in code review; they are not promoted to owner-approved facts.

| ID | Implemented choice | Rationale |
|---|---|---|
| I-01 | Flat root with `for_each` over a small `vms` map | Smallest readable multi-VM interface |
| I-02 | Terraform `>= 1.5, < 2.0` and `bpg/proxmox ~> 0.116.0` | Matches provider requirements and bounds a pre-1.0 minor |
| I-03 | `proxmox_virtual_environment_vm` full clone | Supports native initialization and agent settings; newer clone resource cannot manage both |
| I-04 | API-token environment authentication, verified TLS 1.3, no provider SSH | Removes credentials from code and avoids unnecessary host access |
| I-05 | PVE-allocated VM IDs; stable map keys supply VM names | Avoids inventing an ID range while retaining stable Terraform addresses |
| I-06 | One VirtIO NIC, DHCP-only IPv4, optional shared VLAN | Minimal initial network surface |
| I-07 | Native cloud-init username and public keys; no passwords, private keys, snippets, or provisioners | Minimal secret exposure and guest bootstrap scope |
| I-08 | Guest Agent opt-in and disabled by default | Avoids inherited-agent waits until the template is proven compatible |
| I-09 | Automatic update reboots off; PVE host autostart off | Protects a reusable development VM from surprise downtime |
| I-10 | No lifecycle ignore or prevent-destroy rule | Keeps drift and destructive plans visible; relies on review and backups |
| I-11 | Partial HTTP backend configured externally | Keeps GitLab endpoints and credentials out of source |

## Required decisions before an authenticated plan

| ID | Unknown or approval needed | Evidence required |
|---|---|---|
| D-01 | Exact PVE patch version, node name, API endpoint, and CA chain | PVE inventory and verified TLS connection |
| D-02 | Template VM ID and completed template contract, including disabled `ciupgrade` | Recorded image origin/checksum, config, test clone, and cloud-init result |
| D-03 | Actual datastore ID and clone/disk/cloud-init support | PVE storage inventory and capacity check |
| D-04 | Bridge, DHCP scope, optional VLAN, routing, and SSH path | Network-owner confirmation and disposable connectivity test |
| D-05 | First VM name, CPU, RAM, disk size, guest username, and approved public keys | Owner-approved local `terraform.tfvars` values |
| D-06 | Whether QEMU Guest Agent is installed and enabled in the template | Successful guest-agent status and IP-reporting test |
| D-07 | Dedicated API principal, token separation, and least-privilege ACLs | PVE 9 permission test for read, clone, configure, start, stop, and delete paths |
| D-08 | GitLab project, state name, endpoint, credential type, access roles, locking, and recovery | Isolated backend test and documented restore exercise |
| D-09 | Backup/restore, deletion, replacement, and optional VM-protection policy | Owner approval and recoverability evidence for reusable VM data |
| D-10 | Acceptability of cloned `scsi0` normalization shown by the first plan | Template config comparison and reviewed authenticated plan |

An authenticated plan can itself supply evidence for D-10, but it must not be
applied until all destructive effects and the backup/recovery posture are
approved. Static validation does not resolve any of these environment decisions.
