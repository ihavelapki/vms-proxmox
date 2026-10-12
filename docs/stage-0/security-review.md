# Stage 0 security review

**Status:** Proposed security baseline; control owners and environment values are unresolved.  
**Scope:** Terraform-to-PVE control plane, VM bootstrap, networking, storage, state, and operations.

Owner-confirmed context affecting this review:

- **APPROVED:** The first VM is a reusable development VM, not disposable test infrastructure.
- **APPROVED:** GitLab-managed Terraform state is the selected HTTP backend, pending validation of its concrete configuration and controls.
- **APPROVED:** Administrators can access Proxmox through the Web UI and SSH. This does not authorize Terraform provider SSH or host changes.
- **APPROVED:** The Ubuntu 24.04 cloud-init template must be prepared outside the Terraform VM stack.

## Classification

- **OBSERVED** — confirmed from inspected source or current primary documentation.
- **PROPOSED** — recommended control; not yet approved.
- **UNKNOWN** — missing fact or owner decision.
- **APPROVED** — explicit project constraint.

## Security objectives

- Prevent unauthorized control of PVE and managed VMs.
- Prevent secrets from entering Git, Terraform configuration, state, plans, or logs.
- Prevent accidental VM/disk deletion or unreviewed replacement.
- Preserve verified TLS and a private management path.
- Limit Terraform ownership to VM-scoped resources.
- Make backups, recovery, and state protection explicit instead of implied.

## Risk summary

| Priority | Finding | Evidence | Proposed control | Status |
|---|---|---|---|---|
| MUST | Provider credential exposure | **OBSERVED:** `rtl-vm` reads a local JSON credential file not explicitly ignored | Dedicated PVE API token supplied by environment/secret manager; no token in files, tfvars, commands, or logs | **PROPOSED** |
| MUST | TLS bypass risk | Provider supports `insecure`; internal PVE deployments often use private CAs | Trust the issuing CA and leave verification enabled; reject `insecure = true` as a project default | **PROPOSED** |
| MUST | Excessive PVE privilege | Provider docs' sample role is explicitly likely too permissive and privileges changed in PVE 9 | Derive an operation-specific role and narrow ACL paths; keep token privilege separation; prove on an authorized test target | **PROPOSED** |
| MUST | Disk loss on destroy | VM resource currently defaults `delete_unreferenced_disks_on_destroy = true`; Terraform-owned disks are deleted with resource destruction unless designed otherwise | Set lifecycle arguments explicitly, review every destructive plan, keep backups separate, document three deletion boundaries | **PROPOSED** |
| MUST | Unknown bootstrap content | **OBSERVED:** Original SSH and user-data files are missing | Recover intent; version only nonsecret minimal cloud-init; no private keys/passwords/application secrets | **PROPOSED** |
| MUST | Sensitive state and plans | Provider arguments, cloud-init, resource data, and credentials can be captured depending on configuration/workflow | Validate GitLab-managed HTTP state for TLS, authentication, locking, access, retention and recovery; keep secrets out of Terraform values | **PROPOSED** |
| MUST | Network exposure/ownership gap | **OBSERVED:** Original used external/default controls; Proxmox bridge/firewall is external | Private network only; name firewall owner and port/source matrix before managing exposure | **PROPOSED** |
| MUST | Template supply chain not established | **APPROVED:** No suitable template exists yet | Prepare the Ubuntu 24.04 template externally with immutable provenance, patch owner, promotion and retirement process | **PROPOSED** |
| MUST | Useful development data lost during lifecycle tests | **APPROVED:** The first VM is reusable, not disposable | Do not perform destructive experiments on it; authorize a separate disposable VM and define backup/recovery first | **PROPOSED** |
| SHOULD | Guest-agent mismatch | Provider waits and shutdown can fail when agent is enabled but not running | Enable only after template test; wait for required IP family explicitly | **PROPOSED** |
| SHOULD | Provider upgrade drift | Current provider is pre-1.0 | Bounded version, committed lock file, release-note review, upgrade plan | **PROPOSED** |
| SHOULD | Unreviewed automatic reboot | Provider can reboot/power off to apply some updates | Set behavior explicitly and require maintenance/plan review | **PROPOSED** |
| SHOULD | State is mistaken for backup | Common operational misconception; original has no backup evidence | Document that state cannot restore guest disks; define independent backup/RPO/RTO | **PROPOSED** |
| SHOULD | Provider SSH expands blast radius | Snippet upload and some file operations can require node SSH/sudo | Use native initialization and API-only operations initially | **PROPOSED** |

