---
title: "vLearn2 (VFLS) — System Design Specification"
subtitle: "Virtual Foreign Language — conversational language-learning platform"
author: "vLearn2 Engineering"
date: "2026-05-22"
---

# System Design Specification

**Project:** vLearn2 — marketed as *Virtual Foreign Language* (VFLS)
**Document type:** System Design Specification (SDS)
**Version:** 1.0 (Draft)
**Date:** 2026-05-22
**Source:** Derived from inspection of `C:\project\vLearn2`.

---

## 1. Introduction

### 1.1 Purpose

This document describes the technical design of the vLearn2 system — its
architecture, technology stack, data model, component design, and
deployment topology. It is the engineering reference for how the system
is built. *What* the system must do is covered separately in the
Requirements Specification; *how it is verified* is covered in the
Testing Specification.

### 1.2 Scope

vLearn2 is a conversational language-learning platform. End users
practise spoken and written English with persona-driven AI tutors,
receive automated scoring across speaking skills, and track their
progress, streaks, and achievements. Administrators manage content
(scenarios, personas, courses, news), users, AI prompt templates, and
runtime configuration through a web console.

The system comprises four delivered subsystems:

1. **Flutter app** — the learner-facing client for Android and Windows.
2. **Backend API** — a NestJS service exposing the REST API.
3. **Admin panel** — a Next.js web console for staff.
4. **DataManage tool** — a Win32 C++ utility that packages speech-model
   bundles (`.ddp`) consumed by the Flutter app.

A PostgreSQL database backs the system.

### 1.3 Definitions and acronyms

| Term | Meaning |
|------|---------|
| VFLS | Virtual Foreign Language — the product name in shipping artifacts |
| Persona | An AI tutor character (accent, style, specialties, avatar) |
| Scenario | A structured role-play conversation exercise |
| Course | An ordered collection of scenarios |
| Session | One conversation instance between a learner and a tutor |
| `.ddp` | DataManage Package — a signed, optionally encrypted/compressed model bundle |
| RBAC | Role-Based Access Control |
| STT / TTS | Speech-to-Text / Text-to-Speech |
| XP | Experience points awarded to learners |
| JWT | JSON Web Token |
| SDS / SRS | System Design / Software Requirements Specification |

### 1.4 References

- vLearn2 repository `README.md` and per-subsystem `README.md` files.
- Backend OpenAPI specification served at `/api/docs`.
- Requirements Specification (`vLearn2_Requirements_Specification`).
- Testing Specification (`vLearn2_Testing_Specification`).

---

## 2. System overview

vLearn2 follows a classic three-tier structure with an additional
offline asset-packaging pipeline:

- **Presentation tier** — the Flutter app (learners) and the Next.js
  admin panel (staff).
- **Application tier** — the NestJS backend, which owns all business
  logic, authentication, AI orchestration, and persistence.
- **Data tier** — PostgreSQL 16.
- **Asset pipeline** — the DataManage C++ tool builds `.ddp` speech-model
  bundles offline; the Flutter app verifies and unpacks them on-device.

All client–server communication is REST over HTTP/HTTPS. In production
an nginx reverse proxy terminates TLS and routes traffic to the two
Node services.

### 2.1 Context diagram

```
        ┌──────────────┐         ┌──────────────────┐
        │  Learner     │         │  Administrator   │
        │  (Flutter:   │         │  (browser)       │
        │  Android,    │         │                  │
        │  Windows)    │         │                  │
        └──────┬───────┘         └────────┬─────────┘
               │ HTTPS                    │ HTTPS
               │ /vfls/*                  │ /vAdmin/*
               ▼                          ▼
        ┌───────────────────────────────────────────┐
        │             nginx reverse proxy           │
        │   /vfls/*  → backend  /api/*               │
        │   /vAdmin/* → admin panel                  │
        └───────┬──────────────────────┬─────────────┘
                │                      │
                ▼                      ▼
        ┌───────────────┐      ┌────────────────┐
        │ NestJS backend│◄────►│ Next.js admin  │
        │  (REST API)   │ rew. │  panel         │
        └───────┬───────┘      └────────────────┘
                │
        ┌───────┼────────────────────┐
        ▼       ▼                    ▼
   ┌─────────┐ ┌──────────────┐ ┌──────────────┐
   │Postgres │ │ AI provider  │ │ File storage │
   │  16     │ │ (Anthropic / │ │ (local / S3) │
   │         │ │  OpenAI-cmp) │ │              │
   └─────────┘ └──────────────┘ └──────────────┘

   Offline:  DataManage (C++) ──builds──► .ddp bundle ──► Flutter unpacks
```

