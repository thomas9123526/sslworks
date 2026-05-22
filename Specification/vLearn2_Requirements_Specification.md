---
title: "vLearn2 (VFLS) — Requirements Specification"
subtitle: "Virtual Foreign Language — conversational language-learning platform"
author: "vLearn2 Engineering"
date: "2026-05-22"
---

# Software Requirements Specification

**Project:** vLearn2 — marketed as *Virtual Foreign Language* (VFLS)
**Document type:** Software Requirements Specification (SRS)
**Version:** 1.0 (Draft)
**Date:** 2026-05-22
**Source:** Reconstructed from the implemented behaviour of `C:\project\vLearn2`.

---

## 1. Introduction

### 1.1 Purpose

This document specifies the functional and non-functional requirements
of the vLearn2 system. It defines *what* the system does, for whom, and
under what constraints. The companion System Design Specification
describes *how* the system is built; the Testing Specification defines
how requirements are verified.

Because the system already exists, this SRS is reconstructed from the
implemented behaviour and is intended as a baseline for maintenance,
regression testing, and future change control.

### 1.2 Scope

vLearn2 is a conversational language-learning platform for practising
English. Learners hold spoken or written conversations with AI tutor
personas — either free-form or structured around role-play scenarios —
and receive automated multi-skill scoring, progress tracking, streaks,
and achievements. Staff manage learning content, users, AI prompts,
and runtime configuration through a web admin console.

The product is delivered as a Flutter app (Android and Windows), a
NestJS backend API, a Next.js admin panel, and an offline DataManage
packaging tool, backed by PostgreSQL.

### 1.3 Definitions and acronyms

| Term | Meaning |
|------|---------|
| Learner | An end user of the Flutter app |
| Administrator / Sub-admin / Superadmin | Staff users of the admin panel, by privilege level |
| Persona | An AI tutor character |
| Scenario | A structured role-play conversation exercise |
| Course | An ordered set of scenarios |
| Session | One conversation between a learner and a tutor |
| Free talk | A session not bound to a scenario |
| XP | Experience points |
| Streak | Consecutive days of activity |
| FR / NFR | Functional / Non-Functional Requirement |
| `.ddp` | Signed speech-model bundle produced by DataManage |

### 1.4 References

- vLearn2 System Design Specification.
- vLearn2 Testing Specification.
- Backend OpenAPI specification (`/api/docs`).

### 1.5 Requirement notation

Functional requirements are identified `FR-<area>-<n>` and
non-functional requirements `NFR-<category>-<n>`. The keyword **shall**
denotes a mandatory requirement.

---

## 2. Overall description

### 2.1 Product perspective

vLearn2 is a self-contained client–server product. The Flutter app and
admin panel are clients of a single backend API; the backend integrates
with an external AI provider (Anthropic or an OpenAI-compatible
service) and a file-storage backend (local disk or S3). PostgreSQL is
the system of record. The DataManage tool operates offline to package
speech models.

### 2.2 User classes

| User class | Description | Primary interface |
|------------|-------------|-------------------|
| Learner | Practises language; tracks progress | Flutter app |
| Sub-admin | Staff with a granted subset of permissions | Admin panel |
| Administrator | Staff with broad content/user permissions | Admin panel |
| Superadmin | Unrestricted staff; manages other admins | Admin panel |
| Content packager | Builds speech-model bundles | DataManage tool |

### 2.3 Operating environment

- **Flutter app:** Android (minimum SDK 24) and Windows desktop.
- **Admin panel:** modern desktop web browsers.
- **Backend:** Node.js 22+ on Linux (RHEL-class) or Windows.
- **Database:** PostgreSQL 16.
- **Reverse proxy:** nginx terminating TLS.

### 2.4 Design and implementation constraints

- The backend exposes a REST API under the `/api` prefix; nginx maps the
  public `/vfls/*` path to it and serves the admin panel under
  `/vAdmin/*`.
- Authentication uses JWT access tokens with rotating refresh tokens.
- Localized content shall support multiple languages (English and
  Chinese are currently shipped in the app).
- The Flutter app shall function in read-only mode when offline, using
  a local cache.
- On-device speech requires an installed, signed `.ddp` model bundle.

### 2.5 Assumptions and dependencies

- A reachable AI provider is required for live tutor replies and
  AI-based scoring; the system degrades to fallback behaviour when it is
  unavailable.