## PVE API identity and authorization

### Authentication

- **PROPOSED:** Create a dedicated non-human PVE user and API token for this repository/environment.
- **PROPOSED:** Keep API-token privilege separation enabled. With privilege separation, the token needs its own ACL grants and cannot exceed the corresponding user's privileges.
- **PROPOSED:** Deliver the combined token value only through `PROXMOX_VE_API_TOKEN` or the organization's secret-injection mechanism. The endpoint may use `PROXMOX_VE_ENDPOINT`.
- **PROPOSED:** Set an owner, expiry if supported by the operating model, rotation frequency, emergency revoke procedure, and audit trail.
- **PROPOSED:** Never manage the credential used by this provider in the same Terraform state.
- **UNKNOWN:** Realm, identity owner, token expiry/rotation, and secret-management system.

### Candidate privilege surface

The exact role cannot be approved until PVE version, resource schema, VM pool/paths, template, storage, bridge, and optional features are known. The following is a **PROPOSED CANDIDATE**, not a copy-paste role:

| Operation | Candidate privileges to validate | Narrow path concept |
|---|---|---|
| Read template/VM and plan drift | `VM.Audit` | Approved template and managed VM/pool paths |
| Allocate/clone VM | `VM.Allocate`, `VM.Clone` | Managed pool/VM namespace and source template |
| Configure compute | `VM.Config.CPU`, `VM.Config.Memory`, `VM.Config.Options` | Managed VMs only |
| Configure disks/cloud-init | `VM.Config.Disk`, `VM.Config.CDROM`, `VM.Config.Cloudinit` | Managed VMs only |
| Configure NIC | `VM.Config.Network` | Managed VMs only |
| Start/stop/reboot | `VM.PowerMgmt` | Managed VMs only |
| Read/allocate datastore | `Datastore.Audit`, `Datastore.AllocateSpace` | Approved target datastore only |
| Read/use bridge/VLAN | `SDN.Audit` or `SDN.Use` as actually required | Approved local-network/SDN path only |
| Optional pool assignment | `Pool.Audit`/`Pool.Allocate` only if used | One approved pool |
| Optional guest-agent operations | Minimum relevant guest-agent audit privilege only if called | Managed VMs only |

**PROPOSED:** Do not include realm/user/group/permissions management, cluster/network/storage creation, backup/snapshot, host power, syslog, console, migration, replication, mapping modification, or unrestricted guest-agent privileges unless a planned resource operation proves the need.

**OBSERVED:** Provider documentation notes that PVE 9 changed available privileges, its example role is likely too broad, and bridge discovery can require `SDN.Audit` or `SDN.Use`. Therefore a static role copied from documentation is not acceptable evidence.

### ACL validation

Before first apply to any authorized target:

1. Produce the exact resource/operation list from the approved Terraform.
2. Have the PVE administrator create the narrow candidate role and ACL paths outside this state.
3. Run authenticated read/plan checks with audit-only access first.
4. Test non-destructive clone, configuration, and power behavior using only the candidate role.
5. Add one missing privilege at a time from PVE audit/API evidence; never jump to Administrator.
6. Record the final role, path grants, PVE version, provider version, and negative tests.

Any delete/replacement permission test must use a separately authorized disposable VM, not the reusable development VM.

No such live validation was performed in Stage 0.

## TLS and provider transport

