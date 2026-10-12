# Stage 0 migration mapping

**Status:** Proposed for review.  
**Purpose:** Separate portable intent from Yandex-specific implementation and unknown operational behavior.

## Classification

- **OBSERVED** — confirmed in the inspected source or source analysis.
- **PROPOSED** — recommended Proxmox treatment; not approved.
- **UNKNOWN** — requires owner/platform input or a live sandbox check.
- **APPROVED** — explicitly required by the Stage 0 brief.

## Migration rule

**APPROVED:** This is a redesign, not a mechanical provider translation. Preserve proven user intent, redesign cloud-specific mechanisms, and remove behavior that has no Proxmox equivalent or no demonstrated need.

## Component mapping

| `rtl-vm` concern | Confirmed source fact | Classification for target | Proposed Proxmox treatment | Approval/unknown |
|---|---|---|---|---|
| Multiple VM inventory | **OBSERVED:** `vms` map with stable `for_each` keys `master` and `worker` | Preserve | **PROPOSED:** Small `vms` map and one flat root `for_each` | Approve map contract and key names |
| Resource identity | **OBSERVED:** Map key controls Terraform identity; `name` separately controls VM naming | Redesign | **PROPOSED:** Map key is canonical identity; derive name or allow a narrowly justified override | Confirm compatibility names |
| Child VM module | **OBSERVED:** Wraps three resources and hides active defaults | Remove initially | **PROPOSED:** Flat root module; add a child module only for proven reuse | Approve flat layout |
| VM resource | **OBSERVED:** One `yandex_compute_instance` per map entry | Replace | **PROPOSED:** `proxmox_virtual_environment_vm` clone per key | Confirm PVE/provider/resource choice |
| Compute sizing | **OBSERVED:** Explicit cores and memory; optional core fraction | Preserve/redesign | **PROPOSED:** Preserve explicit cores and memory in native units; remove core fraction | Select values and CPU type policy |
| Platform | **OBSERVED:** Hidden `standard-v3` default | Remove/redesign | **PROPOSED:** Template architecture plus explicit, cluster-compatible Proxmox CPU type policy | Node CPU/migration requirements unknown |
| Preemptibility | **OBSERVED:** Hidden `preemptible = true` for every VM | Remove | PVE has no direct VM purchase model; do not invent interruption behavior | None unless scheduler/HA need appears |
| Stop for update | **OBSERVED:** `allow_stopping_for_update = true` | Redesign | **PROPOSED:** Make provider reboot behavior explicit; plans that stop/reboot/replace require review | Maintenance policy unknown |
| OS image family | **OBSERVED:** Latest/resolved Ubuntu 24.04 family feeds root-disk creation | Redesign | **PROPOSED:** Clone a promoted external template with recorded source and checksum | Template/OS/provenance unknown |
| Root disk | **OBSERVED:** Separate 20 GB image-backed disk, retained on VM API deletion but Terraform-owned | Redesign | **PROPOSED:** Full-cloned root disk on explicit datastore; explicit size and destroy behavior | Retention/backup/storage unknown |
| `/opt` disk | **OBSERVED:** Separate empty 30 GB disk; visible code does not format or mount it | Defer/redesign | **PROPOSED:** Add only after `/opt` purpose, filesystem, idempotent mount, retention, and recovery are approved | Original bootstrap missing |
| Disk type | **OBSERVED:** Both disks use `network-hdd` | Remove | Proxmox datastore/type capabilities are different; select external datastore by ID | Datastore type/capability unknown |
| Disk image drift | **OBSERVED:** Root `image_id` changes are ignored | Remove | **PROPOSED:** Pin/promote templates; review template changes instead of hiding drift | Template update process unknown |
| Empty-disk drift rule | **OBSERVED:** `/opt` disk ignores `image_id` despite no image input | Remove | No target equivalent or value | None |
| Disk deletion | **OBSERVED:** `auto_delete = false` does not protect Terraform-owned disks from destroy/key removal | Redesign | **PROPOSED:** Explicit provider deletion arguments, documented plan review, backups separate | Owner must define survival at three deletion boundaries |
| Availability zone | **OBSERVED:** Derived from external subnet and shared by VM/disks | Remove/redesign | **PROPOSED:** Select explicit PVE node; respect storage locality/shared scope | Standalone vs cluster unknown |
| Existing subnet | **OBSERVED:** Consumed by name; not created | Preserve boundary | **PROPOSED:** Consume existing bridge/VLAN and guest network services | Bridge/VLAN/addressing unknown |
| Private IPv4 | **OBSERVED:** Dynamic private address, no public NAT | Preserve intent | **PROPOSED:** Existing private/management network; DHCP or approved static cloud-init | DHCP, route and access path unknown |
| IPv6 | **OBSERVED:** Disabled | Preserve initially | **PROPOSED:** IPv4-only until an IPv6 requirement is approved | Confirm platform standard |
| NIC model | Yandex-specific and implicit | Redesign | **PROPOSED:** One VirtIO NIC | Confirm guest/template support |
| Security group | **OBSERVED:** No explicit group; external/default network behavior applies | Remove/redesign | PVE bridge/firewall and guest firewall are different; make firewall owner explicit | Port matrix and firewall ownership unknown |
| DNS zone | **OBSERVED:** Existing zone consumed; zone not created | Preserve boundary only if needed | **PROPOSED:** DNS out of initial scope; later manage records through the actual external DNS provider | FQDN compatibility/owner unknown |
| DNS record | **OBSERVED:** A record nested in NIC, TTL 600, no PTR | Redesign or remove | Proxmox does not supply authoritative DNS; add separate integration only if required | Record owner and names unknown |
| Master naming special case | **OBSERVED:** `master` gets exactly `project_name`; others get `<project>-<name>` | Remove unless compatible | **PROPOSED:** One visible DNS-compatible naming rule | Consumers of current names unknown |
| VM ID | Yandex ID generated by service | Redesign | **PROPOSED:** Let PVE allocate, unless a reserved explicit ID range is required | PVE convention unknown |
| SSH access | **OBSERVED:** Missing `ssh-keys.metadata` is required | Redesign | **PROPOSED:** Approved public keys through native cloud-init; no private keys/passwords in Terraform | User/key/rotation owner unknown |
| User data | **OBSERVED:** Missing `user-data.metadata` is required | Recover intent | **PROPOSED:** Minimal versioned cloud-init only after intent review; application config stays elsewhere | Content and egress unknown |
| Agent behavior | **OBSERVED:** Yandex unified-agent and serial metadata are disabled | Remove/redesign | Decide QEMU Guest Agent independently; do not translate cloud-agent flags | Template agent state unknown |
| QEMU Guest Agent | Not a Yandex concept in visible code | Add conditionally | **PROPOSED:** Require installed/running agent if enabling provider agent or IP outputs | Template contract unknown |
| VM service identity | **OBSERVED:** No guest service account attached | Preserve absence | Do not add guest credentials or an identity mechanism without need | Application access unknown |
| Tags/labels | **OBSERVED:** None | Add minimal | **PROPOSED:** Small PVE tag set such as `terraform` and environment/project if naming rules allow | Tag standard unknown |
| Folder/cloud IDs | **OBSERVED:** Yandex-specific environment boundary | Remove | No Proxmox analogue; endpoint/cluster plus explicit node/storage/bridge replace it | None |
| Data-source lookups | **OBSERVED:** Folder/subnet/zone/image discovered by mutable names/family | Redesign | **PROPOSED:** Explicit node, template VM ID, datastore ID, bridge, and VLAN inputs | Exact values unknown |
| Provider auth | **OBSERVED:** Local service-account JSON file referenced | Replace | **PROPOSED:** Dedicated API token from environment/secret injection | Token/ACL/rotation unknown |
| Provider version | **OBSERVED:** Yandex provider unbounded; no lock file | Replace | **PROPOSED:** Reviewed bounded `bpg/proxmox` release plus committed lock | PVE version must be known first |
| HTTP backend | **OBSERVED:** Empty partial configuration | Validate/reuse or replace | **PROPOSED:** Reuse only if HTTPS, authentication, locking, access control, backup and recovery pass review | Backend details unknown |
| State sensitivity | **OBSERVED:** Metadata could enter state | Preserve concern | Treat PVE token, cloud-init, plans, and state as sensitive; keep secrets out of resource arguments | State owner/controls unknown |
| Human-formatted outputs | **OBSERVED:** Folder/subnet/DNS/image heredocs duplicate external data | Remove | Output only operator/automation values | Confirm output consumers |
| VM output map | **OBSERVED:** IDs, names, FQDN, private IP | Preserve narrowly | **PROPOSED:** ID, name, node, MAC; IP only from agent or configured static value | Agent/addressing decision |
| CI | **OBSERVED:** No CI | Add later if required | **PROPOSED:** format/validate/plan, protected reviewed apply, serialized per state | CI platform and requirements unknown |
| Backup | **OBSERVED:** No backup/snapshot resources or recovery docs | External decision | **PROPOSED:** Keep backup outside Terraform VM lifecycle; document restore owner and evidence | RPO/RTO/data class unknown |

