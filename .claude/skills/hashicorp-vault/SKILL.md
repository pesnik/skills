---
name: hashicorp-vault
description: Deploy, configure, and manage HashiCorp Vault — including Docker Compose setup, LDAP auth, userpass auth, secret engines, personal secret isolation, and policy management.
---

# HashiCorp Vault

**Category:** Infrastructure
**Domain:** Secrets Management / Identity & Access

---

## Overview

HashiCorp Vault is a secrets management tool for storing and controlling access to tokens, passwords, certificates, and encryption keys. This skill covers running Vault in Docker, configuring LDAP and Userpass authentication, managing secret engines, personal secret isolation per user, and writing access policies.

---

## Stack Used

- **HashiCorp Vault** (Docker image: `hashicorp/vault:latest`)
- **Docker Compose** with Raft integrated storage (no external backend)
- **Traefik** as reverse proxy (TLS termination)
- **varlock** for injecting Vault secrets into scripts at runtime
- **LDAP** (Active Directory / OpenLDAP) for user authentication

---

## Docker Compose Setup

```yaml
services:
  vault:
    image: hashicorp/vault:latest
    restart: unless-stopped
    entrypoint: ["/usr/bin/dumb-init", "--", "vault", "server", "-config=/vault/config/vault.hcl"]
    user: "100:1000"          # vault:vault — never run as root
    cap_add:
      - IPC_LOCK              # prevent secrets swapping to disk
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    volumes:
      - ./config:/vault/config:ro
      - ./data:/vault/file
      - ./logs:/vault/logs
```

**Key `vault.hcl` settings:**
```hcl
storage "raft" {
  path    = "/vault/file"
  node_id = "vault-node-1"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true           # TLS handled by Traefik
}

api_addr     = "http://vault.localhost"
cluster_addr = "http://vault:8201"
ui           = true
disable_mlock = false
```

---

## LDAP Authentication Setup

Uses a shell script + varlock to inject LDAP credentials at runtime. Store these in Vault itself under `ede/ldap`:

| Secret                    | Description                                   |
|---------------------------|-----------------------------------------------|
| `AUTH_LDAP_SERVER`        | LDAP URL (e.g. `ldap://localhost:389`)        |
| `AUTH_LDAP_BIND_USER`     | Service account DN for Vault bind             |
| `AUTH_LDAP_BIND_PASSWORD` | Service account password                      |
| `AUTH_LDAP_SEARCH`        | User search base DN                           |
| `AUTH_LDAP_UID_FIELD`     | Username attribute (`sAMAccountName` / `uid`) |

**Apply with varlock:**
```bash
varlock run -- bash scripts/setup-ldap-auth.sh
```

**Setup script core commands:**
```bash
vault auth enable ldap

vault write auth/ldap/config \
  url="$AUTH_LDAP_SERVER" \
  binddn="$AUTH_LDAP_BIND_USER" \
  bindpass="$AUTH_LDAP_BIND_PASSWORD" \
  userdn="$AUTH_LDAP_SEARCH" \
  userattr="$AUTH_LDAP_UID_FIELD" \
  token_policies="ldap-default"
```

**Get LDAP auth accessor** (needed for identity templates in policies):
```bash
vault auth list -format=json | jq -r '.["ldap/"].accessor'
# e.g. auth_ldap_xxxxxxxx — use the exact value, not the wildcard *
```

**User login:**
```bash
vault login -method=ldap username=<username>
```

---

## Userpass Authentication Setup

For service/ops accounts that aren't in LDAP:

```bash
vault auth enable userpass
vault write auth/userpass/users/<username> password="<password>" policies="<policy>"
```

**User login:**
```bash
vault login -method=userpass username=<username>
```

---

## Personal Secrets Per User (KV v2)

Each LDAP user gets an isolated personal secrets space. No other user can access it — only the owner and root.

**Enable the personal mount once:**
```bash
vault secrets enable -path=personal kv-v2
```

**Policy rules** — add to the LDAP default policy using the **exact accessor** (not `*`):
```hcl
# List root so folder is visible in UI
path "personal/metadata/" {
  capabilities = ["list"]
}

# Owner only — data (exact path + subpaths for KV v2)
path "personal/data/{{identity.entity.aliases.auth_ldap_xxxxxxxx.name}}" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "personal/data/{{identity.entity.aliases.auth_ldap_xxxxxxxx.name}}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Owner only — metadata (for UI folder navigation)
path "personal/metadata/{{identity.entity.aliases.auth_ldap_xxxxxxxx.name}}" {
  capabilities = ["read", "list", "delete"]
}
path "personal/metadata/{{identity.entity.aliases.auth_ldap_xxxxxxxx.name}}/*" {
  capabilities = ["read", "list", "delete"]
}
```

> Users can see each other's folder names exist but cannot access contents. Root bypasses all policies.

---

## Ops User Policy (Userpass)

