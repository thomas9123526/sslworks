---
title: "vLearn2 (VFLS) — Release Notes"
author: "vLearn2"
date: "2026-05-22"
---

# Release Notes

**Product:** Virtual Foreign Language (VFLS)

---

## Version 1.0.0 — 2026-05-22

The first release of vLearn2 (VFLS), a conversational
language-learning platform for Android and Windows with a supporting
backend and admin console.

### Highlights

- **AI conversation practice** with persona-driven tutors, in text
  **chat** mode and an animated **face** mode.
- **Structured scenarios** graded by difficulty and grouped into
  **courses**.
- **Automated multi-skill scoring** — overall plus pronunciation,
  fluency, vocabulary, grammar, engagement, and listening — with a
  session report after every conversation.
- **Progress and gamification** — XP, levels, streaks, daily skill
  snapshots, and achievements.
- **On-device speech** — speech-to-text and text-to-speech via
  installable signed model bundles.
- **Offline read mode** — cached content remains available without a
  connection.
- **News** — in-app announcements with per-learner read tracking.
- **Admin console** — content management (scenarios, personas,
  categories, courses, news), user management, AI prompt templates,
  runtime configuration, leaderboard, and an audit log.

### Platforms

- Android (minimum SDK 24).
- Windows desktop.

### Architecture

- Backend: NestJS 11 on Node.js 22, PostgreSQL 16, TypeORM.
- Admin panel: Next.js 14.
- App: Flutter 3.41 (Dart 3.11) with Riverpod and go_router.
- Reverse proxy: nginx (`/vfls` → API, `/vAdmin` → admin panel).

### Security

- JWT authentication with rotating, single-use refresh tokens.
- bcrypt password hashing; permission-based admin RBAC.
- Signed `.ddp` speech-model bundles verified against a pinned CA.
- Rate limiting and security headers.

### Known limitations

These are documented in the System Design Specification §11 and are
planned for resolution:

- The opening tutor message in a new conversation is a placeholder;
  full AI wiring of the session-open path is in progress.
- On-device speech uses placeholder engines until a verified `.ddp`
  model bundle is installed.
- The runtime gzip toggle is currently inert (the kill-switch is
  disabled in code).
- The admin bootstrap signup route is open by design for first setup
  and must be gated before public deployment.
- Android release builds are signed with debug keys pending a
  production keystore.
- Automated test coverage is currently limited; expansion is planned
  per the Testing Specification.

### Upgrade notes

This is the initial release; no upgrade steps apply. Database schema is
established by the included migrations; run the seed step to load
reference content.

---

## Release-note process (for future versions)

Each subsequent release should add a section with: version and date,
new features, improvements, bug fixes, security changes, breaking
changes / upgrade steps, and known issues. Entries can be derived from
the project's commit history and per-task implementation reports.

---

*End of Release Notes.*
