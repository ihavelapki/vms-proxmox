# Stage 0 skill audit

**Skill audited:** `.agents/skills/proxmox-vms-development/SKILL.md`  
**Audit date:** 2026-10-12  
**Status:** The skill is fit for purpose with several provider-version clarifications recommended below. The skill itself was not modified.

## Classification

- **OBSERVED** — present in the skill or verified current documentation.
- **PROPOSED** — recommended clarification/update; not approved.
- **UNKNOWN** — depends on the target environment.
- **APPROVED** — explicit project constraint.

## Overall assessment

**OBSERVED:** The skill correctly forces a documentation-only Stage 0, prevents mechanical Yandex-to-Proxmox translation, favors a flat root and stable `for_each` keys, keeps shared PVE infrastructure external, requires explicit lifecycle/security decisions, and makes evidence-based documentation part of completion.

**PROPOSED:** Retain the skill's architecture and security principles. Update its time-sensitive provider notes before implementation so it reflects PVE 9 compatibility, the current two-resource clone choice, provider lifecycle defaults, and the API-versus-SSH boundary.

## Requirement-to-architecture audit

| Skill requirement | Proposed architecture alignment | Assessment |
|---|---|---|
| Read source analysis and repositories | Complete analysis and all accessible source files were read | **ALIGNED** |
| Stage 0 produces six named documents | All six are present under `docs/stage-0/` | **ALIGNED** |
| Mark OBSERVED/PROPOSED/UNKNOWN/APPROVED | Documents define and use these labels | **ALIGNED** |
| No Terraform implementation in Stage 0 | Documentation only | **ALIGNED** |
| Flat root, one `for_each` | Proposed as initial shape | **ALIGNED** |
| Shared nodes/bridges/VLAN/storage/DNS/template external | Explicit ownership table and non-goals | **ALIGNED** |
| Prefer `bpg/proxmox`, verify matched docs | Current 0.116.0/PVE support/resource docs reviewed | **ALIGNED** |
| Clone approved cloud-init template | External promoted template and full clone proposed | **ALIGNED** |
| Cloud-init minimal, not app orchestration | Native minimal initialization proposed | **ALIGNED** |
| `/opt` is not mounted merely by attaching disk | Data disk deferred pending filesystem/mount contract | **ALIGNED** |
| Explicit disk deletion/replacement semantics | Lifecycle decision and validation matrix required | **ALIGNED** |
| Least-privilege token, TLS verification | Dedicated privilege-separated token and trusted CA proposed | **ALIGNED** |
| Secrets absent from Git/state-facing config | Environment/secret injection and public keys only | **ALIGNED** |
| State and plans sensitive, backend verified | HTTP backend validation gate documented | **ALIGNED** |
| Bounded versions and committed lock file | Stage 1 requirement | **ALIGNED** |
| Concise nonsecret outputs | Proposed | **ALIGNED** |
| Apply/destroy/state changes require approval | Explicit global gate | **ALIGNED** |
| Documentation and stage evidence report | Per-stage documentation/report contract | **ALIGNED** |

## Current provider findings the skill should capture

### 1. PVE compatibility has a strong default now

- **OBSERVED:** Current provider documentation says it targets and acceptance-tests PVE 9.x, gives PVE 8.x limited support, and does not support PVE 7.x.
- **PROPOSED SKILL UPDATE:** State this as a time-stamped discovery requirement, not a permanent version claim: “Check the current compatibility matrix; if it remains PVE 9-first, require an explicit compatibility spike for PVE 8.”
- **Architecture effect:** D-01 recommends PVE 9.x and blocks implementation until the deployed version is known.

### 2. There are now two clone resource paths

- **OBSERVED:** Provider 0.116.0 offers:
  - `proxmox_virtual_environment_vm` with a `clone` block, full VM configuration, initialization, and agent settings;
  - experimental `proxmox_cloned_vm` with opt-in device management but no management of cloud-init initialization or QEMU Guest Agent settings.
- **PROPOSED SKILL UPDATE:** Require an explicit resource-choice record. Prefer `proxmox_virtual_environment_vm` when per-clone cloud-init or agent configuration is needed; consider `proxmox_cloned_vm` only after its experimental status and limitations are acceptable.
- **Architecture effect:** The legacy-named VM resource is proposed because the target requires per-VM SSH/network initialization.

### 3. Provider lifecycle defaults are security-relevant

- **OBSERVED:** Current `proxmox_virtual_environment_vm` documentation reports defaults including `delete_unreferenced_disks_on_destroy = true`, `purge_on_destroy = true`, and `stop_on_destroy = false`.
- **PROPOSED SKILL UPDATE:** Name these settings in the lifecycle checklist and require explicit values in code rather than inherited defaults.
- **Architecture effect:** Stage 2 cannot proceed until each value and backup impact is approved.

### 4. Clone inheritance can overwrite template disk settings

- **OBSERVED:** When modifying an inherited disk, provider docs require explicitly restating source attributes that differ from schema defaults; otherwise defaults can overwrite template settings. Cross-node clone behavior also depends on whether datastores are shared and consistently named.
- **PROPOSED SKILL UPDATE:** Add a template-clone inspection checklist: source disk attributes, target datastore, full/linked clone, same/cross-node behavior, and post-clone plan convergence.
- **Architecture effect:** Full clone, explicit datastore, minimal template device set, and sandbox clone validation are proposed.

### 5. Guest-agent settings affect correctness and availability

- **OBSERVED:** Enabling the provider agent when `qemu-guest-agent` is absent/stopped can produce long refresh/create/shutdown failures. Clones inherit the template agent setting unless explicitly overridden. IP outputs depend on the agent.
- **PROPOSED SKILL UPDATE:** Require the template contract and Terraform setting to agree; explicitly select IPv4/IPv6 wait behavior or disable waiting.
- **Architecture effect:** Agent/IP output decisions are Stage 2 gates.

