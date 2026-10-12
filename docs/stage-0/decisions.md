# Stage 0 decisions

**Status:** Partially approved; unresolved implementation choices remain.  
**Rule:** Only rows marked **APPROVED** are decisions. Recommended answers remain **PROPOSED** until the owner accepts or changes them.

The concise current decision register is [`../decisions.md`](../decisions.md). This document preserves the more detailed Stage 0 discussion.

## Already approved

| ID | Decision | Status | Source |
|---|---|---|---|
| A-01 | Target Proxmox VE with a simple, secure, documented Terraform VM builder | **APPROVED** | Stage 0 brief |
| A-02 | Stage 0 is documentation-only; implement no Terraform resources | **APPROVED** | Stage 0 brief |
| A-03 | Do not modify `rtl-vm` | **APPROVED** | Stage 0 brief |
| A-04 | Do not run apply, destroy, or destructive state operations | **APPROVED** | Stage 0 brief and `AGENTS.md` |
| A-05 | Obtain architecture approval before Stage 1 | **APPROVED** | Stage 0 brief and project skill |

## Confirmed owner decisions

| ID | Decision | Status | Approver/source |
|---|---|---|---|
| O-01 | Target Proxmox VE 9.x | **APPROVED** | Owner; documentation reconciliation request |
| O-02 | Use one standalone Proxmox server; no initial cluster or HA requirement | **APPROVED** | Owner; documentation reconciliation request |
| O-03 | Guest OS is Ubuntu Server 24.04 LTS | **APPROVED** | Owner; documentation reconciliation request |
| O-04 | No suitable cloud-init template exists; prepare it outside the Terraform VM stack | **APPROVED** | Owner; documentation reconciliation request |
| O-05 | Use existing `local-lvm` for VM disks, subject to implementation-time ID/capability verification | **APPROVED** | Owner; documentation reconciliation request |
| O-06 | Administrators have Web UI and SSH access; this does not authorize provider SSH or host changes | **APPROVED** | Owner; documentation reconciliation request |
| O-07 | Use GitLab-managed Terraform state via HTTP, pending endpoint/auth/TLS/locking/recovery validation | **APPROVED** | Owner; documentation reconciliation request |
| O-08 | The first VM is a reusable development VM, not a disposable sandbox | **APPROVED** | Owner; documentation reconciliation request |

An approval date is intentionally omitted because the original decision dates from the earlier ChatGPT discussion were not reliably established.

## Architecture decisions requested

Please approve, amend, or reject each proposed answer. Values in angle brackets are intentionally unresolved.

### D-01 — PVE version and topology

- **APPROVED:** PVE 9.x on one standalone server; cluster and HA are not initial requirements.
- **UNKNOWN:** Exact PVE patch version, node name, and any pool convention.
- **PROPOSED:** Configure one explicit target node and omit cluster/HA resources.

### D-02 — Terraform provider and VM resource

- **OBSERVED:** `bpg/proxmox` 0.116.0 is current on 2026-10-12 and is pre-1.0.
- **PROPOSED:** When the provider foundation is implemented, re-check current release notes and pin the reviewed release with a patch-compatible constraint (historically `~> 0.116.0`), then commit `.terraform.lock.hcl`. Use `proxmox_virtual_environment_vm` with `clone` if version-matched documentation still supports the required per-VM initialization and guest-agent settings.
- **Owner response:** `<approve/change>`

### D-03 — Repository structure

- **PROPOSED:** Flat Terraform root module with one `for_each`; no local child module until another root configuration genuinely reuses the complete VM contract.
- **Owner response:** `<approve/change>`

### D-04 — Template ownership and provenance

- **APPROVED:** Guest OS is Ubuntu Server 24.04 LTS. No suitable cloud-init template currently exists; it must be prepared outside the Terraform VM stack.
- **UNKNOWN:** Future template ID, source image checksum, build process, architecture, cloud-init configuration, guest-agent state, and maintenance owner.
- **PROPOSED:** Consume one externally prepared, promoted template and record immutable provenance plus an update process.

### D-05 — Clone type

- **PROPOSED:** Full clones initially. Linked clones are out of scope until storage support, performance, template retention, migration, backup, and failure behavior are approved.
- **Owner response:** `<approve/change>`

### D-06 — Compute and CPU model

- **UNKNOWN:** Required CPU/RAM values, guest architecture, and CPU model.
- **PROPOSED:** Preserve explicit cores and memory per VM and remove Yandex core fraction. Select a documented CPU type suitable for the standalone server.
- **Owner response:** `<approve/change and provide sizing/CPU policy>`

### D-07 — Node placement and VM IDs

- **PROPOSED:** Require explicit `node_name` per VM or one explicit common node for a standalone deployment. Let PVE allocate VM IDs unless the platform owner supplies a reserved range/convention. Map keys remain Terraform identities.
- **Owner response:** `<approve/change and provide node/VM-ID policy>`

### D-08 — Storage and root disk

- **APPROVED:** Use the existing `local-lvm` storage for VM disks.
- **UNKNOWN:** Actual storage ID confirmation, available capacity, content/clone support, thin/discard behavior, backup coverage, root size, and deletion behavior.
- **PROPOSED:** Refer to the verified datastore explicitly, use a full clone, set root size explicitly, and make all destroy-related arguments visible. Do not assume the reusable development VM's root disk is disposable.

### D-09 — Additional data disk and `/opt`

- **UNKNOWN:** Whether `/opt` must exist, what data it holds, filesystem, size, mount owner, retention, backup, and recovery expectations.
- **PROPOSED:** Omit the data disk from the initial VM implementation. If later approved, add one explicitly managed disk, format only when blank, mount by filesystem UUID/label, and verify persistence after reboot. Define behavior for VM replacement, map-key removal, and full destroy separately.
- **Owner response:** `<approve/change and describe /opt requirement>`