- **OBSERVED:** The provider verifies TLS by default and currently defaults its minimum TLS setting to 1.3.
- **PROPOSED:** Use a DNS name matching the PVE API certificate and trust the internal/public issuing CA on operator and CI hosts.
- **PROPOSED:** Keep `insecure` unset/false. Do not use `curl -k` or equivalent in normal instructions.
- **PROPOSED:** If a reverse proxy is used, validate end-to-end trust, authentication-header handling, host/port matching, and audit logging.
- **UNKNOWN:** Endpoint name, certificate issuer, CA distribution method, proxy, and whether all runners support the chosen minimum TLS version.

## Provider SSH boundary

- **OBSERVED:** Normal VM create/update/delete, `import_from`, and provider-managed downloads can use the PVE API. Snippet upload and some local file transfers require SSH.
- **APPROVED:** Human administrators have SSH access to the Proxmox server. That administrative access is separate from Terraform and grants no provider SSH or host-change authority.
- **PROPOSED:** Keep the initial provider path API-only. Use native `initialization`; do not upload snippets.
- **PROPOSED:** If a later explicit task authorizes provider SSH, perform a separate threat review. Use a dedicated SSH identity, host-key verification, restricted network path, and precisely scoped sudoers. Never grant unrestricted `qm`, `pvesm`, or broad passwordless root-equivalent commands.
- **UNKNOWN:** Whether custom cloud-init beyond native initialization will ever be necessary.

## Guest access and cloud-init

- **PROPOSED:** Accept only approved SSH public keys. Do not generate private keys with Terraform or place private keys/passwords in state.
- **PROPOSED:** Define named key owners, rotation/revocation, and whether keys are per-person or through an organizational CA/access system.
- **PROPOSED:** Use cloud-init only for minimal bootstrapping. Any application secret must be retrieved at runtime from an approved secret system, not embedded in user data.
- **PROPOSED:** Review rendered cloud-init for secret strings and syntax before plan/apply. Confirm it is idempotent and does not log secrets.
- **PROPOSED:** The template must regenerate machine identity and SSH host keys correctly for clones.
- **UNKNOWN:** Guest user, key sources, access path, sudo policy, original bootstrap, package mirrors, and egress.

## Network security

- **PROPOSED:** Preserve private-only placement. This repository does not make a VM public for convenience.
- **PROPOSED:** Record packet paths for PVE API access, operator-to-guest management, DNS/NTP, package updates, application traffic, and backup/monitoring agents.
- **PROPOSED:** A bridge and VLAN are attachment mechanisms, not firewall policies. Enabling the PVE NIC firewall flag without rules is insufficient.
- **PROPOSED:** Assign ownership for PVE datacenter/node/VM firewall and guest firewall. Document default-deny/allow behavior and the exact port/source matrix before adding rules.
- **PROPOSED:** Avoid IPv6 until routing and firewall policy cover it end to end.
- **UNKNOWN:** Bridge, VLAN, routing, DHCP, DNS, egress, management network, firewall defaults, and application flows.

## Template and supply-chain security

- **APPROVED:** The target guest is Ubuntu Server 24.04 LTS and the required template does not yet exist; template preparation remains outside this Terraform VM stack.
- **PROPOSED:** Record vendor/source URL, immutable digest or signed build reference, OS/architecture, build owner, package update date, configuration, and deprecation date for each approved template.
- **PROPOSED:** Scan or otherwise review images according to organization policy before promotion. Do not download an unchecked moving “latest” image during a VM apply.
- **PROPOSED:** Include cloud-init and QEMU Guest Agent in the template contract and prove both at boot.
- **PROPOSED:** Patch by promoting a new template and reviewing replacement/upgrade impact; Terraform is not an in-guest patch manager.
- **UNKNOWN:** Image pipeline, signature/checksum policy, patch SLA, and vulnerability ownership.

## VM and disk lifecycle security

