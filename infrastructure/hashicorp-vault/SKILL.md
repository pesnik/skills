---
name: hashicorp-vault
description: Deploy, configure, and manage HashiCorp Vault — including Docker Compose setup, LDAP auth, secret engines, and policy management.
---

# HashiCorp Vault

**Category:** Infrastructure
**Domain:** Secrets Management / Identity & Access

---

## Overview

HashiCorp Vault is a secrets management tool for storing and controlling access to tokens, passwords, certificates, and encryption keys. This skill covers running Vault in Docker, configuring LDAP authentication for team access, managing secret engines, and writing access policies.

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

**User login:**
```bash
VAULT_ADDR=http://localhost:8200 vault login -method=ldap username=<username>
```

---

## Policy Management

Policies are HCL files applied via `vault policy write <name> <file>`.

### Default LDAP User Policy

Grants LDAP users ability to:
- Read their own secrets
- Mount and configure secret engines
- Read/write within any mounted engine

```hcl
# Own secret path
path "secret/data/users/{{identity.entity.aliases.auth_ldap_*.name}}/*" {
  capabilities = ["read", "list"]
}

# Mount secret engines
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "sys/mounts" {
  capabilities = ["read", "list"]
}

# Configure and use any mounted engine
path "+/config" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "+/config/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "+/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
```

> **Note:** After updating a policy, users must log out and back in for the new token to carry the updated permissions.

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
| `VAULT_ADDR` warning in varlock | Env var present but not wired to plugin | Use `url=$VAULT_ADDR` in `@initHcpVault` |
| Policy change not taking effect | Old token still in use | User must log out and re-authenticate |

---

## References

- [Vault LDAP Auth Docs](https://developer.hashicorp.com/vault/docs/auth/ldap)
- [Vault Policy Syntax](https://developer.hashicorp.com/vault/docs/concepts/policies)
- [varlock docs](https://varlock.dev)
