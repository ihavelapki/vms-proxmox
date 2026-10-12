# Historical staged implementation reference

**Status:** Non-binding Stage 0 reference, reconciled with later owner decisions.  
**Task authority:** The project sequence and approval gates are decided in ChatGPT and supplied in each current Codex prompt. This document does not mandate the next task or authorize any operation.

## Classification

- **OBSERVED** — confirmed source or current documentation fact.
- **PROPOSED** — recommended future work; not approved.
- **UNKNOWN** — prerequisite not yet supplied.
- **APPROVED** — explicit Stage 0 constraint.

## Global gates

- **APPROVED:** No Terraform resources are implemented in Stage 0.
- **APPROVED:** Never run apply/destroy or destructive state commands without explicit approval.
- **APPROVED:** The first VM is a reusable development VM, not a disposable sandbox.
- **PROPOSED:** Use a separate disposable test VM if destructive lifecycle experiments are necessary.
- **PROPOSED:** A successful `validate` is not infrastructure evidence, and a successful plan is not a runtime test.
- **PROPOSED:** Re-check version-matched provider documentation before writing or changing resource schema.
- **PROPOSED:** Pause whenever a plan contains an unexplained delete, replacement, disk move/delete, node move, firewall exposure, credential value, or state migration.

The numbered stages below are possible increments only. A future prompt may combine, reorder, narrow, or omit them.

## Stage 0 — Discovery, architecture, security, and decisions

**State:** Completed as historical documentation; eight later owner decisions are now recorded in [decisions.md](decisions.md).

### Delivered

- Architecture and ownership boundary.
- Source-to-Proxmox migration mapping.
- Decision register with unresolved owner inputs.
- Security and lifecycle review.
- Staged implementation and validation plan.
- Skill audit against current provider behavior.

### Evidence

- Read `AGENTS.md` and the complete `proxmox-vms-development` skill.
- Read all 1,436 lines of `RTL_VM_ANALYSIS_FOR_AWS_SKILL.md`.
- Inspected every accessible project file in `rtl-vm`; made no source-repository changes.
- Reviewed current official/provider primary documentation for provider compatibility, VM clone resources, cloud-init, guest agent, storage lifecycle, authentication/ACLs, TLS, and HTTP state locking.
- Created documentation only; no Terraform command or live PVE operation was run.

### Current use

Use [current decisions](../decisions.md) as the concise source of truth. Resolve only the unknowns needed by the active prompt. Do not interpret this reference plan as approval.

## Stage 1 — Repository foundation and provider validation; no VMs

### Goal

Create a reproducible, secret-free Terraform skeleton and prove provider compatibility without managing infrastructure.

### Approved inputs required

- Exact PVE 9 patch version, node, endpoint, and trusted CA method.
- Supported Terraform version.
- Reviewed `bpg/proxmox` version.
- Local read-only authentication path.
- GitLab project/state/backend details and validation method.

### Proposed files

- `versions.tf`
- `providers.tf`
- `variables.tf`
- `outputs.tf` only if a useful nonsecret version/account-style check exists
- `.gitignore`
- `.terraform.lock.hcl`
- `terraform.tfvars.example`
- `README.md`
- `docs/architecture.md`
- `docs/terraform-basics.md`
- `docs/proxmox-basics.md`
- `docs/security.md`
- `docs/stages/stage-1.md`

Create only files with real content. No empty placeholder files.

### Proposed implementation

- Bound Terraform and `bpg/proxmox`; commit provider selection/checksums.
- Configure endpoint without credentials in HCL. Token comes from environment/secret injection.
- Keep TLS verification enabled.
- Add no managed resources and no node SSH block.
- Document provider versus resource versus data source, dependency lock file, local cache, state, and plan.

### Validation

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

If approved read-only credentials and connectivity are available, run only a harmless provider/version read or empty authenticated plan after separate authorization. Record command, redacted result, versions, and date. Do not call it tested if credentials/network were absent.

### Exit criteria

- No secrets in tracked files or plan output.
- TLS succeeds without insecure mode.
- PVE/provider/Terraform compatibility is evidenced.
- No managed resources appear.
- README explains safe init/validate workflow.

## Stage 2 — One reusable development VM

### Goal

Clone exactly one private, reusable development VM from the externally prepared Ubuntu 24.04 template and prove the end-to-end contract without treating the VM as disposable.

### Approved inputs required

- Standalone node, prepared template VM ID/node, full-clone decision.
- Verified `local-lvm` ID/capabilities for root and cloud-init disks.
- Bridge/VLAN and DHCP or static IPv4 configuration.
- VM ID policy, CPU, memory, root size, name.
- Guest user and approved SSH public key source.
- QEMU Guest Agent state.
- Lifecycle/deletion arguments and explicit apply authorization.