- **APPROVED:** The first VM is a reusable development VM. Its disk may contain useful work even if no formal production availability requirement exists.
- **OBSERVED:** Current provider documentation says `proxmox_virtual_environment_vm` defaults `delete_unreferenced_disks_on_destroy = true`, `purge_on_destroy = true`, and `stop_on_destroy = false`.
- **PROPOSED:** Set all material lifecycle arguments explicitly so provider defaults cannot silently define data loss, backup-job removal, or shutdown behavior.
- **PROPOSED:** Treat map-key renames, VM removal, root/data disk changes, template changes, node moves, datastore moves, imports, and state moves as high-risk operations requiring explicit review.
- **PROPOSED:** Distinguish:
  1. VM replacement;
  2. removal of one map key;
  3. full stack destroy;
  4. deletion outside Terraform;
  5. restoration from backup.
- **PROPOSED:** PVE `protection` can reduce accidental API deletion but is not a backup and can obstruct legitimate Terraform destroy. Choose it only with an unlock/runbook owner.
- **PROPOSED:** Backups/snapshots must have an independent owner, retention, off-host policy where required, restore procedure, and tested evidence.
- **PROPOSED:** Use a separate disposable VM for destructive lifecycle tests; do not infer that a development VM can be recreated safely until its data and bootstrap contract prove it.
- **UNKNOWN:** Root/data retention, backup scope, RPO/RTO, `purge_on_destroy`, protection flag, shutdown method, and restore tests.

## Terraform state and plan security

- **OBSERVED:** The source HTTP backend is unconfigured in Git. HashiCorp's HTTP backend supports optional locking; locking is disabled unless lock endpoints are configured.
- **APPROVED:** GitLab-managed Terraform state through the HTTP backend is the target state service, pending validation.
- **PROPOSED:** Use it only after confirming:
  - TLS verification and protected credentials;
  - server-side access control and auditability;
  - working lock and unlock endpoints;
  - backups/versioning and a tested restore process;
  - separate keys/states per environment;
  - restricted administrative/force-unlock procedures;
  - concurrency control in CI.
- **PROPOSED:** Supply backend credentials through supported environment variables/secret injection, not `-backend-config` values that can be cached into `.terraform` or saved plans.
- **PROPOSED:** Ignore `.terraform/`, local state/backups, crash logs, saved plans, and secret tfvars; commit `.terraform.lock.hcl` and a redacted example values file.
- **PROPOSED:** Restrict saved-plan access and retention. A `sensitive` flag hides display but does not guarantee omission from state.
- **PROPOSED:** Never use `-lock=false` for convenience. Force-unlock only the operator's known stale lock after verifying no writer remains.
- **UNKNOWN:** GitLab project ID, state name, HTTP and lock endpoints, credentials, TLS chain, access controls, version/backup behavior, retention, and restore process.

HashiCorp references:

- [HTTP backend](https://developer.hashicorp.com/terraform/language/backend/http)
- [State storage and locking](https://developer.hashicorp.com/terraform/language/state/backends)
- [State locking](https://developer.hashicorp.com/terraform/language/state/locking)

## CI and operational controls

- **PROPOSED:** Separate plan and apply authority where practical. Protect environments/branches and require human review of replacements/deletes.
- **PROPOSED:** Serialize operations per state. Run apply from the reviewed commit/plan only, and keep apply manual initially.
- **PROPOSED:** Ensure runner network access is limited to the required PVE API and backend endpoints. Do not expose PVE publicly for CI.
- **PROPOSED:** Redact token values and disable provider debug logging in normal CI. Debug artifacts require explicit secure handling.
- **PROPOSED:** Record who may approve VM deletion, disk deletion, state recovery, and token/ACL changes.
- **UNKNOWN:** CI product, runner placement, artifact controls, approvers, and secret manager.

## Security validation gate

Before the first VM apply, evidence must show:

- PVE/provider compatibility and exact versions;
- verified API TLS from the operator/runner;
- dedicated token rotation owner and least-privilege ACL test results;
- no PVE node SSH needed for the selected resource path;
- template provenance and guest-agent/cloud-init boot test;
- reviewed private network/firewall/access-path contract;
- explicit lifecycle/deletion configuration and backup owner;
- GitLab backend authentication, TLS, locking, backup/recovery, access-control, and concurrency tests;
- a redacted plan containing no credentials, passwords, or private keys.

**APPROVED:** No apply, destroy, state mutation, or live permission test was run during Stage 0.