### 2.2 Subsystem responsibilities

| Subsystem | Responsibility |
|-----------|----------------|
| Flutter app | Learner UX, conversation UI (chat + tutor "face" mode), on-device speech (STT/TTS), offline read cache, `.ddp` model install |
| Backend API | Authentication, RBAC, all domain logic, AI orchestration, scoring, persistence, file uploads, OpenAPI docs |
| Admin panel | Staff console for content, users, prompts, audit, runtime config |
| DataManage | Offline packaging of speech-model bundles into signed `.ddp` files |
| PostgreSQL | System of record for all persistent data |

---

## 3. Architecture

### 3.1 Architectural style

- **Backend:** modular monolith. NestJS organises domain logic into 14
  feature modules behind one deployable process. A global JWT guard
  makes every route protected by default; routes opt out with a
  `@Public()` decorator.
- **Admin panel:** server-rendered React via the Next.js App Router,
  with client components for interactive pages. It is a thin client of
  the backend API.
- **Flutter app:** layered client — `core/` (infrastructure:
  networking, storage, routing, speech, datapack) and `features/`
  (screen-level feature modules), with Riverpod providers as the
  composition layer.
- **DataManage:** standalone native tool, not deployed with the
  services.

### 3.2 Backend module structure

The backend (`backend/src/`) is composed of these NestJS modules,
registered in `app.module.ts`:

| Module | Responsibility |
|--------|----------------|
| `AuthModule` | Learner sign-up / sign-in / refresh / sign-out, JWT issuance |
| `UsersModule` | Learner profile read/update |
| `PersonasModule` | AI tutor persona catalog |
| `ScenariosModule` | Role-play scenario catalog |
| `CategoriesModule` | Scenario categories |
| `CoursesModule` | Course catalog (ordered scenario sets) |
| `ConversationsModule` | Conversation sessions, messages, scoring |
| `ProgressModule` | Progress, skill snapshots, completions |
| `AchievementsModule` | Achievement catalog and awards |
| `AiModule` | AI provider abstraction, prompt building, orchestration |
| `GuardModule` (global) | Content-safety guard |
| `AdminModule` (global) | All admin/staff functionality and RBAC |
| `AppConfigModule` | Runtime configuration flags |
| `NewsModule` | In-app news/announcements |

A root `HealthController` exposes an unauthenticated liveness endpoint.

### 3.3 Request pipeline (backend)

Incoming requests pass through, in order:

1. `helmet` security headers and `compression` (gzip).
2. Global `ValidationPipe` (`whitelist`, `forbidNonWhitelisted`,
   `transform`) — rejects unknown fields and coerces DTO types.
3. Global `JwtAuthGuard` (`APP_GUARD`) — authenticates every request
   unless the handler is `@Public()`.
4. Global `ThrottlerGuard` — rate limiting (default 120 requests / 60 s).
5. `PermissionGuard` on admin routes — RBAC enforcement.
6. Controller → service → repository (TypeORM) → PostgreSQL.

The global API prefix is `/api`, excluding `health` and `uploads/(.*)`.

### 3.4 Deployment topology

| Component | Process | Default port | Public path (via nginx) |
|-----------|---------|--------------|--------------------------|
| Backend API | `node dist/main` | 3000 (dev) / 4101 (service script) | `/vfls/*` → rewritten to `/api/*` |
| Admin panel | `next start` | 4100 (dev) / 5101 (service script) | `/vAdmin/*` |
| PostgreSQL | `postgres:16-alpine` | 5432 | internal only |

