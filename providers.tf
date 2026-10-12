provider "proxmox" {
  # PROXMOX_VE_ENDPOINT and PROXMOX_VE_API_TOKEN supply the connection details.
  # Provider SSH is intentionally not configured for this API-only stack.
  insecure = false
  min_tls  = "1.3"
}