- Learners installing speech models have access to a valid `.ddp`
  bundle.
- Network connectivity is available for all write operations.

---

## 3. Functional requirements

### 3.1 Authentication and accounts

**FR-AUTH-1** — The system shall allow a learner to create an account
by providing the required credentials and profile fields; learner
passwords shall be at least 6 characters.

**FR-AUTH-2** — The system shall allow a learner to sign in and receive
a short-lived access token and a refresh token.

**FR-AUTH-3** — The system shall allow a client to exchange a valid
refresh token for a new access token; each refresh token shall be
single-use and rotated on exchange.

**FR-AUTH-4** — The system shall allow a learner to sign out,
invalidating the current refresh token.

**FR-AUTH-5** — The system shall reject expired or invalid tokens and
require re-authentication.

**FR-AUTH-6** — The Flutter app shall optionally remember a learner's
credentials for convenience, at the learner's choice.

**FR-AUTH-7** — The system shall allow an administrator to create an
account; admin passwords shall be at least 12 characters and contain
lower-case, upper-case, and digit characters.

**FR-AUTH-8** — The first admin account created shall be assigned the
`superadmin` role; subsequent admin accounts shall default to `admin`.

### 3.2 Learner profile

**FR-PROF-1** — The system shall allow a learner to view their profile,
including level, total XP, streak, and preferences.

**FR-PROF-2** — The system shall allow a learner to update display
name, avatar, gender, native/UI language, theme, and active persona.

**FR-PROF-3** — The system shall allow a learner to change their
password, requiring proof of the current password.

**FR-PROF-4** — The system shall record whether a learner has completed
onboarding and present onboarding only until completed.

### 3.3 Learning content browsing

**FR-CONT-1** — The system shall present a catalog of active AI tutor
personas, each with accent, style, specialties, and avatar.

**FR-CONT-2** — The system shall present a catalog of published
scenarios, filterable by category, difficulty, and free-text query.

**FR-CONT-3** — The system shall present scenario detail including
scene description, roles, objectives, key phrases, estimated duration,
and XP reward.

**FR-CONT-4** — The system shall present active scenario categories.

**FR-CONT-5** — The system shall present published courses and, for a
selected course, its scenarios in defined order.

**FR-CONT-6** — Content text shall be presented in the learner's
selected language where localized text is available.

### 3.4 Conversation sessions

**FR-CONV-1** — The system shall allow a learner to start a conversation
session by selecting a persona and, optionally, a scenario; a session
without a scenario is a free-talk session.

**FR-CONV-2** — The system shall support two conversation modes: text
chat and a tutor "face" mode with an animated avatar.

**FR-CONV-3** — The system shall accept a learner message (1–5000
characters) and return an AI tutor reply.

**FR-CONV-4** — The system shall persist all session messages with role
and sequence ordering.

**FR-CONV-5** — The system shall allow a learner to request a suggested
prompt when idle.

**FR-CONV-6** — The system shall allow a learner to end a session,
recording duration, turn count, word count, and XP earned.

**FR-CONV-7** — The system shall allow a learner to list and re-open
their past sessions, and to delete a session.

**FR-CONV-8** — When the AI provider is unavailable, the system shall
return a graceful fallback reply rather than an error, so the
conversation remains usable.

**FR-CONV-9** — The system shall enforce a configurable daily limit on
AI-backed messages per learner.

### 3.5 Scoring and feedback

**FR-SCORE-1** — The system shall produce a per-session score covering
overall, pronunciation, fluency, vocabulary, grammar, engagement, and
listening dimensions, where applicable to the session.

**FR-SCORE-2** — The system shall produce per-session feedback
including strengths and improvement areas.

**FR-SCORE-3** — When AI grammar scoring is unavailable, the system
shall fall back to algorithmic scoring.

**FR-SCORE-4** — The system shall present a session report to the
learner after a session ends.

### 3.6 Progress, streaks, and gamification

**FR-PROG-1** — The system shall maintain aggregate learner progress:
total sessions, sessions this week, minutes spoken, words spoken,
scenarios completed, current streak, and longest streak.

**FR-PROG-2** — The system shall maintain daily per-skill snapshots
(pronunciation, fluency, listening, vocabulary, grammar) with a
running-averaged update for the current day.

**FR-PROG-3** — The system shall record per-scenario completions,
including best score and completion count.