> **Note — port inconsistency.** The startup scripts in `cmds/` carry
> conflicting default-port values between the Windows `.bat`, the Linux
> `.sh`, and their documentation. This should be reconciled to a single
> canonical mapping. See §11.

nginx terminates TLS, serves the admin panel under `/vAdmin/`, and maps
`/vfls/*` to the backend's `/api/*`. Services are managed in production
via `pm2` (notes under `cmds/pm2_things/`) or the `nohup`-based
`start_service_linux.sh`.

---

## 4. Technology stack

### 4.1 Backend

| Concern | Technology |
|---------|-----------|
| Runtime | Node.js 22+ |
| Framework | NestJS 11 (`@nestjs/common`, `core`, `platform-express`) |
| Language | TypeScript 5.7 |
| ORM | TypeORM 0.3.29 |
| Database driver | `pg` 8.20 |
| Authentication | `@nestjs/jwt`, `@nestjs/passport`, `passport-jwt`, `passport-local`, `bcrypt` |
| Validation | `class-validator`, `class-transformer` |
| AI | `@anthropic-ai/sdk`, `openai` |
| API docs | `@nestjs/swagger` |
| Rate limiting | `@nestjs/throttler` |
| Security / perf | `helmet`, `compression` |
| i18n | `nestjs-i18n` |
| Image processing | `sharp` |
| Testing | Jest 30, `ts-jest`, `supertest` |

### 4.2 Admin panel

| Concern | Technology |
|---------|-----------|
| Framework | Next.js 14.2 (App Router) |
| UI library | React 18.3 |
| Language | TypeScript 5.5 |
| Data fetching | TanStack Query 5 |
| Tables | TanStack Table 8 |
| Forms / validation | React Hook Form 7, Zod 3 |
| Charts | Recharts 2 |
| Styling | Tailwind CSS 3.4, `class-variance-authority`, `clsx` |
| Icons | `lucide-react` |
| Testing | Jest 30, `ts-jest` |

### 4.3 Flutter app

| Concern | Technology |
|---------|-----------|
| SDK | Dart 3.11; Flutter 3.41+ |
| State management | Riverpod 2 (`flutter_riverpod`, `riverpod_annotation`) |
| Navigation | `go_router` 14 |
| Networking | `dio` 5 (with `retrofit` declared but not yet wired) |
| Local database | `drift` 2 (SQLite) |
| Models / codegen | `freezed`, `json_serializable`, `build_runner` |
| Secure storage | `flutter_secure_storage` |
| Preferences | `shared_preferences` |
| Speech | `sherpa_onnx` (STT/TTS), `record` (mic), `audioplayers` (playback) |
| Animation | `rive` |
| Charts | `fl_chart` |
| i18n | `intl`, generated `app_localizations` (English, Chinese) |
| `.ddp` crypto | `pointycastle`, `archive`, `asn1lib` |

### 4.4 DataManage tool

Win32 C++ GUI/CLI application. Vendors `zlib` (compression), `mbedTLS`
(crypto/signing), and a JSON library. Produces signed, optionally
encrypted and compressed `.ddp` bundles.

---

## 5. Data design

### 5.1 Overview

PostgreSQL 16 is the system of record. Persistence uses TypeORM with 26
entities. Most tables carry a `vl_` prefix; primary keys are UUIDs
generated by `gen_random_uuid()` (pgcrypto). Schema evolution is managed
by 13 ordered migration files; a seed runner populates baseline
achievements, app-config, courses, personas, and scenarios.

Localized text fields are stored as JSONB (`I18nText`) to support
multi-language content.

### 5.2 Entity groups

**Identity & access**

| Entity | Table | Purpose |
|--------|-------|---------|
| `UserEntity` | `users` | Learner account (credentials, name, CID) |
| `UserInfoEntity` | `vl_user_info` | Learner profile (email, level, XP, streak, role, status, preferences) |
| `RefreshTokenEntity` | `vl_refresh_tokens` | Hashed learner refresh tokens |
| `AdminEntity` | `vl_admins` | Staff account |
| `AdminRefreshTokenEntity` | `vl_admin_refresh_tokens` | Hashed admin refresh tokens |
| `AdminPermissionEntity` | `vl_admin_permissions` | Per-admin granted permissions |
| `AdminAuditLogEntity` | `vl_admin_audit_log` | Immutable record of admin actions |

