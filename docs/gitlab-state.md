# GitLab-managed HTTP state

`versions.tf` contains only `backend "http" {}`. All environment-specific
addresses and credentials stay outside source and local variable files.

## External configuration

After the GitLab project ID and state name are approved, configure the operator
environment through its secret-management mechanism:

```sh
export TF_HTTP_ADDRESS="https://gitlab.example.com/api/v4/projects/<project-id>/terraform/state/<state-name>"
export TF_HTTP_LOCK_ADDRESS="${TF_HTTP_ADDRESS}/lock"
export TF_HTTP_UNLOCK_ADDRESS="${TF_HTTP_ADDRESS}/lock"
export TF_HTTP_LOCK_METHOD="POST"
export TF_HTTP_UNLOCK_METHOD="DELETE"
export TF_HTTP_RETRY_WAIT_MIN="5"
export TF_HTTP_USERNAME="<gitlab-username-or-token-name>"
export TF_HTTP_PASSWORD="<gitlab-access-token>"
```

Use the real trusted HTTPS GitLab hostname. Do not disable certificate
verification. Do not put the password/token in Terraform code, `.tfvars`, a
checked-in shell script, a command-line `-backend-config` argument, or a saved
plan. Terraform can cache backend configuration under `.terraform/`, which is
ignored by this repository; environment variables reduce credential persistence.

For local GitLab authentication, choose the narrowest supported credential and
scope. GitLab documents Developer access for reading and Maintainer or Owner for
locking and writing in common user-token workflows; verify the exact behavior
for the chosen GitLab version and token type.

## Validation gate

Before pointing this stack at a real VM state:

1. Confirm the exact project ID and unique state name with the owner.
2. Verify TLS, read/write authorization, and denial for unapproved principals.
3. Exercise concurrent lock contention on an isolated test state; never make
   `-lock=false` the normal workaround.
4. Confirm state version history and download a test version.
5. Document and rehearse restoration without overwriting the production state.
6. Confirm who may force-unlock, how the lock owner is identified, and how an
   interrupted operation is investigated first.
7. Confirm retention, encryption, audit logging, and GitLab backup ownership.

Only then run a normal `terraform init`. Confirm that Terraform selected the
expected non-empty state before any plan. An unexpectedly empty state can make
Terraform propose duplicate VMs and must be treated as a backend incident.

Static schema validation uses `terraform init -backend=false`; it neither tests
nor initializes this remote backend.

References: [Terraform HTTP backend](https://developer.hashicorp.com/terraform/language/backend/http)
and [GitLab-managed state](https://docs.gitlab.com/user/infrastructure/iac/terraform_state/).