For ops/service accounts that need access to all shared engines but not personal secrets:

```hcl
path "ede/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "sys/mounts" {
  capabilities = ["read", "list"]
}
path "+/config" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "+/config/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "+/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Block personal secrets entirely
path "personal/*" {
  capabilities = ["deny"]
}
```

> `deny` is safe here because this policy has no identity-templated allow on `personal/*`. Only use `deny` on `personal/*` in policies that have NO identity-template allow for that path — otherwise deny will override the allow regardless of specificity.

---

## Policy Pitfalls

### `deny` is absolute
`deny` overrides ALL other capabilities in ALL matching paths, regardless of specificity. Never combine `path "personal/*" { deny }` with `path "personal/{{username}}/*" { allow }` in the same policy — the deny always wins.

**Wrong:**
```hcl
path "personal/*" { capabilities = ["deny"] }
path "personal/{{identity.entity.aliases.auth_ldap_*.name}}/*" { capabilities = ["read"] }
# deny wins — user can't read their own secrets
```

**Right:** Omit the deny entirely. If no other rule matches `personal/<other-user>/*`, Vault implicitly denies it.

### `+/*` wildcard covers everything
`+` matches one path segment, `*` matches the rest. So `+/*` matches `personal/data/mr.hasan/foo`. If you use `+/*` in a shared policy, all users get access to all mounts including `personal/`. Either remove `+/*` or use it only in policies that also have an explicit `deny` on paths you want blocked — but only when those policies have no identity-template allows for the same paths.

### KV v2 uses `data/` and `metadata/` subpaths
The UI path `personal/mr.hasan/teradata` maps to API paths:
- `personal/data/mr.hasan/teradata` — read/write the secret
- `personal/metadata/mr.hasan/teradata` — list/browse in UI

Policies must cover both. Also cover the exact path **without** trailing `/*` for top-level secrets:
```hcl
path "personal/data/mr.hasan"   { ... }   # exact
path "personal/data/mr.hasan/*" { ... }   # subpaths
```

### Use exact LDAP accessor in identity templates
`{{identity.entity.aliases.auth_ldap_*.name}}` — the `*` wildcard in the accessor can silently fail to resolve. Always use the exact accessor ID:
```hcl
# Bad  — may not resolve
{{identity.entity.aliases.auth_ldap_*.name}}

# Good — exact accessor
{{identity.entity.aliases.auth_ldap_xxxxxxxx.name}}
```

Get it with: `vault auth list -format=json | jq -r '.["ldap/"].accessor'`

---

## varlock Integration

varlock injects Vault secrets as environment variables at runtime, so secrets never touch `.env` files.

**.env.schema example:**
```ini
# @plugin(@varlock/hashicorp-vault-plugin@0.0.3)
# @initHcpVault(url="http://localhost:8200", defaultPath="ede/ldap")
# @defaultRequired=infer @defaultSensitive=false
# ---

# @sensitive
AUTH_LDAP_BIND_PASSWORD=vaultSecret()

# @sensitive
AUTH_LDAP_BIND_USER=vaultSecret()
```

**Run a command with secrets injected:**
```bash
varlock run -- <your-command>
```

---

## Common Gotchas

| Symptom | Cause | Fix |
|---|---|---|
| `permission denied` on `sys/mounts` | Policy missing `sys/mounts` capabilities | Add `sys/mounts/*` to policy |
| Config not saved after mounting engine | Policy missing `+/config` path | Add `+/config/*` to policy |
| User can't read their own personal secret | `deny` on `personal/*` overriding identity template allow | Remove the deny — implicit deny is enough |
| Other users can access personal secrets | `+/*` wildcard covers `personal/` paths | Remove `+/*` from shared policies or use separate ops policy with explicit deny |
| 404 on `personal/metadata/<username>` | Secret is in a subfolder, not at root | Navigate into the folder: `personal/<username>/<secret>` |
| UI can't browse personal folder | Missing `list` on `personal/metadata/` root | Add `path "personal/metadata/" { capabilities = ["list"] }` |
| Identity template not resolving | Using `auth_ldap_*` wildcard accessor | Use exact accessor ID from `vault auth list` |
| Policy change not taking effect | Old token still in use | User must log out and re-authenticate |
| `VAULT_ADDR` warning in varlock | Env var present but not wired to plugin | Use `url=$VAULT_ADDR` in `@initHcpVault` |

---

## References

- [Vault LDAP Auth Docs](https://developer.hashicorp.com/vault/docs/auth/ldap)
- [Vault Userpass Auth Docs](https://developer.hashicorp.com/vault/docs/auth/userpass)
- [Vault Policy Syntax](https://developer.hashicorp.com/vault/docs/concepts/policies)
- [Vault Identity Templating](https://developer.hashicorp.com/vault/docs/concepts/policies#templated-policies)
- [varlock docs](https://varlock.dev)