**Learning content**

| Entity | Table | Purpose |
|--------|-------|---------|
| `PersonaEntity` | `vl_personas` | AI tutor characters |
| `CategoryEntity` | `vl_categories` | Scenario categories |
| `ScenarioEntity` | `vl_scenarios` | Role-play exercises |
| `CourseEntity` | `vl_courses` | Ordered scenario collections |
| `CourseScenarioEntity` | `vl_course_scenarios` | Course↔scenario join |
| `PromptTemplateEntity` | `vl_prompt_templates` | Editable AI prompt templates |

**Conversations & scoring**

| Entity | Table | Purpose |
|--------|-------|---------|
| `ConversationSessionEntity` | `vl_conversation_sessions` | One conversation instance |
| `ConversationMessageEntity` | `vl_conversation_messages` | Messages within a session |
| `SessionScoreEntity` | `vl_session_scores` | Per-session multi-skill scores |

**Progress & gamification**

| Entity | Table | Purpose |
|--------|-------|---------|
| `UserProgressEntity` | `vl_user_progress` | Aggregate learner progress |
| `SkillSnapshotEntity` | `vl_skill_snapshots` | Daily per-skill snapshots |
| `UserScenarioCompletionEntity` | `vl_user_scenario_completions` | Per-scenario completion records |
| `AchievementEntity` | `vl_achievements` | Achievement catalog |
| `UserAchievementEntity` | `vl_user_achievements` | Achievements earned by a learner |

**Platform**

| Entity | Table | Purpose |
|--------|-------|---------|
| `AppConfigEntity` | `vl_app_config` | Runtime configuration flags |
| `NewsPostEntity` | `vl_news_posts` | In-app announcements |
| `NewsReadStatusEntity` | `vl_news_read_status` | Per-user news read state |
| `GuardViolationEntity` | `vl_guard_violations` | Content-safety violation log |
| `UploadedFileEntity` | `vl_uploaded_files` | Uploaded file metadata, ref-counted |

### 5.3 Key relationships

- `UserEntity` 1—1 `UserInfoEntity` (eager, cascade, `ON DELETE CASCADE`).
- `UserEntity` 1—N `RefreshTokenEntity`.
- `ScenarioEntity` N—1 `CategoryEntity` (`ON DELETE RESTRICT`).
- `CourseEntity` N—M `ScenarioEntity` via `CourseScenarioEntity` (ordered).
- `ConversationSessionEntity` 1—N `ConversationMessageEntity`;
  1—1 `SessionScoreEntity`.
- `ConversationSessionEntity` references `ScenarioEntity` (nullable —
  null denotes free-talk) and `PersonaEntity`.
- `AdminEntity` 1—N `AdminRefreshTokenEntity`.

### 5.4 Enumerations

Enumerated values are stored as `varchar` and constrained at the
application layer:

- `UserRole`: `user | admin | superadmin`
- `UserStatus` / `AdminStatus`: `active | suspended | deleted`
- `AdminRole`: `admin | superadmin`
- `ScenarioStatus` / `CourseStatus` / `NewsStatus`: `draft | published | archived`
- `ConversationMode`: `chat | face`
- `SessionStatus`: `active | completed | abandoned`
- `MessageRole`: `user | assistant`
- `GuardSeverity`: `block | warn`; `GuardSource`: `client | server`
- `PromptKind`: `tutor_system | grammar | feedback`
- `AppConfigCategory`: `home | evaluation | progress | conversation | scenarios | settings | system`
- `AppConfigValueType`: `boolean | string | number | object | array`

---

## 6. Backend design

### 6.1 API surface

All endpoints are under the `/api` prefix (except `/health`). Every
route is JWT-protected unless marked public.

**Public**

- `GET /health` — liveness.
- `POST /api/auth/signup`, `POST /api/auth/signin`,
  `POST /api/auth/refresh` — learner authentication.
- `POST /api/admin/auth/signup`, `signin`, `refresh` — admin
  authentication.