**FR-PROG-4** — The system shall award XP for completed activity and
maintain a learner level derived from XP.

**FR-PROG-5** — The system shall maintain an achievement catalog and
award achievements to learners when defined conditions are met.

**FR-PROG-6** — The system shall allow a learner to view the
achievement catalog and the achievements they have earned.

### 3.7 News and announcements

**FR-NEWS-1** — The system shall present in-app news posts to learners,
paginated, with pinned posts surfaced.

**FR-NEWS-2** — The system shall track per-learner read status and
report an unread count.

**FR-NEWS-3** — The system shall allow a learner to mark an individual
post, or all posts, as read.

### 3.8 Application configuration

**FR-CFG-1** — The system shall expose app-visible configuration flags
to the Flutter app so that feature visibility can be controlled
centrally.

### 3.9 Offline behaviour (Flutter app)

**FR-OFF-1** — The Flutter app shall cache users, scenarios, sessions,
messages, progress, settings, and layout configuration locally.

**FR-OFF-2** — When the device is offline, the app shall serve cached
read-only content and present user-safe messaging instead of raw
errors.

**FR-OFF-3** — The app shall store authentication tokens in secure
device storage.

### 3.10 On-device speech

**FR-SPCH-1** — The app shall support speech-to-text input and
text-to-speech playback when a verified speech-model bundle is
installed.

**FR-SPCH-2** — When no verified model bundle is installed, the app
shall divert the learner to a model-setup screen before starting a
speech-enabled conversation, unless the learner has explicitly
acknowledged text-only mode.

**FR-SPCH-3** — The app shall verify the cryptographic signature of a
`.ddp` model bundle against the pinned root CA before installing it.

### 3.11 Administration — content management

**FR-ADM-1** — The system shall allow authorized staff to create, edit,
publish, archive, and delete scenarios.

**FR-ADM-2** — The system shall allow authorized staff to create, edit,
soft-delete, and restore personas.

**FR-ADM-3** — The system shall allow authorized staff to create, edit,
and delete categories; deletion shall be refused if the category is in
use.

**FR-ADM-4** — The system shall allow authorized staff to upload
scenario and persona images, validated for type (`jpeg`/`png`/`webp`)
and size (≤ 5 MB).

**FR-ADM-5** — The system shall allow authorized staff to create, edit,
publish, archive, and delete news posts.

**FR-ADM-6** — The system shall allow authorized staff to view and edit
AI prompt templates (tutor-system, grammar, feedback).

### 3.12 Administration — users and analytics

**FR-ADM-7** — The system shall allow authorized staff to list and view
learner accounts.

**FR-ADM-8** — The system shall allow authorized staff to suspend and
restore learner accounts and to reset a learner's password.

**FR-ADM-9** — The system shall present summary statistics: total
users, users active in the last 30 days, total sessions, and published
scenarios.

**FR-ADM-10** — The system shall present a learner leaderboard ranked
by a selectable metric (total XP, streak days, or level).

### 3.13 Administration — staff and governance

**FR-ADM-11** — The system shall allow a superadmin to create
sub-admin accounts and grant or revoke individual permissions.

**FR-ADM-12** — The system shall restrict privacy-sensitive permissions
so they cannot be granted to sub-admins.

**FR-ADM-13** — The system shall allow a superadmin to suspend,
restore, and soft-delete admin accounts.

**FR-ADM-14** — The system shall record every administrative mutation
in an immutable audit log capturing actor, action, target, and
before/after values, and shall allow authorized staff to search it.

**FR-ADM-15** — The system shall allow authorized staff to view and
edit runtime configuration flags, reset individual flags to default,
and (superadmin only) reset all flags.

**FR-ADM-16** — The admin panel shall enforce role/permission-based
visibility of UI features; the backend shall enforce authorization
authoritatively regardless of client-side gating.

### 3.14 Content safety

**FR-SAFE-1** — The system shall screen conversation content for
disallowed material and record violations with severity, matched
terms, language, and source.

**FR-SAFE-2** — The Flutter app shall additionally apply a client-side
content guard.

### 3.15 Model packaging (DataManage)

**FR-PKG-1** — The DataManage tool shall package a directory of files
into a single `.ddp` bundle.

**FR-PKG-2** — The tool shall cryptographically sign each bundle and
shall optionally encrypt and/or compress it.

**FR-PKG-3** — The tool shall operate via a GUI and an optional CLI
mode.