### Proposed implementation

- Flat `proxmox_virtual_environment_vm` with a one-entry `for_each` map.
- Full clone from external template.
- Explicit CPU, memory, target node/datastore, one VirtIO NIC, cloud-init network/user/key.
- Agent setting aligned with the tested template.
- Explicit `started`, `reboot_after_update`, `stop_on_destroy`, `purge_on_destroy`, and `delete_unreferenced_disks_on_destroy` decisions.
- No data disk, DNS, PVE firewall resources, snippets, app deployment, HA, or node SSH.

### Documentation

- Update README quick start and plan review.
- Add/update architecture, Proxmox basics, networking, security, operations, and Stage 2 report.
- Explain full clone, map identity, VM ID, agent/IP outputs, stop/reboot/replacement, and deletion.

### Static validation

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

### Authenticated validation

Only with explicit authorization for the development target and validated GitLab backend:

1. Initialize the approved backend.
2. Run `terraform plan` and save/protect the artifact only if policy permits.
3. Confirm exactly one VM clone and no network/storage/template infrastructure changes.
4. Review all stop/reboot/delete/protection arguments and disk actions.
5. Obtain separate approval for apply.
6. After apply, verify in PVE and guest: node, VM ID/name, full clone, CPU/RAM, disk/storage, NIC/bridge/VLAN, no unintended public path, cloud-init completion, unique machine/SSH identity, authorized keys, agent, correct IPv4, graceful shutdown/restart, and plan convergence.

Do not test deletion, replacement, state surgery, or disk-loss behavior on the reusable development VM. If such testing is required, authorize and use a separate disposable VM.

### Exit criteria

- A second plan is empty or every residual diff is explained.
- Access works only through the approved path.
- No secret appears in state-facing inputs or captured artifacts.
- Lifecycle/deletion behavior is understood before moving on.

## Stage 3 — Multiple VMs with stable `for_each` keys

### Goal

Generalize the proven one-VM configuration to the required small fleet without creating a framework.

### Approved inputs required

- Final map keys and naming compatibility.
- Per-VM node, VM ID policy, CPU, RAM, root size, and network allocation.
- Confirmation that adding the second VM must not replace the first.

### Proposed implementation

- Small `map(object(...))` with stable keys.
- Same resource pattern for all similar VMs.
- Concise output map with reliable, nonsecret values.
- No required duplicate `name` field; document key-rename risk.

### Validation

- Format/init/validate.
- Plan must add only the new VM and its clone/cloud-init artifacts; no first-VM replacement.
- With separately approved apply, verify both VMs, unique names/IDs/MACs/IPs/host keys, intended sizing, and converged plan.
- Exercise a non-destructive sizing plan and document whether it is hot-applied, rebooted, or blocked by policy; do not apply merely for the test without approval.

### Documentation

- Add/remove/change examples.
- Address tracing example such as `...vm["worker"]`.
- Naming and state-identity explanation.
- Stage 3 evidence report.

## Stage 4 — Additional data disk and verified `/opt` mount

### Goal

Add a data disk only if the workload needs it, with explicit retention and guest behavior.

### Approved inputs required

- Purpose/data classification, size, datastore, filesystem, mount point/options.
- Disk interface/controller and provider lifecycle semantics.
- Behavior on VM replacement, key removal, and stack destroy.
- Backup/RPO/RTO and recovery owner.

### Proposed implementation

- One explicitly declared data disk per approved VM; no arbitrary disk list initially.
- Use an idempotent bootstrap that detects an existing filesystem, formats only a proven blank disk, labels it, mounts by UUID/label, and persists it in `/etc/fstab`.
- Do not adopt the provider's experimental “disk holder VM” pattern without a separate data-loss review.
- Set unreferenced-disk deletion behavior explicitly.

### Validation

- Provider/schema review for the pinned version.
- Format/init/validate and exact disk-focused plan review.
- With explicit approval: verify block-device identity, filesystem, ownership/permissions, `findmnt`, reboot persistence, resize procedure, backup, and restore.
- Test destructive replacement/deletion behavior only on a separately authorized disposable VM with disposable data.

### Documentation

- Storage ownership, local/shared implications, mount workflow, resize, backup/restore, deletion matrix, and recovery runbook.
- Stage 4 evidence report.

## Stage 5 — Optional DNS, firewall, and advanced networking

### Goal

Add only requirements proven by operations; this stage may be skipped.

### Possible separately approved increments