**Learner-facing (JWT, `actor = user`)**

- `auth` — `signout`, `me`.
- `users` — `GET/PATCH /profile`.
- `personas` — list, get.
- `scenarios` — list (filterable), get by id/slug.
- `categories` — list.
- `courses` — list, get (with ordered scenarios).
- `conversations` — start session, list sessions, get session with
  messages, send message (+ tutor reply), end session, delete session,
  request a suggestion.
- `progress` — get progress, snapshots, completions; upsert daily
  snapshot.
- `achievements` — catalog, earned.
- `news` — list (paginated), unread count, mark read / read-all, get.
- `app-config` — app-visible configuration flags.

**Admin-facing (JWT `actor = admin` + `PermissionGuard`)**

- `admin/auth`, `admin/admins` (sub-admin and permission management),
  `admin/stats`, `admin/users`, `admin/scenarios`, `admin/personas`,
  `admin/categories`, `admin/leaderboard`, `admin/prompt-templates`,
  `admin/news`, `admin/audit`, `admin/config`.

The full route list is the authoritative OpenAPI spec at `/api/docs`.

### 6.2 Authentication and authorization

vLearn2 uses a **dual-actor JWT** model:

- A single JWT structure carries `sub` (subject id), identity claims,
  `role`, `permissions[]`, and an `actor` discriminator
  (`user` | `admin`) telling guards which table `sub` refers to.
- **Access tokens** are HS256-signed, short-lived (default 15 minutes).
- **Refresh tokens** are random 48-byte secrets, stored only as SHA-256
  hashes, single-use (rotated on every refresh), default lifetime
  7 days. Learners and admins use separate refresh-token tables.
- **Passwords** are bcrypt-hashed (10 rounds). Admin passwords have
  stronger composition rules (≥12 chars, mixed case + digit) than
  learner passwords (≥6 chars).
- **RBAC:** `PermissionGuard` enforces `@RequirePermission(...)` on
  admin routes against a permission catalog (~40 keys). `superadmin`
  bypasses all checks. Sub-admin permissions are resolved from
  `vl_admin_permissions`; privacy-sensitive permissions are not
  grantable to sub-admins.
- **Audit:** admin mutations are recorded in `vl_admin_audit_log`
  within the same database transaction as the change, so an audit
  entry and its change commit or roll back together.

### 6.3 AI orchestration

`AiModule` abstracts the LLM provider behind a factory
(`AiProviderFactory`) selecting Anthropic or an OpenAI-compatible
provider via the `AI_PROVIDER` env var. A `ConversationOrchestrator`
builds prompts from editable `PromptTemplateEntity` records, drives
tutor replies and idle-suggestion generation, and degrades gracefully:
on `AiProviderError` it returns canned fallback replies, and grammar
scoring falls back to algorithmic scoring when the model is
unavailable. A per-day cap (`MAX_AI_MESSAGES_PER_DAY`) limits AI usage.

> The opening tutor message in a new session is currently a hard-coded
> placeholder; full AI wiring of the session-open path is incomplete.
> See §11.

### 6.4 Content safety

The global `GuardModule` screens conversation content. Violations are
recorded in `vl_guard_violations` with severity (`block`/`warn`),
matched terms, language, and source (`client`/`server`). The Flutter
app also runs a client-side `content_guard`.

### 6.5 File uploads

Images (scenario and persona artwork) are uploaded through admin
endpoints, validated for MIME type (`jpeg`/`png`/`webp`) and size
(≤ 5 MB), processed with `sharp`, and recorded in `vl_uploaded_files`
with a content hash and reference count. Storage is pluggable
(`STORAGE_PROVIDER` = `local` | `s3`).

### 6.6 Configuration

Configuration is supplied via environment variables (`.env`) read
through `@nestjs/config`. Key groups: server (`PORT`,
`PUBLIC_BASE_URL`, `CORS_ORIGINS`), database (`DB_*`), JWT secrets and
lifetimes, AI provider settings, storage, throttling, and gzip.

---

## 7. Admin panel design

### 7.1 Routing

