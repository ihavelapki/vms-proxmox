# Stage 0 decisions

**Status:** Awaiting owner review and approval.  
**Rule:** Only rows marked **APPROVED** are decisions. Recommended answers remain **PROPOSED** until the owner accepts or changes them.

## Already approved

| ID | Decision | Status | Source |
|---|---|---|---|
| A-01 | Target Proxmox VE with a simple, secure, documented Terraform VM builder | **APPROVED** | Stage 0 brief |
| A-02 | Stage 0 is documentation-only; implement no Terraform resources | **APPROVED** | Stage 0 brief |
| A-03 | Do not modify `rtl-vm` | **APPROVED** | Stage 0 brief |
| A-04 | Do not run apply, destroy, or destructive state operations | **APPROVED** | Stage 0 brief and `AGENTS.md` |
| A-05 | Obtain architecture approval before Stage 1 | **APPROVED** | Stage 0 brief and project skill |

## Architecture decisions requested

Please approve, amend, or reject each proposed answer. Values in angle brackets are intentionally unresolved.

### D-01 — PVE version and topology

- **UNKNOWN:** Exact PVE version, standalone versus cluster, node names, pools, and HA/migration expectations.
- **PROPOSED:** Require PVE 9.x for the initial supported baseline. Support one explicit target node per VM and no HA resources initially. If the actual environment is PVE 8.x, perform a compatibility spike with the pinned provider before any VM implementation.
- **Why:** Current `bpg/proxmox` targets and tests PVE 9.x; PVE 8.x support is limited.
- **Owner response:** `<approve/change and provide version, topology, nodes>`

### D-02 — Terraform provider and VM resource

- **OBSERVED:** `bpg/proxmox` 0.116.0 is current on 2026-10-12 and is pre-1.0.
- **PROPOSED:** At Stage 1, re-check current release notes and pin the reviewed release with a patch-compatible constraint (currently `~> 0.116.0`), then commit `.terraform.lock.hcl`. Use `proxmox_virtual_environment_vm` with `clone` because per-VM initialization and guest-agent settings are required. Do not use experimental `proxmox_cloned_vm` initially.
- **Owner response:** `<approve/change>`

### D-03 — Repository structure

- **PROPOSED:** Flat Terraform root module with one `for_each`; no local child module until another root configuration genuinely reuses the complete VM contract.
- **Owner response:** `<approve/change>`

### D-04 — Template ownership and provenance

- **UNKNOWN:** Existing template ID, node, OS, architecture, source, checksum/build record, guest-agent state, and owner.
- **PROPOSED:** Consume one externally managed, promoted, cloud-init-compatible template. The VM repository neither creates nor mutates it. Record immutable provenance and a tested update/promotion process.
- **Owner response:** `<approve/change and provide template details>`

### D-05 — Clone type

- **PROPOSED:** Full clones initially. Linked clones are out of scope until storage support, performance, template retention, migration, backup, and failure behavior are approved.
- **Owner response:** `<approve/change>`

### D-06 — Compute and CPU model

- **UNKNOWN:** Required CPU/RAM values, guest architecture, cluster CPU compatibility, and live-migration needs.
- **PROPOSED:** Preserve explicit cores and memory per VM; remove Yandex core fraction. Choose one documented Proxmox CPU type compatible with all intended nodes. Do not default to host passthrough before migration expectations are known.
- **Owner response:** `<approve/change and provide sizing/CPU policy>`

### D-07 — Node placement and VM IDs

- **PROPOSED:** Require explicit `node_name` per VM or one explicit common node for a standalone deployment. Let PVE allocate VM IDs unless the platform owner supplies a reserved range/convention. Map keys remain Terraform identities.
- **Owner response:** `<approve/change and provide node/VM-ID policy>`

### D-08 — Storage and root disk

- **UNKNOWN:** Datastore ID/type, local/shared scope, thin/discard support, free-space policy, migration, backup coverage, root size, and deletion behavior.
- **PROPOSED:** Consume an explicit datastore, use a full clone, set root size explicitly, and make all destroy-related arguments explicit. Treat root as disposable only if bootstrap is reproducible and backup/recovery requirements allow it.
- **Owner response:** `<approve/change and provide datastore/root policy>`