### 6. Native cloud-init avoids node SSH

- **OBSERVED:** Most VM operations are API-only. Uploading snippets and certain file operations need SSH; provider docs warn broad `qm`/`pvesm` sudo is effectively root.
- **PROPOSED SKILL UPDATE:** Prefer native `initialization` for the first implementation and call out snippet upload as a separate security boundary.
- **Architecture effect:** No provider SSH in the proposed initial stages.

### 7. TLS behavior is version-sensitive

- **OBSERVED:** The provider verifies certificates by default and currently defaults `min_tls` to 1.3.
- **PROPOSED SKILL UPDATE:** Add a connectivity prerequisite covering endpoint name, CA distribution, reverse proxy, and runner support for the provider's current minimum TLS behavior.
- **Architecture effect:** PVE endpoint/CA is required before Stage 1.

### 8. PVE 9 privileges changed

- **OBSERVED:** Provider documentation warns that available privileges changed in PVE 9 and that its sample role is likely too permissive. It also notes bridge discovery may need `SDN.Audit` or `SDN.Use`, particularly for privilege-separated tokens.
- **PROPOSED SKILL UPDATE:** Explicitly prohibit copying the provider's sample role. Require an operation/path matrix and add-one-privilege-at-a-time sandbox evidence.
- **Architecture effect:** Security review contains a candidate privilege surface, not a final role or command.

### 9. Current release pin

- **OBSERVED:** 0.116.0 is current as of the audit date; the provider remains pre-1.0.
- **PROPOSED SKILL UPDATE:** Keep the generic bounded-version rule and add a reminder that `~> 0.x.y` pins to patch releases for this pre-1.0 provider. Re-check on every implementation/upgrade stage.
- **Architecture effect:** `~> 0.116.0` is a current proposal, not an approved permanent value.

## Skill strengths to retain

- Strong source-fact discipline and prohibition on inventing missing metadata.
- Flat, beginner-readable Terraform before modules/frameworks.
- External ownership for shared PVE infrastructure and template library.
- Clear distinction between bridge attachment and guest networking.
- Explicit warning that a data disk is not a mounted `/opt` filesystem.
- Separation of state recovery from VM data backup.
- Least-privilege API token, verified TLS, public-key-only SSH, and plan/state sensitivity.
- Provider-schema verification rather than invented HCL.
- Stage gates, no automatic apply/destroy, and evidence-based change reports.

## Potential ambiguities and recommended clarifications

| Skill text/theme | Risk | Proposed clarification |
|---|---|---|
| “Prefer cloning an approved template” | Could imply linked clone or template management here | Default to full clone for simplicity; record full/linked decision; template remains external |
| “Review API permissions” | Could lead to a copied broad role | Require exact planned operations plus path-scoped ACL/negative tests |
| “Cloud-init handles minimal initialization” | Could still lead to snippet upload/SSH | Native initialization first; snippets require a separate security decision |
| “Root/data disk lifecycle” | Provider defaults are not named | Require explicit destroy/purge/unreferenced-disk/stop/protection settings |
| “Output IP with agent prerequisites” | Agent inheritance/wait behavior can still surprise | Require explicit agent block and IP-family wait policy on clones |
| Proposed Stage 1 lockfile validation | Lockfile needs provider download/network | Report NOT RUN if unavailable; never fabricate a lock file |
| Remote state may be “reused earlier” | Could normalize an unverified HTTP backend | Require TLS/auth/locking/backup/recovery test before collaboration or apply |

## Architecture challenges to the skill

No core principle conflicts with the proposed architecture. Two implementation details require conscious exceptions/interpretation:

1. **Resource naming maturity:** The architecture proposes a resource the provider now describes as “legacy,” because the experimental replacement cannot manage the required per-clone cloud-init and agent settings. This is a deliberate, documented tradeoff to revisit before Stage 2 and each provider upgrade.
2. **Data-disk independence:** The provider's separate “disk holder VM” example is experimental and explicitly warns of data loss. The skill's desire for clear persistent-disk lifecycle should not push this project into that pattern without a separate sandbox proof. The simplest initial architecture defers the data disk and treats backup/recovery as the primary persistence control.

## Recommended skill changes

No skill file was changed in Stage 0. If the owner wants the skill updated later, the minimal patch should:

1. Add time-stamped PVE/provider compatibility discovery.
2. Add a clone-resource selection decision.
3. Require explicit VM lifecycle arguments, including unreferenced-disk behavior.
4. Add clone inheritance/cross-node datastore checks.
5. Add explicit guest-agent inheritance and IP wait policy.
6. Prefer native initialization and flag snippets as an SSH/sudo boundary.
7. Prohibit copying broad sample roles; require path-scoped permission evidence.
8. Add endpoint CA/minimum-TLS compatibility to Stage 1.

## Audit conclusion

**PROPOSED:** Approve the skill as the governing development workflow for this repository, with the clarifications above applied during implementation reviews. The skill correctly blocks implementation until the environment decisions in [decisions.md](decisions.md) are approved.

Primary provider references:

- [Provider compatibility and security](https://github.com/bpg/terraform-provider-proxmox)
- [Provider configuration and authentication](https://bpg.sh/docs/)
- [VM resource and lifecycle defaults](https://bpg.sh/docs/resources/virtual_environment_vm/)
- [VM lifecycle guide](https://bpg.sh/docs/guides/vm-lifecycle/)
- [Clone resource comparison](https://bpg.sh/docs/guides/migration-vm-clone/)
- [Cloud-init guide](https://bpg.sh/docs/guides/cloud-init/)