The admin panel uses the Next.js App Router with `basePath: /vAdmin`
and two route groups:

- `(auth)` — `/signin`, `/signup`.
- `(dashboard)` — shared sidebar layout with an auth gate; pages:
  dashboard, personas (+ new / edit), prompt-templates, scenarios
  (+ new), categories, users, news (+ new), leaderboard, audit, admins,
  config, settings.

### 7.2 Backend communication

A `fetch`-based API client (`src/lib/api.ts`) targets
`NEXT_PUBLIC_API_BASE_URL`, attaches the bearer token, and transparently
refreshes once on a 401 before retrying. `next.config.mjs` also defines
a server-side rewrite from `/api/backend/*` to the backend's `/api/*`.

### 7.3 Authentication

Admin access and refresh tokens are held in `sessionStorage`. The
dashboard layout performs a **client-side** gate (redirect to
`/signin` if the JWT is absent or the role is not `admin`/
`superadmin`); a `usePermission` hook hides UI for missing
permissions. **Server-side checks on the backend remain the
authoritative enforcement** — client gating is a UX convenience only.

---

## 8. Flutter app design

### 8.1 Layered structure

- **`core/`** — infrastructure: `api/` (Dio client + interceptors),
  `auth/`, `config/`, `datapack/` (`.ddp` unpacker), `db/` (Drift),
  `guard/`, `models/`, `providers/`, `router/` (`go_router`),
  `services/`, `speech/` (recorder + sherpa-onnx STT/TTS), `storage/`,
  `theme/`, `utils/`.
- **`features/`** — screen-level modules: `splash`, `auth`,
  `onboarding`, `home`, `scenarios`, `conversation`, `course`,
  `report`, `progress`, `news`, `settings`, `setup`.
- **`l10n/`** — generated localizations (English, Chinese).
- **`shared/`** — shared widgets (app shell, score ring, etc.).

### 8.2 State management

Riverpod is used throughout. `main.dart` warms `appConfigProvider`
before `runApp`. Central providers include `authProvider` (a state
machine: `checking → signedOut | signedIn`), `appSettingsProvider`,
`routerProvider`, and `apiClientProvider`.

### 8.3 Navigation

`go_router` defines routes for splash, auth, onboarding, the five-tab
shell (home, scenarios, conversation history, progress, settings),
fullscreen conversation, session report, courses, news, and the
speech-model setup screen. A redirect handler enforces authentication
gating, onboarding completion, and a speech-model gate that diverts to
`/setup/models` when a conversation is started without an installed
model bundle (unless the learner has acknowledged text-only mode).

### 8.4 Networking

A `dio` client is built per `apiClientProvider`. Its base URL is read
at runtime from an on-device `app_config.json` file, overridable at
build time via `--dart-define=API_BASE_URL`. Interceptors run in order:
compression, auth (bearer attach + auto-refresh + forced sign-out on
invalid session), request logging (debug only), error normalization.

### 8.5 Local storage and offline behaviour

- **`flutter_secure_storage`** — JWT access/refresh tokens (with an
  in-memory cache layer to avoid a Windows stale-read race) and
  remembered credentials.
- **`shared_preferences`** — synchronous settings cache (theme,
  language, fonts, conversation defaults).
- **Drift (SQLite)** — `vlearn2.sqlite` with 8 tables caching users,
  scenarios, sessions, messages, progress, settings, and layout
  configuration for offline read-only flows.

### 8.6 Speech and model packaging

On-device STT/TTS uses `sherpa_onnx`. Real engines activate only when a
verified model bundle is present; otherwise placeholder no-op services
are used. Model bundles are produced offline by the DataManage tool as
signed `.ddp` files and unpacked on a background isolate using pure-Dart
crypto. The committed root CA certificate (`assets/datamanage/
root_ca.crt`) anchors signature verification.

### 8.7 Platform specifics

- **Android** — package `com.ryongma.vfls`, `minSdk 24`, `targetSdk
  35`, ABIs `arm64-v8a` + `x86_64`. Permissions: internet, microphone,
  and storage (for the shared config folder). Release builds are
  currently signed with debug keys (see §11).
