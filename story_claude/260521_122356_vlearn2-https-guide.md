# Write vLearn2 HTTPS guide (RHEL7/8, OpenSSL 1.0)

## Task

User pointed at `C:\project\vLearn2` — a Flutter app (Android + Windows),
NestJS backend, Next.js admin panel — and asked for an HTTPS deployment
guide on RHEL7/8 with OpenSSL 1.0 compatible certs. Guide lives in
`tempPrompt`; vLearn2 itself is not touched.

## Conversation

**User:**
> "C:\project\vLearn2" is the project that contains flutter application
> for android and windows, backend api(nest framework), adminpanel(next
> framework). You only reference those and put the guide here, inside
> tempPrompt

**Assistant:**
- Spawned Explore subagent to map vLearn2 read-only. Key findings:
  - **Backend (NestJS)** at `backend/`, port **3000**, starts via
    `npm run start`. No built-in TLS — `main.ts:92-95` already assumes
    nginx maps public `/vfls/*` → internal `/api/*`. CORS reads
    `CORS_ORIGINS` env var.
  - **Admin (Next.js)** at `admin_panel/`, port **4100** (pinned in
    `package.json` + `next.config.mjs`). `basePath = "/vAdmin"`,
    `trailingSlash = true`. Env validator at `src/lib/env.ts` accepts
    paths starting with `/`, so a same-origin `/vfls` works.
  - **Flutter app** at `flutter_app/`: reads `app_config.json` from
    device storage at runtime; falls back to
    `String.fromEnvironment('API_BASE_URL')` build-time override at
    `lib/core/network/api_client.dart:91`. Default points at
    `http://172.86.121.43:80/vfls`. No existing TLS handling, no Dio
    `badCertificateCallback`, no `SecurityContext`.
  - **Startup script** at `cmds/start_service_linux.sh` already takes
    `(backendPort, adminPort, hot)` args.

- Wrote `tempPrompt/vlearn2-https-guide.md`, 13 sections:
  1. Architecture (ASCII diagram + URL routing table)
  2. RHEL prerequisites (yum install nginx openssl)
  3. Cert generation — points back at `gen-cert.sh` in this repo,
     with target path under `/etc/pki/nginx`
  4. Full nginx vhost: HTTP→HTTPS redirect, TLS 1.2 only with
     OpenSSL-1.0-safe `ssl_ciphers`, `/vfls/ → :3000/api/` rewrite,
     `/vAdmin/ → :4100` passthrough, firewalld + SELinux notes
  5. Backend `.env` — `CORS_ORIGINS=https://host`
  6. Admin `.env.production` — `NEXT_PUBLIC_API_BASE_URL=/vfls`
     (relative, same-origin → no preflight, no mixed content)
  7. Start services via existing script
  8. Server smoke test (s_client + curl)
  9. Flutter URL switch — runtime (`app_config.json`) or build-time
     (`--dart-define`)
  10. Flutter cert trust — three options ranked by safety:
      bundle as trusted root (recommended) / SPKI pin /
      `badCertificateCallback` (testing only). Plus Android
      `network_security_config.xml` and Windows trust-store import.
  11. End-to-end verification
  12. Troubleshooting table (8 common symptoms)
  13. Production hardening checklist

Deliberate trade-offs:
- Recommended **bundled trusted root** over installing CA on device
  because Android 7+ wouldn't honour user CAs without an extra
  Network Security Config rebuild anyway — the bundle path is the
  simpler one.
- Used **TLS 1.2 only** in nginx config because OpenSSL 1.0.x can't
  speak 1.3 — keeps server/client capabilities aligned.
- Did **not** auto-apply code changes to vLearn2 (user said reference
  only).

## Latest prompt

> "C:\project\vLearn2" is the project that contains flutter application
> for android and windows , backend api(nest framework), adminpanel(next
> framework).
> You only reference those and put the guide here, inside tempPrompt
