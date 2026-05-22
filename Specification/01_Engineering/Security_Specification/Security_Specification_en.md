---
title: "vLearn2 (VFLS) — Security Specification & Threat Model"
author: "vLearn2 Engineering"
date: "2026-05-22"
---

# Security Specification & Threat Model

**Project:** vLearn2 (VFLS) · **Version:** 1.0 · **Date:** 2026-05-22

---

## 1. Purpose & scope

This document describes the security architecture of vLearn2, analyses
threats using the STRIDE model, lists implemented controls, and records
known weaknesses with remediation guidance. It covers the backend API,
admin panel, Flutter app, and the DataManage signing chain.

## 2. Security architecture

### 2.1 Authentication

- **Dual-actor JWT.** A single JWT structure carries `sub`, identity
  claims, `role`, `permissions[]`, and an `actor` discriminator
  (`user` | `admin`). Guards use `actor` to decide which table `sub`
  refers to.
- **Access tokens:** HS256-signed, short-lived (default 15 minutes).
- **Refresh tokens:** random 48-byte secrets, stored only as SHA-256
  hashes, single-use (rotated on every refresh), default lifetime
  7 days. Learners and admins use separate token tables.
- **Passwords:** bcrypt (10 rounds). Learner minimum 6 characters;
  admin minimum 12 with mixed case + digit.

### 2.2 Authorization

- A global `JwtAuthGuard` protects every route unless decorated
  `@Public()`.
- Admin routes additionally pass `PermissionGuard`, which enforces
  `@RequirePermission(...)` against a catalog of ~40 permission keys.
- `superadmin` bypasses individual permission checks
  (`permissions: ['*']`).
- Privacy-sensitive permissions (e.g. transcript viewing, role
  editing, account deletion, all `admins.*`) are flagged
  non-grantable to sub-admins.

### 2.3 Transport

- TLS terminated at nginx; `helmet` adds security headers.
- CORS restricted to the `CORS_ORIGINS` allow-list with
  `credentials: true`.
- Global rate limiting via `ThrottlerGuard` (default 120 req / 60 s).

### 2.4 Data protection

- Secrets supplied via environment variables; example files contain
  placeholders only.
- Password hashes and admin password hashes are excluded from default
  query selection (`select: false`).
- Uploaded files validated by MIME type and size; stored with a
  content hash.

### 2.5 Supply chain — DataManage `.ddp`

- Speech-model bundles are cryptographically signed by the DataManage
  tool.
- The Flutter app pins a root CA (`assets/datamanage/root_ca.crt`) and
  verifies bundle signatures before installation; unpacking runs on a
  background isolate.

## 3. Trust boundaries

```
[ Learner device ] ──TLS──► [ nginx ] ──► [ backend ] ──► [ PostgreSQL ]
[ Admin browser  ] ──TLS──► [ nginx ] ──► [ admin panel ] ──► [ backend ]
                                         [ backend ] ──► [ AI provider ]
[ DataManage (offline) ] ──signs──► .ddp ──► [ Flutter app verifies ]
```

Boundaries: device↔nginx (untrusted network), nginx↔services (internal),
backend↔AI provider (external third party), DataManage↔app (offline
signed artifact).

## 4. STRIDE threat analysis

| Threat | Vector | Mitigation | Residual risk |
|--------|--------|------------|---------------|
| **Spoofing** | Stolen credentials / tokens | bcrypt, short access-token TTL, single-use refresh tokens | Token theft via XSS on admin panel — see §5.2 |
| **Tampering** | Modified requests; tampered `.ddp` | Validation pipe, TLS, signed bundles + pinned CA | Low |
| **Repudiation** | Admin denies an action | Immutable `vl_admin_audit_log`, written in-transaction | Low |
| **Information disclosure** | Sniffing; over-broad responses | TLS everywhere; `select:false` on hashes; CORS allow-list | Mixed HTTP/HTTPS misconfig — see §5.3 |
| **Denial of service** | Request flooding; large uploads | `ThrottlerGuard`; 5 MB upload cap | AI-provider cost abuse partially capped by `MAX_AI_MESSAGES_PER_DAY` |
| **Elevation of privilege** | Sub-admin escalation; open signup | `PermissionGuard`; non-grantable sensitive perms | Open admin signup — see §5.1 |

## 5. Known weaknesses & remediation

### 5.1 Open admin signup (High)

`POST /admin/auth/signup` is intentionally unauthenticated for
bootstrap — the first signup becomes `superadmin`. **Before any public
deployment** this must be gated: disable the route after first use, or
require an invite token, or restrict by network/IP.

### 5.2 Admin tokens in `sessionStorage` (Medium)

The admin panel stores access/refresh tokens in `sessionStorage`,
exposing them to any XSS on the panel. Documented trade-off vs. httpOnly
cookies. Remediation: move to httpOnly, `Secure`, `SameSite` cookies
with a CSRF token, or accept the risk with strict CSP and dependency
hygiene.

### 5.3 Transport consistency (Medium)

All API traffic, including post-login requests, must be HTTPS. Serving
non-auth endpoints over HTTP would expose the bearer token (a
credential) on every request — encrypting only sign-in provides no net
protection. Enforce HTTPS-everywhere with an HTTP→HTTPS redirect.

### 5.4 CORS fallback (Low)

When `CORS_ORIGINS` is empty the backend falls back to allow-all
(`origin: true`). Always set an explicit allow-list in production.

### 5.5 Android release signing (Medium)

Release APKs are currently signed with debug keys. A production
keystore must be configured before distribution.

### 5.6 Secrets hygiene (Low)

`docker-compose.yml` hard-codes a development database password
(`dev_password`); `.env.example` ships placeholder secrets. Ensure
production secrets are unique, strong, and never committed.

### 5.7 Gzip kill-switch disabled (Informational)

The runtime gzip kill-switch is commented out; not a vulnerability but
noted for operational accuracy.

## 6. Security controls checklist

| Control | Status |
|---------|--------|
| Passwords hashed (bcrypt) | Implemented |
| Refresh tokens hashed & single-use | Implemented |
| Global auth-by-default | Implemented |
| Role/permission enforcement (server-side) | Implemented |
| Rate limiting | Implemented |
| TLS termination | Implemented (nginx) |
| Audit logging (in-transaction) | Implemented |
| Signed model bundles + pinned CA | Implemented |
| Admin signup gating | **Outstanding** (§5.1) |
| Admin token storage hardening | **Outstanding** (§5.2) |
| Production keystore | **Outstanding** (§5.5) |

## 7. Recommendations (priority order)

1. Gate `POST /admin/auth/signup` before public deployment.
2. Enforce HTTPS for the entire API surface.
3. Move admin tokens to httpOnly cookies, or apply a strict CSP.
4. Configure a production Android keystore.
5. Always set an explicit `CORS_ORIGINS` allow-list.
6. Rotate all default/example secrets for production.

---

*End of Security Specification & Threat Model.*