### D-09 — Additional data disk and `/opt`

- **UNKNOWN:** Whether `/opt` must exist, what data it holds, filesystem, size, mount owner, retention, backup, and recovery expectations.
- **PROPOSED:** Omit the data disk until Stage 4. If approved, add one explicitly managed disk, format only when blank, mount by filesystem UUID/label, and verify persistence after reboot. Define behavior for VM replacement, map-key removal, and full destroy separately.
- **Owner response:** `<approve/change and describe /opt requirement>`

### D-10 — Bridge, VLAN, and addressing

- **UNKNOWN:** Bridge, VLAN, MTU, DHCP, static allocation method, prefix, gateway, DNS servers, routes, and egress.
- **PROPOSED:** One VirtIO NIC on an existing bridge. Use DHCP for the first sandbox VM if reliable; otherwise use explicit static IPv4 via cloud-init. Keep IPv6 and multi-NIC out of scope initially.
- **Owner response:** `<approve/change and provide network contract>`

### D-11 — Management path and firewall ownership

- **UNKNOWN:** How operators reach private VMs, inbound/application ports, source networks, PVE firewall baseline, and guest firewall owner.
- **PROPOSED:** No public exposure. Use an existing private management path and approved public SSH keys. Do not manage firewall rules until ownership and port/source matrix are explicit.
- **Owner response:** `<approve/change and provide access/firewall details>`

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
- **PROPOSED:** Dedicated user plus privilege-separated token; narrow role and ACL paths derived from the final resource plan and tested in sandbox. Credentials only through approved environment/secret injection. API-only initially, no PVE node SSH. TLS verification required using a trusted CA.
- **Owner response:** `<approve/change and provide identity/PKI constraints>`

### D-16 — Terraform state

- **UNKNOWN:** Existing HTTP backend service, URL ownership, HTTPS trust, authentication, lock endpoints, backups/versioning, recovery, retention, and environment keys.
- **PROPOSED:** Reuse the existing HTTP backend only if all controls pass a documented test. Otherwise choose an organization-supported remote backend with locking. Keep backend infrastructure outside this state; treat state and plan artifacts as sensitive.
- **Owner response:** `<approve/change and provide backend details>`

### D-17 — Environment and recovery class

- **UNKNOWN:** Sandbox versus production, uptime, maintenance window, RPO/RTO, backup scope, monitoring, and restore-test frequency.
- **PROPOSED:** Implement and validate first in a disposable sandbox. The simple single-VM-per-role design is not presented as highly available. Production use requires explicit recovery and backup approval.
- **Owner response:** `<approve/change and provide service class/RPO/RTO>`

### D-18 — CI and change approvals

- **UNKNOWN:** CI platform, runner network access to PVE/backend, secret manager, protected environments, reviewers, and apply authority.
- **PROPOSED:** CI is a later stage. Start with formatting, backend-disabled init, validate, and a protected authenticated plan. Apply remains manual/protected and serialized per state; no stored token in the repository or long-lived plan artifacts.
- **Owner response:** `<approve/change and provide CI requirements>`

## Minimum information needed to start Stage 1

Stage 1 contains no VM resources, but still needs:

1. PVE version and endpoint/TLS trust approach.
2. Approved Terraform version and `bpg/proxmox` compatibility target.
3. Local authentication method for safe read-only provider checks.
4. State approach for later stages, even if Stage 1 validation initially uses `-backend=false`.
5. Confirmation of flat root structure and provider/resource choice.

## Additional information needed before the first VM stage

1. Node and template ID/provenance/guest-agent contract.
2. Root/cloud-init datastore ID and storage behavior.
3. Bridge, VLAN, DHCP/static network settings, gateway/DNS, and access path.
4. Approved guest user and SSH public keys.
5. VM naming, VM ID, CPU, RAM, root size, and deletion behavior.
6. Sandbox target and authorization for any authenticated plan or apply.

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