---

## 4. External interface requirements

### 4.1 User interfaces

- **Flutter app** — a five-tab interface (home, scenarios, conversation
  history, progress, settings) plus splash, authentication, onboarding,
  fullscreen conversation, session report, courses, news, and
  speech-model setup screens. The UI shall support multiple themes,
  font groups, and chat-bubble styles.
- **Admin panel** — a sidebar-navigated dashboard with pages for
  content, users, prompts, leaderboard, audit, admins, and config.

### 4.2 Software interfaces

- **REST API** — JSON over HTTP/HTTPS under `/api`, documented by an
  OpenAPI specification at `/api/docs`.
- **AI provider** — Anthropic or an OpenAI-compatible API, selected by
  configuration.
- **File storage** — local disk or S3, selected by configuration.
- **Database** — PostgreSQL 16 via TypeORM.

### 4.3 Communication interfaces

- All client–server traffic shall use HTTP/HTTPS; production traffic
  shall be TLS-terminated at nginx.
- CORS shall be restricted to a configured set of allowed origins.

---

## 5. Non-functional requirements

### 5.1 Security

**NFR-SEC-1** — Passwords shall be stored only as bcrypt hashes.

**NFR-SEC-2** — Refresh tokens shall be stored only as hashes and shall
be single-use.

**NFR-SEC-3** — Every API route shall require authentication unless
explicitly designated public.

**NFR-SEC-4** — Administrative actions shall be authorized by
role/permission checks enforced on the server.

**NFR-SEC-5** — The system shall apply rate limiting to API requests
(default 120 requests per 60 seconds per client).

**NFR-SEC-6** — Secrets shall be supplied via environment
configuration and shall not be committed to the repository.

**NFR-SEC-7** — Speech-model bundles shall be signature-verified before
installation.

**NFR-SEC-8** — All conversation tokens (the credentials carried after
sign-in) shall be transmitted only over encrypted connections.

### 5.2 Performance

**NFR-PERF-1** — The backend shall apply gzip compression to eligible
responses.

**NFR-PERF-2** — The Flutter app shall serve cached content for
read-only screens without a network round-trip where a fresh cache
exists.

**NFR-PERF-3** — `.ddp` bundle unpacking shall run off the UI thread so
the app remains responsive.

### 5.3 Reliability and availability

**NFR-REL-1** — The backend shall expose a health endpoint for liveness
checks.

**NFR-REL-2** — The system shall degrade gracefully when the AI
provider is unavailable, substituting fallback replies and algorithmic
scoring.

**NFR-REL-3** — Administrative mutations and their audit-log entries
shall be written atomically within a single transaction.

### 5.4 Usability

**NFR-USE-1** — The Flutter app shall present user-safe error messages,
never raw technical errors.

**NFR-USE-2** — Localized content shall be displayed in the learner's
selected language where available.

**NFR-USE-3** — The app shall provide onboarding for first-time
learners.

### 5.5 Portability

**NFR-PORT-1** — The Flutter app shall run on Android (SDK 24+) and
Windows desktop from a single codebase.

**NFR-PORT-2** — The backend shall run on Linux and Windows hosts.

### 5.6 Maintainability

**NFR-MAINT-1** — The backend shall organize domain logic into
independent feature modules.

**NFR-MAINT-2** — Database schema changes shall be applied through
versioned migrations.

**NFR-MAINT-3** — AI prompt content shall be editable as data (prompt
templates) without code changes.

### 5.7 Auditability

**NFR-AUD-1** — All administrative mutations shall be recorded with
actor, action, target, timestamp, and before/after values.

---

## 6. Constraints and open items

The following implementation gaps affect requirement coverage and
should be tracked (see the System Design Specification §11 for
detail):

- The AI session-open path is partly stubbed (a placeholder opening
  message), partially affecting **FR-CONV-1**.
- On-device speech (**FR-SPCH-1**) is gated on a model bundle and uses
  placeholder engines until one is installed.
- The runtime gzip kill-switch is disabled in code, so
  **NFR-PERF-1** cannot currently be toggled off at runtime.
- `POST /admin/auth/signup` is currently unauthenticated for bootstrap;
  **FR-AUTH-7/8** must be gated before public deployment.
- Admin panel tokens are stored in `sessionStorage`, a documented
  trade-off relevant to **NFR-SEC-8**.

---

*End of Requirements Specification.*