### D-10 — Bridge, VLAN, and addressing

- **UNKNOWN:** Bridge, VLAN, MTU, DHCP, static allocation method, prefix, gateway, DNS servers, routes, and egress.
- **PROPOSED:** One VirtIO NIC on an existing bridge. Use DHCP for the first development VM if reliable; otherwise use explicit static IPv4 via cloud-init. Keep IPv6 and multi-NIC out of scope initially.
- **Owner response:** `<approve/change and provide network contract>`

### D-11 — Management path and firewall ownership

- **APPROVED:** Proxmox administrators can use the Web UI and SSH. This does not authorize Terraform provider SSH or changes to the host.
- **UNKNOWN:** How operators reach the guest VM, inbound/application ports, source networks, PVE firewall baseline, and guest firewall owner.
- **PROPOSED:** No public exposure. Use an existing private management path and approved public SSH keys. Do not manage firewall rules until ownership and port/source matrix are explicit.

### D-12 — Cloud-init and guest agent

- **UNKNOWN:** Approved guest user, SSH keys/rotation, original bootstrap intent, package egress, and template agent status.
- **PROPOSED:** Native provider initialization only: user, public keys, hostname/networking, and minimal approved setup. Require QEMU Guest Agent installed and started in the template before setting `agent.enabled = true`; then wait specifically for IPv4 if needed. Keep application deployment elsewhere.
- **Owner response:** `<approve/change and provide user/key/agent details>`

### D-13 — Naming and DNS

- **UNKNOWN:** Whether current hostnames/FQDNs and TTL 600 are compatibility requirements, and who owns DNS.
- **PROPOSED:** One DNS-compatible name derived from the stable map key; remove the `master` special case. Do not create DNS records initially. Add an external-DNS integration only after owner and zone are known.
- **Owner response:** `<approve/change and list compatibility requirements>`

### D-14 — VM lifecycle and deletion

- **UNKNOWN:** Required behavior on CPU/memory changes, template updates, node/storage changes, key removal, replacement, and destroy.
- **PROPOSED:** No silent replacement; require plan review for stop/reboot/replace/delete actions. Set `reboot_after_update`, `stop_on_destroy`, `purge_on_destroy`, `delete_unreferenced_disks_on_destroy`, and PVE protection deliberately. Do not rely on provider defaults.
- **Owner response:** `<approve/change and define root/data survival>`

### D-15 — API identity, ACL, and TLS

- **UNKNOWN:** PVE endpoint, realm, CA, ACL paths, token owner/expiry/rotation, and whether provider operations are API-only.
- **PROPOSED:** Dedicated user plus privilege-separated token; narrow role and ACL paths derived from the final resource plan and tested on an explicitly authorized target. Credentials only through approved environment/secret injection. API-only initially, no PVE node SSH. TLS verification required using a trusted CA.
- **Owner response:** `<approve/change and provide identity/PKI constraints>`

### D-16 — Terraform state

- **APPROVED:** Use GitLab-managed Terraform state through Terraform's HTTP backend, pending security and recovery validation.
- **UNKNOWN:** GitLab project ID, state name, HTTP/lock endpoints, credentials, HTTPS trust, access controls, backups/versioning, recovery, and retention.
- **PROPOSED:** Keep backend infrastructure and credentials outside this state, validate all unknown controls before use, and treat state and plans as sensitive.

### D-17 — Environment and recovery class

- **APPROVED:** The first VM is a reusable development VM, not a disposable sandbox.
- **UNKNOWN:** Uptime expectations, maintenance window, RPO/RTO, backup scope, monitoring, and restore-test frequency.
- **PROPOSED:** Use a separate disposable test VM for destructive lifecycle experiments. The development VM is not highly available, and its backup/recovery policy must be decided before risky operations.

### D-18 — CI and change approvals

- **UNKNOWN:** CI platform, runner network access to PVE/backend, secret manager, protected environments, reviewers, and apply authority.
- **PROPOSED:** Treat CI as optional later work. If requested, start with formatting, backend-disabled init, validate, and a protected authenticated plan. Apply remains manual/protected and serialized per state; no stored token in the repository or long-lived plan artifacts.
- **Owner response:** `<approve/change and provide CI requirements>`

## Information still needed for the first Terraform implementation

Stage 1 contains no VM resources, but still needs:

1. Exact PVE patch version, node name, endpoint, and TLS trust approach.
2. Approved Terraform version and `bpg/proxmox` compatibility target.
3. Local authentication method for safe read-only provider checks.
4. GitLab project/state/backend details and validation method, even if structural validation initially uses `-backend=false`.
5. Confirmation of flat root structure and provider/resource choice.

## Additional information needed before the first VM stage

1. Prepared Ubuntu 24.04 template ID/provenance/cloud-init/guest-agent contract.
2. Verified `local-lvm` ID, capacity, and relevant storage behavior.
3. Bridge, VLAN, DHCP/static network settings, gateway/DNS, and access path.
4. Approved guest user and SSH public keys.
5. VM naming, VM ID, CPU, RAM, root size, and deletion behavior.
6. Authorization for any authenticated plan or apply against the reusable development VM.

## Approval record

When decisions are made, update the relevant entry with:

```text
Status: APPROVED
Decision: <exact value/behavior>
Approved by: <name or role>
Approved on: YYYY-MM-DD
Evidence/constraints: <ticket, platform output, policy, or test result>
```

Do not replace unresolved values with plausible examples. Examples teach syntax; they do not constitute environment decisions.
