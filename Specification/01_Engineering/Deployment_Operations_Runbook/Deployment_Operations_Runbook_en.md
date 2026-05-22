---
title: "vLearn2 (VFLS) — Deployment & Operations Runbook"
author: "vLearn2 Engineering"
date: "2026-05-22"
---

# Deployment & Operations Runbook

**Project:** vLearn2 (VFLS) · **Version:** 1.0 · **Date:** 2026-05-22

---

## 1. Purpose

Operational reference for deploying, configuring, running, monitoring,
and recovering the vLearn2 backend and admin panel. The Flutter app
ships through app stores / direct distribution and is out of scope here
except for its configuration file.

## 2. Target environment

- **Host OS:** Linux (RHEL-class) or Windows.
- **Runtime:** Node.js 22+.
- **Database:** PostgreSQL 16.
- **Reverse proxy:** nginx, terminating TLS.
- **Process manager:** `pm2` or the provided `cmds/` launchers.

## 3. Components & ports

| Component | Process | Internal port |
|-----------|---------|---------------|
| Backend API | `node dist/main` | 3000 (or `PORT`) |
| Admin panel | `next start` | 4100 |
| PostgreSQL | service / container | 5432 |

> The `cmds/` startup scripts contain conflicting default ports
> (backend 4101 / admin 5101 in some places). Reconcile to a single
> canonical mapping before relying on them; the values above are the
> code defaults.

nginx routes: `/vfls/*` → backend `/api/*`; `/vAdmin/*` → admin panel.

## 4. Deployment procedure

### 4.1 Database

```bash
# Provision PostgreSQL 16 (managed service, or for dev:)
docker compose up -d postgres
# Apply schema
cd backend && npm run db:migrate
# Seed reference content (idempotent)
npm run db:seed
```

### 4.2 Backend

```bash
cd backend
npm ci
npm run build            # nest build -> dist/
# configure .env (see §5)
npm run start:prod       # node dist/main
```

### 4.3 Admin panel

```bash
cd admin_panel
npm ci
# set NEXT_PUBLIC_API_BASE_URL and BACKEND_BASE_URL (see §5)
npm run build            # next build
npm run start            # next start -p 4100
```

`NEXT_PUBLIC_*` values are inlined at build time — rebuild after
changing them.

### 4.4 Reverse proxy

Configure nginx to terminate TLS and route `/vfls/*` and `/vAdmin/*`.
Enforce HTTPS for the whole API (HTTP port 80 should only `301` to
443). On RHEL with SELinux enforcing, allow outbound proxy
connections: `setsebool -P httpd_can_network_connect 1`.

### 4.5 Service management

Use the `cmds/` launchers or `pm2`:

```bash
./cmds/start_service_linux.sh 3000 4100
# or with pm2: pm2 start ... ; pm2 save ; pm2 startup
```

## 5. Configuration reference

### Backend `.env`

| Variable | Purpose |
|----------|---------|
| `NODE_ENV`, `PORT` | Environment, listen port |
| `PUBLIC_BASE_URL`, `CORS_ORIGINS` | Public URL, CORS allow-list |
| `DB_HOST/PORT/NAME/USER/PASSWORD`, `DB_LOGGING` | Database |
| `JWT_ACCESS_SECRET/EXPIRES`, `JWT_REFRESH_SECRET/EXPIRES` | JWT |
| `AI_PROVIDER`, `AI_CHAT_MODEL`, `AI_ANALYSIS_MODEL`, `ANTHROPIC_API_KEY` / `OPENAI_*` | AI provider |
| `STORAGE_PROVIDER`, `LOCAL_UPLOAD_DIR` / `S3_*`, `UPLOADS_DIR` | File storage |
| `THROTTLE_TTL_SECONDS`, `THROTTLE_LIMIT`, `MAX_AI_MESSAGES_PER_DAY` | Limits |
| `GZIP_ENABLED`, `GZIP_THRESHOLD_BYTES` | Compression |

### Admin panel `.env`

| Variable | Purpose |
|----------|---------|
| `NEXT_PUBLIC_API_BASE_URL` | Browser-side API base (use a same-origin `/vfls` path) |
| `BACKEND_BASE_URL` | Server-side rewrite target |

### Flutter `app_config.json` (on-device)

`baseurl` (API base), `reqTout`, `tSync`, `dev`. Located beside the
Windows `.exe` or in the Android shared config folder.

## 6. Health & monitoring

- **Liveness:** `GET /health` → `{ "status": "ok" }`. Wire to the load
  balancer / uptime monitor.
- **Logs:** backend uses the NestJS logger; the Linux launcher writes
  to `<repo>/logs/`. Set `DB_LOGGING=true` only for short diagnostics.
- **Key signals:** 5xx rate, p95 latency on `/vfls/*`, PostgreSQL
  connections, AI-provider error rate, `429` rate.

## 7. Routine operations

| Task | Procedure |
|------|-----------|
| Deploy a new version | Build → migrate (if schema changed) → restart backend/admin |
| Apply a DB migration | `npm run db:migrate` (back up first) |
| Rotate a secret | Update `.env`, restart the affected service |
| First admin | Use the bootstrap `admin/auth/signup` once, then gate the route |
| Toggle a feature flag | Admin panel → Config page |

## 8. Backup & recovery

- **Database:** schedule `pg_dump` (or managed snapshots). Verify
  restores periodically.
- **Uploads:** back up `UPLOADS_DIR` (local provider) or rely on S3
  durability.
- **Restore:** provision PostgreSQL, restore the dump, run
  `db:migrate` to confirm head, restart services.
- **RPO/RTO:** define per environment; document the achieved values.

## 9. Incident response

| Symptom | First checks |
|---------|--------------|
| `502` from nginx | Backend/admin process down — `pm2 status` / `ss -ltnp`; restart |
| Logins fail | JWT secret mismatch; DB reachable; clock skew |
| Conversations error | AI provider reachable; `MAX_AI_MESSAGES_PER_DAY` not hit; check fallback path |
| Slow responses | DB connections/locks; AI latency; CPU |
| `429` spike | Rate limit; check for abuse vs. legitimate load |

Rollback: redeploy the previous build artifact; if a migration is
implicated, restore from backup (TypeORM migrations are not auto-down
in production).

## 10. Pre-production checklist

- [ ] HTTPS enforced for the whole API; HTTP redirects to HTTPS.
- [ ] `admin/auth/signup` gated after the first admin is created.
- [ ] `CORS_ORIGINS` set to an explicit allow-list.
- [ ] Strong, unique JWT secrets and DB password.
- [ ] Production Android keystore configured.
- [ ] Backups scheduled and a restore tested.
- [ ] `/health` wired to monitoring.
- [ ] CI trigger branches aligned with the deployed branch.

---

*End of Deployment & Operations Runbook.*
