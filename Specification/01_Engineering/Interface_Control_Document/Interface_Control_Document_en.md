---
title: "vLearn2 (VFLS) — Interface Control Document"
author: "vLearn2 Engineering"
date: "2026-05-22"
---

# Interface Control Document

**Project:** vLearn2 (VFLS) · **Version:** 1.0 · **Date:** 2026-05-22

---

## 1. Purpose

This document defines the interfaces between vLearn2 subsystems and
external systems — their protocols, data formats, and contracts — so
that each side can be developed and changed against a stable agreement.

## 2. Interface inventory

| ID | From | To | Protocol |
|----|------|----|----------|
| IF-1 | Flutter app | Backend API | HTTPS / REST |
| IF-2 | Admin panel (browser) | Backend API | HTTPS / REST |
| IF-3 | Admin panel (server) | Backend API | HTTP(S) / REST (rewrite proxy) |
| IF-4 | Backend | PostgreSQL | TCP / SQL (TypeORM) |
| IF-5 | Backend | AI provider | HTTPS / vendor SDK |
| IF-6 | Backend | File storage | Local FS or S3 API |
| IF-7 | DataManage tool | Flutter app | `.ddp` file (offline artifact) |
| IF-8 | Clients | nginx | HTTPS (TLS termination) |

---

## 3. IF-1 — Flutter app ↔ Backend API

- **Protocol:** REST over HTTPS; JSON bodies.
- **Public path:** `https://<host>/vfls/*`, mapped by nginx to
  `/api/*`.
- **Auth:** `Authorization: Bearer <access token>`; refresh via
  `POST /vfls/auth/refresh`.
- **Base URL config:** read at runtime from `app_config.json`
  (`baseurl`); build-time override `--dart-define=API_BASE_URL`.
- **Error contract:** non-2xx bodies include an `i18nKey`; the app maps
  failures to user-safe messages.
- **Versioning:** the OpenAPI spec at `/api/docs` is the contract of
  record.

## 4. IF-2 / IF-3 — Admin panel ↔ Backend API

- **IF-2 (browser):** `fetch`-based client to
  `NEXT_PUBLIC_API_BASE_URL`; bearer token from `sessionStorage`;
  automatic one-shot refresh on `401`.
- **IF-3 (server):** Next.js rewrite — `/api/backend/*` →
  `${BACKEND_BASE_URL}/api/*` — for server-side calls.
- **Auth:** admin JWT (`actor=admin`) + permission checks server-side.

## 5. IF-4 — Backend ↔ PostgreSQL

- **Protocol:** PostgreSQL wire protocol via the `pg` driver, managed
  by TypeORM.
- **Connection:** `DB_HOST/PORT/NAME/USER/PASSWORD`.
- **Schema contract:** 26 entities; evolution only through ordered
  migrations (see Database Design Document).
- **Integrity:** `ON DELETE CASCADE` (user info), `ON DELETE RESTRICT`
  (scenario category).

## 6. IF-5 — Backend ↔ AI provider

- **Protocol:** HTTPS via vendor SDK (`@anthropic-ai/sdk` or `openai`).
- **Selection:** `AI_PROVIDER` env (`anthropic` |
  `openai-compatible`); models via `AI_CHAT_MODEL` /
  `AI_ANALYSIS_MODEL`.
- **Auth:** API key (`ANTHROPIC_API_KEY` / `OPENAI_API_KEY`).
- **Failure contract:** on `AiProviderError`, the backend returns
  canned fallback replies and uses algorithmic grammar scoring — the
  client interface is unaffected.
- **Quota:** `MAX_AI_MESSAGES_PER_DAY` per learner.

## 7. IF-6 — Backend ↔ File storage

- **Protocol:** local filesystem or S3 API, by `STORAGE_PROVIDER`.
- **Inputs:** images `jpeg`/`png`/`webp`, ≤ 5 MB.
- **Contract:** stored objects keyed by `storage_key`; metadata in
  `vl_uploaded_files`; static files served from `/uploads/`.

## 8. IF-7 — DataManage ↔ Flutter app

- **Artifact:** `.ddp` bundle — signed, optionally encrypted and
  compressed.
- **Producer:** DataManage Win32 tool (offline).
- **Consumer:** the Flutter app's `core/datapack/` unpacker, on a
  background isolate.
- **Trust contract:** the app pins `root_ca.crt`; a bundle whose
  signature does not verify against the pinned CA is rejected.
- **Transfer:** out of band (download / sideload) — not a network API.

## 9. IF-8 — Clients ↔ nginx

- **Protocol:** HTTPS; nginx terminates TLS.
- **Routing contract:** `/vfls/*` → backend, `/vAdmin/*` → admin
  panel; HTTP `301`-redirects to HTTPS.
- **Headers:** `X-Forwarded-Proto`, `X-Forwarded-For`, `Host` passed
  upstream.

## 10. Change control

Any change to an interface contract (a route, a payload shape, an env
variable name, the `.ddp` format, the nginx path mapping) requires:

1. Updating this document and the affected detailed spec
   (API Reference / Database Design Document).
2. A compatibility assessment for every consumer of that interface.
3. Coordinated release where producer and consumer must move together.

---

*End of Interface Control Document.*