- External DNS records for stable FQDN compatibility.
- VM-specific PVE firewall rules when ownership is assigned here.
- Static IPs if DHCP is unsuitable.
- VLAN, MTU, or multiple network segments when required.

### Guardrails

- Do not manage authoritative zones, bridges, VLAN creation, routing, DHCP, or cluster firewall baselines.
- Do not turn on the NIC firewall flag without a complete effective policy and recovery access.
- Do not add generic maps of arbitrary DNS/firewall/network rules.
- Treat DNS credentials/state as sensitive and use the actual DNS provider, not Proxmox.

### Validation

- Review exact records, ports, protocols, sources, destinations, and effective firewall layers.
- Verify DNS from intended resolver scopes.
- Prove management access and recovery console before/after firewall changes.
- Stage 5 evidence report for each selected increment.

## Stage 6 — GitLab state, optional CI, and operational hardening

This stage may be split: connect a required validated remote backend earlier, while full CI remains later.

### Goal

Provide safe collaboration, locking, reviewed delivery, recovery, and controlled upgrades.

### Approved inputs required

- GitLab project ID, state name, HTTP and lock endpoints, auth/TLS, access controls, backup/restore.
- CI product, runner network, secret injection, protected branches/environments, review and apply roles.

### Proposed implementation

- GitLab HTTP backend configuration without embedded credentials.
- CI: format, backend-disabled init/validate, protected authenticated plan, manual protected apply, serialized per state.
- Short artifact retention and restricted access.
- Provider/template upgrade procedure and drift schedule.
- Backup/restore and incident runbooks.

### Validation

- Backend TLS/auth test.
- Two-client lock contention test without infrastructure changes.
- State backup and restore exercise in a disposable key/environment.
- CI negative tests for untrusted branch/apply/token access.
- Review plan artifact redaction/permissions/retention.
- Stage 6 evidence report.

## Historical documentation suggestions

The current simplified skill does not require stage reports, long checklists, or implementation plans unless the active task asks for them. If a future prompt requests a stage report, useful evidence includes:

1. Scope, approved decisions, and non-goals.
2. Changed files and why each changed.
3. Terraform and Proxmox concepts introduced.
4. Resource ownership and create/update/reboot/replace/delete impact.
5. Security implications and credential/state handling.
6. Commands actually run, versions, redacted results, and date.
7. Checks not run and exact reason.
8. Runtime evidence, when an apply was separately approved.
9. Risks, limitations, rollback/recovery, and next-stage gate.

Always report checks as `PASSED`, `FAILED`, or `NOT RUN`; never use “tested” without command/runtime evidence.

## Reference plan-review checklist

For every authenticated plan:

- Correct endpoint, environment, node, template, datastore, bridge, VLAN, and VM IDs.
- Expected stable map keys and resource addresses.
- Exact create/update/reboot/replace/delete counts.
- No template, bridge, storage, cluster, DNS zone, or shared firewall mutation.
- No unexpected disk deletion, detach, move, shrink, or recreation.
- No unintended public exposure or new management route.
- No private key, password, API token, or application secret.
- Provider and lock-file versions match review.
- Backup/recovery prerequisites exist for any destructive action.

## Stage 0 change report

### Changed files

- `docs/stage-0/architecture.md`
- `docs/stage-0/migration-mapping.md`
- `docs/stage-0/decisions.md`
- `docs/stage-0/security-review.md`
- `docs/stage-0/implementation-plan.md`
- `docs/stage-0/skill-audit.md`

### Resource impact

- **OBSERVED:** Documentation only. No Terraform resources, state, PVE objects, original source files, or credentials were changed.

### Commands and checks

- **PASSED:** Source and target repository inventory/read checks.
- **PASSED:** Complete skill, source analysis, and source Terraform review.
- **PASSED:** Primary-documentation review as of 2026-10-12.
- **NOT RUN:** `git status`/`git diff`; the host's Git launcher reported that Xcode Command Line Tools are unavailable. File inventory checks were used instead.
- **NOT RUN:** `terraform fmt`, `init`, `validate`, and `plan` because Stage 0 contains no HCL and implementation is explicitly prohibited.
- **NOT RUN:** Live PVE/API/backend tests because environment decisions and credentials were not supplied or approved.
- **NOT RUN:** `apply`, `destroy`, or state mutations because prohibited.

### Remaining gate

The owner later approved PVE 9.x, a standalone server, Ubuntu 24.04, external template preparation, `local-lvm`, administrative Web UI/SSH access, GitLab-managed HTTP state, and a reusable first development VM. Remaining unknowns are tracked in [current decisions](../decisions.md). No later task is authorized by this plan alone.
