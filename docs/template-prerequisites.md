# External template prerequisites

Template preparation is deliberately outside this Terraform stack. The VM
resource assumes the following contract; it does not create, repair, or update
the template.

## Required contract

- Proxmox VE 9.x recognizes the source as a VM template on the selected node.
- The guest is Ubuntu Server 24.04 LTS built from a recorded, trusted image with
  its source URL, release date, and checksum retained for audit.
- `cloud-init` is installed and enabled, and the image is cleaned so clones run
  first-boot initialization independently.
- The bootable root disk is `scsi0`. Its size is no larger than any requested
  `vms[*].disk_gb` value; this stack supports growth, not shrinking.
- The Proxmox cloud-init disk is attached at `ide2`.
- Proxmox cloud-init **Upgrade packages** (`ciupgrade`) is disabled on the
  template. This stack deliberately omits `initialization.upgrade`: PVE permits
  only `root@pam` to set it, while the stack uses a non-root API token. Omitting
  it safely preserves the externally prepared template value.
- The template can boot with the inherited firmware, machine, controller, and
  boot-order settings; this stack intentionally inherits them.
- The guest supports the VirtIO network and SCSI devices used by the clone.
- No reusable host keys, machine identity, credentials, DHCP lease, or other
  clone-unique state remains in the captured template.
- The image has no known reusable password and SSH password authentication is
  disabled. Access is through the public keys supplied to native cloud-init.

The provider documentation warns that changing one inherited disk attribute can
cause unspecified attributes to return to provider defaults. Because this stack
sets `scsi0` size and datastore, compare the first authenticated plan with the
template's complete disk configuration. If it proposes unintended cache,
discard, I/O-thread, format, or controller changes, stop and make the template
contract explicit before applying.

## QEMU Guest Agent modes

The safe default is `qemu_guest_agent_enabled = false`. The Terraform resource
then explicitly disables inherited agent integration, skips the provider IP
wait, and returns no IP addresses.

Set it to `true` only if all of the following have been verified on a disposable
test clone:

- `qemu-guest-agent` is installed in the template;
- its service starts automatically and promptly after boot;
- Proxmox reports agent connectivity and a non-loopback IPv4 address; and
- shutdown/reboot through the agent succeeds.

An enabled PVE agent flag without a running in-guest service can block provider
refresh, create, shutdown, and reboot operations until timeout.

## Acceptance evidence

Before using the reusable development VM, retain evidence of:

1. image provenance and checksum verification;
2. the final PVE template configuration, including `scsi0` and `ide2`;
3. successful full-clone creation on the selected datastore;
4. successful DHCP, cloud-init username, SSH-key login, and reboot testing;
5. guest-agent behavior for the selected enabled/disabled mode; and
6. template versioning and replacement/rollback procedure.

Use a separately authorized disposable clone for this testing. Do not perform
destructive template experiments on the reusable first VM.

Reference: [provider clone guide](https://bpg.sh/docs/guides/clone-vm/) and
[VM resource notes](https://bpg.sh/docs/resources/virtual_environment_vm/).
