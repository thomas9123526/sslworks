# Discussion 03 — vLearn2 architecture inspection + HTTPS guide

**Span:** user points at `C:\project\vLearn2` through committing
`vlearn2-https-guide.md`.

## Goal

User said:
> "C:\project\vLearn2" is the project that contains flutter
> application for android and windows, backend api(nest framework),
> adminpanel(next framework). You only reference those and put the
> guide here, inside tempPrompt

So: a deployment guide for vLearn2 living in `tempPrompt`,
referencing (read-only) the actual project files.

## Inspection (via Explore subagent, read-only)

| Subsystem | Path | Port | Role |
|---|---|---|---|
| Backend (NestJS) | `backend/` | 3000 | API |
| Admin panel (Next.js) | `admin_panel/` | 4100 | browser admin |
| Flutter app | `flutter_app/` | n/a | clients (Android + Windows) |

Important pre-existing assumptions baked into the code:

- **`backend/src/main.ts:92-95`** has a comment confirming the backend
  already expects nginx to map public `/vfls/* → /api/*`.
- **`admin_panel/next.config.mjs`** pins `basePath = "/vAdmin"`,
  `trailingSlash = true`. So nginx must forward the `/vAdmin/` prefix
  intact.
- **`admin_panel/src/lib/env.ts`** accepts paths starting with `/`,
  so the admin panel can talk to the backend via a same-origin
  `/vfls` URL — no CORS preflight, no mixed-content issues.
- **Flutter** reads API base URL from `app_config.json` on the device,
  parsed at `lib/core/config/app_config.dart`. Build-time override
  via `String.fromEnvironment('API_BASE_URL')` at
  `lib/core/network/api_client.dart:91`.
- **`cmds/start_service_linux.sh`** already takes
  `(backendPort, adminPort, hot)` args. No new process management
  needed.

No existing TLS / SSL code in any of the three subsystems — they all
assume reverse proxy termination.

## What we built

`vlearn2-https-guide.md` (13 sections, ~540 lines):

1. Architecture (ASCII diagram + URL routing table).
2. RHEL prerequisites.
3. Cert generation (back-references `gen-cert.sh`).
4. Full nginx vhost — TLS 1.2 only (OpenSSL 1.0 can't do 1.3),
   OpenSSL-1.0-safe `ssl_ciphers`, `/vfls/ → :3000/api/` rewrite,
   `/vAdmin/ → :4100` passthrough, firewalld + SELinux notes.
5. Backend `.env` — `CORS_ORIGINS=https://host`.
6. Admin `.env.production` — `NEXT_PUBLIC_API_BASE_URL=/vfls`
   (relative, same-origin → no preflight, no mixed content).
7. Start services via the existing script.
8. Server smoke test (`openssl s_client` + curl).
9. Flutter URL switch — runtime `app_config.json` or build-time
   `--dart-define`.
10. Flutter cert trust — three options ranked: bundle as trusted root
    (recommended), SPKI pin, `badCertificateCallback` (test only).
    Plus Android `network_security_config.xml` + Windows
    `Import-Certificate`.
11. End-to-end verification.
12. Troubleshooting table (8 common symptoms).
13. Production hardening checklist.

## Decisions made

- **TLS 1.2 only** in nginx, because OpenSSL 1.0 can't terminate 1.3.
- **Same-origin /vfls** for the admin panel's `NEXT_PUBLIC_API_BASE_URL`
  — avoids CORS preflight and mixed-content issues.
- **Bundle CA in Flutter app** (Option 10a) as the recommended trust
  approach — Android 7+ won't honour user-installed CAs without a
  Network Security Config rebuild anyway, so bundling is the simpler
  path overall.
- **Do not modify vLearn2** — guide references only, per the user's
  explicit instruction.

## Artifacts

- `vlearn2-https-guide.md` (project root).

## Where to look for the raw conversation

`story_claude/260521_122356_vlearn2-https-guide.md`.
