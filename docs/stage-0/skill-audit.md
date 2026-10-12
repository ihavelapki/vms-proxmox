# Stage 0 skill audit

**Skill audited:** `.agents/skills/proxmox-vms-development/SKILL.md`  
**Audit date:** 2026-10-12  
**Status:** Reconciled with the simplified skill. The skill and `AGENTS.md` were not modified.

## Classification

- **OBSERVED** — present in the current skill or verified project history.
- **PROPOSED** — an architecture recommendation, not an owner approval.
- **UNKNOWN** — environment information still required.
- **APPROVED** — explicitly confirmed by the owner.

## Current skill assessment

The simplified skill is appropriate for the project. It prioritizes the active prompt and current architecture/decision documents, asks for the smallest understandable change, preserves external ownership boundaries, and requires proportionate non-destructive verification.

It also corrects an important governance issue in the original Stage 0 workflow: historical recommendations and stage plans are background, not mandatory future work.

| Current skill requirement | Documentation alignment | Result |
|---|---|---|
| Follow the active prompt and approved current decisions | `docs/architecture.md` and `docs/decisions.md` are now the current source of truth | **ALIGNED** |
| Consult Stage 0 only when relevant | Stage 0 pages are explicitly labeled historical/background | **ALIGNED** |
| Do not invent environment values | Remaining node/template/network/sizing/state details stay **UNKNOWN** | **ALIGNED** |
| Verify the selected provider version before implementation | Provider/resource choice remains **PROPOSED** and version compatibility unresolved | **ALIGNED** |
| Prefer simple flat Terraform and a small VM map | Retained as **PROPOSED**, not promoted to approval | **ALIGNED** |
| Keep host/network/storage/template/DNS/shared policy external | Current architecture preserves those boundaries | **ALIGNED** |
| Use minimal cloud-init and avoid implicit data-disk mounting | Retained as implementation guidance | **ALIGNED** |
| Prefer least-privilege API-only access and verified TLS | Retained as **PROPOSED** security design | **ALIGNED** |
| Treat replacement, disk deletion, key changes, and state changes as destructive | Strengthened for the reusable development VM | **ALIGNED** |
| Avoid stage reports and plans unless requested | The old implementation plan is now explicitly non-binding | **ALIGNED** |
| Report only checks actually run | Preserved in current documentation guidance | **ALIGNED** |

## Historical recommendations that are no longer hard requirements

The original Stage 0 skill prescribed a fixed staged roadmap, six Stage 0 outputs, detailed reports for every stage, and a large documentation contract. Those requirements produced useful discovery material, but the current simplified skill no longer mandates them.

Accordingly:

- The sequence in `implementation-plan.md` is a reference only. Each ChatGPT/Codex prompt defines the authorized task, prerequisites, and stopping point.
- A future task does not need a stage report, long checklist, or new planning document unless the prompt asks for one.
- Provider version `0.116.0`, `proxmox_virtual_environment_vm`, full clones, flat `for_each`, Proxmox-allocated VM IDs, native cloud-init, API token design, and deferral of DNS/data disk/CI/firewall remain **PROPOSED** choices.
- Historical provider findings remain useful but are time-sensitive and must be verified against the version selected by the implementation task.
- The owner-approved PVE, guest OS, storage, state service, topology, administration paths, and VM purpose take precedence over older unknowns or sandbox assumptions.

## Owner decisions reflected in the audit

- **APPROVED:** PVE 9.x on one standalone server, with no initial cluster or HA requirement.
- **APPROVED:** Ubuntu Server 24.04 LTS guests.
- **APPROVED:** Prepare the missing cloud-init template outside the Terraform VM stack.
- **APPROVED:** Use existing `local-lvm`, after verification.
- **APPROVED:** Human Web UI and SSH administration exist, but provider SSH and host changes are not authorized.
- **APPROVED:** Use GitLab-managed Terraform state via HTTP after validating concrete controls.
- **APPROVED:** The first VM is a reusable development VM.

The reusable VM decision invalidates the historical assumption that the first VM could be a disposable sandbox. Destructive lifecycle testing now requires a separate, explicitly authorized disposable VM.

## Useful historical provider findings

These remain observations from the 2026-10-12 Stage 0 research, not permanent requirements:

- The reviewed provider release targeted PVE 9.x and was pre-1.0.
- The reviewed `proxmox_virtual_environment_vm` resource supported per-clone initialization and guest-agent settings; the alternative clone resource was experimental and more limited.
- VM lifecycle defaults could delete unreferenced disks or purge related configuration, so material lifecycle arguments should be reviewed explicitly.
- A guest-agent setting that does not match the template can cause create, refresh, or shutdown delays.
- Native initialization can avoid provider SSH; uploading snippets may introduce a separate node SSH/sudo boundary.
- PVE privileges and provider requirements are version-sensitive; broad sample roles are not an acceptable least-privilege design.

## Remaining skill-relevant unknowns

- Exact PVE patch, node, endpoint, and certificate chain.
- Compatible Terraform and provider versions and exact resource schema.
- Ubuntu template provenance, ID, build process, cloud-init behavior, and agent state.
- Verified `local-lvm` capacity and capabilities.
- Network and guest-management path.
- VM sizing, identity, user, key source, lifecycle, backup, and recovery.
- GitLab state endpoints, credentials, locking, access controls, and restore behavior.

## Conclusion

No skill change is needed for this documentation task. The current skill correctly makes `docs/architecture.md`, `docs/decisions.md`, and the active prompt authoritative while retaining Stage 0 material as evidence and historical context.
