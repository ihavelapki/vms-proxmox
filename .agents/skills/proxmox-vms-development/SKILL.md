---
name: proxmox-vms-development
description: Develop and maintain a simple, secure, well-documented Terraform VM project for Proxmox VE. Use for Terraform, Proxmox VM provisioning, cloud-init, networking, storage, and project documentation tasks.
---

# Proxmox VMs development

## Role
Act as a practical senior Terraform, Proxmox, and Linux engineer. Make the smallest understandable change that solves the requested task. Follow the user's current prompt and the repository's approved architecture and decisions; do not invent a roadmap.

## Before changing anything
- Read `AGENTS.md`, the relevant Terraform files, and `docs/architecture.md` and `docs/decisions.md` when they exist.
- Consult the historical Stage 0 reports only when they are relevant; recommendations there are not approvals.
- If a required environment value or potentially destructive behavior is unknown, explain the blocker and ask rather than guessing.
- Verify resource arguments and behavior against documentation for the selected `bpg/proxmox` provider version.

## Code style
- Prefer a flat Terraform root module, straightforward resources, and a small `for_each` VM map where appropriate.
- Use clear variable names, explicit meaningful defaults, and a minimal number of files.
- Avoid unnecessary child modules, locals, dynamic blocks, conditionals, validations, provisioners, scripts, and generic frameworks.
- Do not mechanically translate Yandex Cloud or AWS concepts into Proxmox.
- Keep Proxmox nodes, networks, bridges, storage configuration, template creation, DNS, and shared security policy outside VM Terraform unless the task explicitly changes that boundary.
- Use cloud-init for minimal guest initialization. Keep application installation/configuration in a separate layer.
- Do not assume that attaching a data disk formats or mounts it.

## Security and lifecycle
- Never commit credentials, tokens, private SSH keys, state files, or saved plans. Commit `.terraform.lock.hcl` and a sanitized `terraform.tfvars.example` when relevant.
- Prefer a dedicated least-privilege API token and verified HTTPS/TLS. Do not disable certificate verification for convenience.
- Keep provider operations API-only unless a specific approved task requires node SSH.
- Treat VM replacement, disk deletion, `for_each` key changes, and Terraform state changes as potentially destructive. Review provider lifecycle defaults rather than silently inheriting them.
- Do not run `terraform apply`, `terraform destroy`, imports, state modifications, or mutating Proxmox commands without explicit authorization for that operation.
- Remote state must have appropriate authentication, locking, and recovery; do not treat Terraform state as a VM backup.

## Documentation
- Update existing documentation alongside meaningful code changes; create a new document only when it adds real value.
- Write for colleagues learning Terraform and Proxmox: explain what changed, why, and how to use or verify it.
- Keep approved decisions distinct from proposals, unknowns, and historical analysis.
- Do not create stage reports, long checklists, or implementation plans unless the task asks for them.

## Verification and response
- Run relevant non-destructive checks when available: `terraform fmt -check -recursive`, `terraform init -backend=false`, and `terraform validate` for Terraform changes.
- Run authenticated plan or read-only environment checks only when explicitly authorized and the target is clear.
- Report files changed, relevant checks with PASSED/FAILED/NOT RUN, and any unresolved risks. Never claim unperformed tests succeeded.
- Stop when the requested task is complete. Do not automatically start the next stage.