## Functionality to preserve

- **PROPOSED:** A concise map of machines with stable keys.
- **PROPOSED:** Explicit per-VM CPU, memory, and disk sizing after values are reviewed.
- **PROPOSED:** Private-only network intent and consumption of existing platform infrastructure.
- **PROPOSED:** Existing DNS ownership boundary, but not necessarily DNS record management.
- **PROPOSED:** Structured per-VM outputs, reduced to values that are reliable and operationally useful.
- **PROPOSED:** An additional data disk only after its actual persistence and `/opt` requirements are proven.

## Functionality to redesign

- VM creation becomes cloning from an approved cloud-init template.
- Yandex subnet/zone placement becomes explicit PVE node, datastore, bridge, and optional VLAN selection.
- Hidden interruptibility/platform behavior becomes explicit CPU, reboot, protection, and lifecycle policy.
- Missing metadata inputs become reviewed native cloud-init with controlled public keys.
- Cloud-integrated DNS becomes a separate external-DNS integration, if required.
- Disk retention becomes an explicit Terraform/PVE/backup contract rather than an attachment flag.
- Credential files become an injected, least-privilege API token with verified TLS.
- Unverified HTTP state becomes a validated locking remote backend or an approved replacement.

## Functionality to remove

- Yandex cloud/folder/image/subnet/DNS data sources and identifiers.
- Core fraction, `standard-v3`, preemptible scheduling, Yandex agent and serial-port metadata.
- Hidden module defaults, quoted numeric/Boolean coercion, and meaningless disk `ignore_changes`.
- Special `master` naming unless an external dependency is demonstrated.
- Human-formatted external-resource outputs.
- The initial child module and any universal VM abstraction.
- Any assumption that Proxmox creates DHCP, DNS, routing, or a safe firewall policy.

## Unknown behavior that must not be invented

- The contents of `ssh-keys.metadata` and `user-data.metadata`.
- Whether the original `/opt` disk was formatted, labeled, mounted, backed up, or used for persistent data.
- Network routes, firewall rules, DNS visibility, management path, and package egress.
- Workload availability, backup, recovery, monitoring, and application-port requirements.
- Current HTTP backend controls and CI workflow.

These unknowns become owner decisions or discovery tasks; they are not defaults to guess during implementation.