- **Windows** — standard Win32 C++ runner; native splash screen.

---

## 9. Cross-cutting concerns

### 9.1 Logging

- **Backend** — NestJS `Logger`; optional TypeORM query logging via
  `DB_LOGGING`.
- **Flutter** — the `logger` package; debug-only request logging after
  the bearer header is attached.
- **Admin** — relies on Next.js / browser defaults.

### 9.2 Error handling

- **Backend** — typed NestJS HTTP exceptions carrying an `i18nKey` for
  `nestjs-i18n` translation. Admin mutations run inside database
  transactions.
- **Flutter** — a `PoliteError` layer translates raw failures into
  user-safe messages; the Dio error interceptor normalizes failures;
  invalid sessions trigger a forced sign-out; offline failures fall
  back to the Drift cache.

### 9.3 Internationalization

Localized content is stored as JSONB `I18nText`. The backend translates
error keys with `nestjs-i18n`. The Flutter app ships English and
Chinese localizations.

### 9.4 Security

- TLS terminated at nginx; HSTS and security headers via `helmet`.
- CORS restricted to `CORS_ORIGINS` with credentials enabled.
- Secrets supplied via environment variables; example files ship
  placeholders only.
- bcrypt password hashing; hashed, single-use refresh tokens; separate
  learner/admin token stores; global rate limiting.
- `.ddp` bundles are cryptographically signed; the Flutter app pins the
  root CA.

---

## 10. Deployment architecture

### 10.1 Build

| Subsystem | Build command | Artifact |
|-----------|---------------|----------|
| Backend | `npm run build` (`nest build`) | `dist/` |
| Admin panel | `npm run build` (`next build`) | `.next/` |
| Flutter (Android) | `flutter build apk --release` | signed APK |
| Flutter (Windows) | `flutter build windows --release` | Windows bundle |

### 10.2 Runtime

Production runs the two Node services behind nginx, started via the
`cmds/` launchers or `pm2`. PostgreSQL runs as a managed service or the
provided `docker-compose.yml` (development).

### 10.3 Continuous integration

GitHub Actions workflows (path-filtered) build and test each subsystem:

- `backend_ci.yml` — Node 22, ephemeral PostgreSQL service, lint,
  build, unit tests, non-blocking e2e, coverage artifact.
- `admin_ci.yml` — Node 20, lint, typecheck, `next build`.
- `flutter_ci.yml` — Flutter 3.41.9, format check, analyze, test, debug
  Android + Windows builds.

> CI triggers on `master`/`dev`. The repository's primary branch is
> `main`; the trigger branches should be aligned. See §11.

---

## 11. Known limitations and technical debt

The following are recorded for design transparency and should be
tracked for resolution:

1. **AI session-open path partly stubbed** — a new conversation's
   opening tutor message is a hard-coded placeholder.
2. **Gzip runtime kill-switch disabled** — the compression filter's
   `system.gzip_enabled` flag / `GZIP_ENABLED` env checks are commented
   out, so they have no runtime effect.
3. **Speech engines gated** — STT/TTS use placeholder no-op services
   until a verified `.ddp` model bundle is installed.
4. **Retrofit unused** — declared as a Flutter dependency but no
   Retrofit clients are generated; API calls are hand-written Dio code.
5. **Android release signing** — release builds are signed with debug
   keys; a production keystore is required before release.
6. **CI branch mismatch** — workflows trigger on `master`/`dev` but the
   main branch is `main`.
7. **Startup-script port inconsistency** — `cmds/` launchers disagree
   on default backend/admin ports.
8. **Open admin signup** — `POST /admin/auth/signup` is intentionally
   unauthenticated for bootstrap (first signup → superadmin); it must
   be gated before any public deployment.
9. **Admin token storage** — admin tokens live in `sessionStorage`,
   exposing them to XSS; a documented trade-off versus httpOnly
   cookies.
10. **Documentation drift** — several READMEs are stale (admin "pages
    today" list, DataManage stage count).
11. **Stray directory** — a nested `backend/flutter_app/` duplicate
    exists and should be removed.

---

*End of System Design Specification.*
