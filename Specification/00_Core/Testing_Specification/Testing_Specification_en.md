---
title: "vLearn2 (VFLS) — Testing Specification"
subtitle: "Virtual Foreign Language — conversational language-learning platform"
author: "vLearn2 Engineering"
date: "2026-05-22"
---

# Testing Specification

**Project:** vLearn2 — marketed as *Virtual Foreign Language* (VFLS)
**Document type:** Testing Specification / Test Plan
**Version:** 1.0 (Draft)
**Date:** 2026-05-22
**Source:** Derived from inspection of `C:\project\vLearn2` and the
companion System Design and Requirements Specifications.

---

## 1. Introduction

### 1.1 Purpose

This document defines the test strategy, test environment, current
coverage baseline, and the planned test cases for the vLearn2 system.
It is the reference for verifying that the system meets the
requirements stated in the Requirements Specification (SRS).

### 1.2 Scope

Testing covers all four subsystems — the NestJS backend, the Next.js
admin panel, the Flutter app, and the DataManage tool — across unit,
integration, end-to-end (E2E), and manual test levels.

### 1.3 References

- vLearn2 System Design Specification (SDS).
- vLearn2 Requirements Specification (SRS) — requirement IDs `FR-*`,
  `NFR-*` are traced here.
- Backend OpenAPI specification (`/api/docs`).

### 1.4 Test case notation

Test cases are identified `TC-<area>-<n>`. Each references the
requirement(s) it verifies. Priority is **P1** (critical path), **P2**
(important), or **P3** (secondary).

---

## 2. Test strategy

### 2.1 Test levels

| Level | Goal | Primary tooling |
|-------|------|-----------------|
| Unit | Verify individual functions/classes in isolation | Jest (backend, admin), `flutter_test` (app), smoke-test binaries (DataManage) |
| Integration | Verify modules against real collaborators (DB, API) | Jest + `supertest` + ephemeral PostgreSQL |
| End-to-end | Verify whole user journeys across subsystems | API-driven E2E; UI automation (planned) |
| Manual / exploratory | Verify UX, devices, speech, install flows | Test-charter-driven manual passes |

### 2.2 Approach by subsystem

- **Backend** — the priority target for automated testing, since it
  owns all business logic. Strategy: unit-test services and guards;
  integration-test controllers against an ephemeral PostgreSQL via
  `supertest`; cover authentication, RBAC, and the conversation/scoring
  flow most heavily.
- **Admin panel** — unit-test `lib/` utilities; add component tests for
  forms and tables; add an E2E smoke pass over sign-in and one CRUD
  flow.
- **Flutter app** — unit-test `core/` logic (guard, datapack, model
  registry, token store); add widget tests for key screens; add
  provider tests for the auth state machine and router redirects.
- **DataManage** — extend the existing smoke-test binaries into a
  pack → sign → unpack round-trip verified by the Flutter `datapack`
  tests.

### 2.3 Entry and exit criteria

**Entry criteria** (a build is ready for a test cycle):

- The subsystem compiles/builds cleanly.
- Linting and type-checking pass.
- The test environment (§3) is provisioned.

**Exit criteria** (a test cycle is complete):

- All P1 test cases pass.
- No open P1 defects.
- P2/P3 failures are triaged and either fixed or accepted with a
  recorded waiver.
- Coverage meets the targets in §7.

### 2.4 Regression strategy

Every defect fix shall be accompanied by a test that fails before the
fix and passes after it. The full automated suite shall run in CI on
every change (see §3.3).

---

## 3. Test environment

### 3.1 Backend / integration environment

- Node.js 22+.
- An ephemeral PostgreSQL 16 instance (the `docker-compose.yml`
  service, or the CI service container).
- A test `.env` with throwaway secrets and a dedicated test database;
  migrations applied before the run; seed data loaded as needed.
- The AI provider stubbed/mocked so tests are deterministic and offline.

### 3.2 Flutter environment

- Flutter 3.41.x toolchain.
- `flutter test` for unit/widget tests (headless).
- For `.ddp` datapack tests: the DataManage binaries and CA files must
  be present, otherwise those tests self-skip.
- Manual device testing on at least one Android device (SDK 24 and a
  current SDK) and one Windows desktop.

### 3.3 Continuous integration

GitHub Actions workflows run per subsystem (path-filtered):

- `backend_ci.yml` — provisions PostgreSQL, runs lint, build, unit
  tests, and (non-blocking) E2E.
- `admin_ci.yml` — runs lint, typecheck, build.
- `flutter_ci.yml` — runs format check, analyze, test, and debug
  builds.

> **Action item:** CI triggers on `master`/`dev`; the main branch is
> `main`. Align the triggers so changes are actually tested. The
> backend E2E step is currently non-blocking (`|| true`) — once stable,
> make it blocking.

### 3.4 Test data

- Seed data: baseline achievements, app-config, courses, personas, and
  scenarios via the seed runner.
- Fixture accounts: one learner, one sub-admin (limited permissions),
  one superadmin.
- Fixture conversation: one scenario session with a known message
  sequence for scoring tests.

---

## 4. Current coverage baseline

The existing automated tests at the time of writing:

| Subsystem | Test files | Covered today |
|-----------|-----------|---------------|
| Backend | `ai/prompt-builder.service.spec.ts`, `guard/content-guard.service.spec.ts`, `test/app.e2e-spec.ts` | Prompt-builder logic, content-guard logic, `GET /health` smoke |
| Admin panel | `lib/__tests__/env.test.ts`, `flag-catalog.test.ts`, `utils.test.ts` | Pure `lib/` utilities |
| Flutter app | `test/datapack/installer_test.dart`, `unpack_test.dart`, `test/guard/content_guard_test.dart`, `test/storage/model_registry_test.dart` | Datapack install/unpack, content guard, model registry |
| DataManage | `manifest_smoke_test.cpp`, `packer_smoke_test.cpp`, `session_smoke_test.cpp` | Manifest, packer, session smoke checks |

**Assessment:** coverage is thin and skewed toward pure-logic units.
The bulk of business logic — backend controllers/services,
authentication, RBAC, conversations and scoring, admin operations, and
all Flutter screens — is currently untested. Sections 5–6 define the
test cases needed to close this gap; section 7 sets coverage targets.

---

## 5. Functional test cases

The following test cases trace to requirements in the SRS. They define
the target suite; cases not yet automated are flagged as **(to
implement)**.

### 5.1 Authentication

| ID | Requirement | Description | Priority |
|----|-------------|-------------|----------|
| TC-AUTH-1 | FR-AUTH-1 | Learner signup with valid fields creates an account and profile | P1 |
| TC-AUTH-2 | FR-AUTH-1 | Signup rejects a password shorter than 6 characters | P1 |
| TC-AUTH-3 | FR-AUTH-2 | Signin with correct credentials returns access + refresh tokens | P1 |
| TC-AUTH-4 | FR-AUTH-2 | Signin with wrong credentials is rejected with the expected error key | P1 |
| TC-AUTH-5 | FR-AUTH-3 | Refresh with a valid token returns a new access token and rotates the refresh token | P1 |
| TC-AUTH-6 | FR-AUTH-3 | A refresh token cannot be reused after rotation | P1 |
| TC-AUTH-7 | FR-AUTH-4 | Signout invalidates the refresh token | P2 |
| TC-AUTH-8 | FR-AUTH-5 | A request with an expired access token is rejected | P1 |
| TC-AUTH-9 | FR-AUTH-5 | A protected route without a token is rejected | P1 |
| TC-AUTH-10 | FR-AUTH-7 | Admin signup rejects a password not meeting the 12-char composition rule | P1 |
| TC-AUTH-11 | FR-AUTH-8 | The first admin account is created as `superadmin`; the next as `admin` | P1 |
| TC-AUTH-12 | FR-AUTH-6 | The app remembers credentials only when the learner opts in | P3 |

### 5.2 Learner profile

| ID | Requirement | Description | Priority |
|----|-------------|-------------|----------|
| TC-PROF-1 | FR-PROF-1 | Profile read returns level, XP, streak, preferences | P2 |
| TC-PROF-2 | FR-PROF-2 | Profile update persists changed fields | P2 |
| TC-PROF-3 | FR-PROF-3 | Password change succeeds with the correct current password | P1 |
| TC-PROF-4 | FR-PROF-3 | Password change is rejected with a wrong current password | P1 |
| TC-PROF-5 | FR-PROF-4 | Onboarding flag is set once and onboarding is not shown again | P3 |

### 5.3 Content browsing

| ID | Requirement | Description | Priority |
|----|-------------|-------------|----------|
| TC-CONT-1 | FR-CONT-1 | Persona list returns only active personas | P2 |
| TC-CONT-2 | FR-CONT-2 | Scenario list returns only published scenarios | P1 |
| TC-CONT-3 | FR-CONT-2 | Scenario list filters by category, difficulty, and query | P2 |
| TC-CONT-4 | FR-CONT-3 | Scenario detail resolves by both id and slug | P2 |
| TC-CONT-5 | FR-CONT-5 | Course detail returns scenarios in defined order | P2 |
| TC-CONT-6 | FR-CONT-6 | Localized text renders in the learner's selected language | P3 |

### 5.4 Conversation and scoring

| ID | Requirement | Description | Priority |
|----|-------------|-------------|----------|
| TC-CONV-1 | FR-CONV-1 | Starting a session with a persona only creates a free-talk session | P1 |
| TC-CONV-2 | FR-CONV-1 | Starting a session with a persona + scenario links the scenario | P1 |
| TC-CONV-3 | FR-CONV-3 | Sending a learner message returns a tutor reply and persists both | P1 |
| TC-CONV-4 | FR-CONV-3 | A message over 5000 characters is rejected | P2 |
| TC-CONV-5 | FR-CONV-4 | Messages are persisted with correct role and sequence | P1 |
| TC-CONV-6 | FR-CONV-5 | A suggestion request returns a usable prompt | P3 |
| TC-CONV-7 | FR-CONV-6 | Ending a session records duration, turn count, word count, XP | P1 |
| TC-CONV-8 | FR-CONV-7 | Session list and session-with-messages read back correctly | P2 |
| TC-CONV-9 | FR-CONV-7 | Deleting a session removes it and its messages | P2 |
| TC-CONV-10 | FR-CONV-8 | With the AI provider stubbed to fail, a fallback reply is returned (no error surfaced) | P1 |
| TC-CONV-11 | FR-CONV-9 | The daily AI-message limit is enforced | P2 |
| TC-SCORE-1 | FR-SCORE-1 | A completed session produces a multi-skill score record | P1 |
| TC-SCORE-2 | FR-SCORE-2 | The score record includes strengths and improvement areas | P2 |
| TC-SCORE-3 | FR-SCORE-3 | With AI grammar scoring unavailable, algorithmic scoring is used | P2 |
| TC-SCORE-4 | FR-SCORE-4 | The session report screen renders the score after a session ends | P2 |

### 5.5 Progress and gamification

| ID | Requirement | Description | Priority |
|----|-------------|-------------|----------|
| TC-PROG-1 | FR-PROG-1 | Aggregate progress reflects completed sessions | P2 |
| TC-PROG-2 | FR-PROG-2 | A second snapshot on the same day running-averages the values | P2 |
| TC-PROG-3 | FR-PROG-3 | Scenario completion records best score and completion count | P2 |
| TC-PROG-4 | FR-PROG-4 | XP award raises the learner level at the defined threshold | P2 |
| TC-PROG-5 | FR-PROG-5 | An achievement is awarded when its condition is met | P2 |
| TC-PROG-6 | FR-PROG-6 | Earned achievements read back for the learner | P3 |

### 5.6 News

| ID | Requirement | Description | Priority |
|----|-------------|-------------|----------|
| TC-NEWS-1 | FR-NEWS-1 | News list is paginated and surfaces pinned posts first | P3 |
| TC-NEWS-2 | FR-NEWS-2 | Unread count reflects per-learner read status | P3 |
| TC-NEWS-3 | FR-NEWS-3 | Mark-read and mark-all-read update read status | P3 |

### 5.7 Offline behaviour (Flutter)

| ID | Requirement | Description | Priority |
|----|-------------|-------------|----------|
| TC-OFF-1 | FR-OFF-1 | Read content is cached to the local Drift database | P2 |
| TC-OFF-2 | FR-OFF-2 | Offline, cached content is served and a user-safe message shown | P2 |
| TC-OFF-3 | FR-OFF-3 | Tokens are written to and read from secure storage (incl. the Windows cache path) | P1 |

### 5.8 On-device speech

| ID | Requirement | Description | Priority |
|----|-------------|-------------|----------|
| TC-SPCH-1 | FR-SPCH-2 | Starting a speech conversation with no model installed diverts to the setup screen | P2 |
| TC-SPCH-2 | FR-SPCH-2 | After acknowledging text-only mode, the conversation proceeds without diversion | P2 |
| TC-SPCH-3 | FR-SPCH-3 | A `.ddp` bundle with an invalid signature is rejected | P1 |
| TC-SPCH-4 | FR-SPCH-3 | A correctly signed `.ddp` bundle installs and registers the model | P1 |

### 5.9 Administration — content

| ID | Requirement | Description | Priority |
|----|-------------|-------------|----------|
| TC-ADM-1 | FR-ADM-1 | An authorized admin can create, edit, publish, archive, delete a scenario | P1 |
| TC-ADM-2 | FR-ADM-2 | Persona create / edit / soft-delete / restore work | P2 |
| TC-ADM-3 | FR-ADM-3 | Deleting a category in use is refused (409) | P2 |
| TC-ADM-4 | FR-ADM-4 | Image upload rejects a non-image type and an over-5 MB file | P2 |
| TC-ADM-5 | FR-ADM-5 | News create / publish / archive / delete work | P2 |
| TC-ADM-6 | FR-ADM-6 | Editing a prompt template persists and is used by the orchestrator | P2 |

### 5.10 Administration — users, governance, RBAC

| ID | Requirement | Description | Priority |
|----|-------------|-------------|----------|
| TC-ADM-7 | FR-ADM-8 | Suspending a learner blocks their access; restore re-enables it | P1 |
| TC-ADM-8 | FR-ADM-9 | Stats endpoint returns the four summary metrics | P3 |
| TC-ADM-9 | FR-ADM-10 | Leaderboard ranks correctly by each selectable metric | P3 |
| TC-ADM-10 | FR-ADM-11 | A superadmin can create a sub-admin and grant permissions | P1 |
| TC-ADM-11 | FR-ADM-12 | A privacy-sensitive permission cannot be granted to a sub-admin | P1 |
| TC-ADM-12 | FR-ADM-16 | A sub-admin without a permission is refused the corresponding endpoint (403) | P1 |
| TC-ADM-13 | FR-ADM-16 | A `superadmin` bypasses individual permission checks | P2 |
| TC-ADM-14 | FR-ADM-14 | Every admin mutation writes an audit-log entry with before/after values | P1 |
| TC-ADM-15 | FR-ADM-14 | A failed admin mutation rolls back without leaving an audit entry | P1 |
| TC-ADM-16 | FR-ADM-15 | Config flag edit and reset-to-default work; reset-all is superadmin-only | P2 |

### 5.11 Content safety

| ID | Requirement | Description | Priority |
|----|-------------|-------------|----------|
| TC-SAFE-1 | FR-SAFE-1 | Disallowed content is detected and a violation is recorded with severity and terms | P1 |
| TC-SAFE-2 | FR-SAFE-2 | The Flutter client-side guard flags disallowed content before sending | P2 |

### 5.12 DataManage

| ID | Requirement | Description | Priority |
|----|-------------|-------------|----------|
| TC-PKG-1 | FR-PKG-1/2 | Packing a directory produces a signed `.ddp` bundle | P1 |
| TC-PKG-2 | FR-PKG-2 | An encrypted + compressed bundle round-trips: pack → unpack equals the source | P1 |
| TC-PKG-3 | FR-PKG-2 | A tampered bundle fails signature verification on unpack | P1 |

---

## 6. Non-functional test cases

| ID | Requirement | Description | Priority |
|----|-------------|-------------|----------|
| TC-NFR-SEC-1 | NFR-SEC-1 | Stored passwords are bcrypt hashes, never plaintext | P1 |
| TC-NFR-SEC-2 | NFR-SEC-2 | Refresh tokens are stored hashed and rejected after single use | P1 |
| TC-NFR-SEC-3 | NFR-SEC-3 | A representative protected route from every module rejects unauthenticated requests | P1 |
| TC-NFR-SEC-4 | NFR-SEC-5 | Exceeding the rate limit returns 429 | P2 |
| TC-NFR-SEC-5 | NFR-SEC-6 | No real secrets are present in committed files | P1 |
| TC-NFR-PERF-1 | NFR-PERF-1 | Eligible responses are gzip-compressed | P3 |
| TC-NFR-PERF-2 | NFR-PERF-3 | `.ddp` unpacking does not block the UI thread | P2 |
| TC-NFR-REL-1 | NFR-REL-1 | `GET /health` returns `status: ok` | P1 |
| TC-NFR-REL-2 | NFR-REL-2 | With the AI provider down, conversations and scoring still complete via fallbacks | P1 |
| TC-NFR-REL-3 | NFR-REL-3 | An admin mutation and its audit entry commit or roll back together | P1 |
| TC-NFR-USE-1 | NFR-USE-1 | The Flutter app surfaces a polite message, never a raw stack/error | P2 |
| TC-NFR-PORT-1 | NFR-PORT-1 | The app builds and runs on Android (SDK 24) and Windows | P1 |

---

## 7. Coverage targets and gap closure

### 7.1 Targets

| Subsystem | Current | Target |
|-----------|---------|--------|
| Backend — services & guards (unit) | 2 files | ≥ 80% line coverage of services and guards |
| Backend — controllers (integration) | health smoke only | every endpoint has at least one happy-path + one auth/validation test |
| Admin panel | `lib/` utils only | `lib/` ≥ 80%; component tests for each form/table; one E2E smoke |
| Flutter app | 4 core-logic files | `core/` logic ≥ 70%; widget tests for splash, auth, conversation, report; provider tests for auth + router |
| DataManage | 3 smoke binaries | full pack/sign/encrypt/compress round-trip + tamper-rejection |

### 7.2 Prioritized gap-closure plan

1. **P1 — backend auth & RBAC integration tests.** TC-AUTH-*,
   TC-ADM-10/11/12, TC-NFR-SEC-1/2/3. Highest risk, currently untested.
2. **P1 — conversation & scoring flow.** TC-CONV-*, TC-SCORE-*,
   including the AI-fallback path (TC-CONV-10, TC-NFR-REL-2).
3. **P1 — admin mutation + audit atomicity.** TC-ADM-14/15,
   TC-NFR-REL-3.
4. **P2 — Flutter core + key widget tests.** Token store (incl. the
   Windows cache path), router redirects, auth state machine,
   conversation screen.
5. **P2 — admin panel component + E2E smoke.**
6. **P3 — news, leaderboard, stats, localization.**

### 7.3 Traceability

Every `FR-*` and `NFR-*` in the SRS shall map to at least one `TC-*`
in this document. Sections 5–6 provide that mapping in the
*Requirement* column. New requirements shall not be accepted without a
corresponding test case, and the traceability shall be reviewed each
release.

---

## 8. Defect management

- Defects are logged with severity (S1 blocker … S4 cosmetic),
  reproduction steps, environment, and the related `TC-*`/`FR-*` ID.
- **S1/S2** defects block the release; **S3/S4** may ship with a
  recorded waiver and a follow-up ticket.
- Every fix adds a regression test (see §2.4).

---

## 9. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| AI provider non-determinism | Flaky conversation/scoring tests | Stub the provider; assert on structure, not exact text |
| CI not triggered on `main` | Changes merge untested | Align workflow trigger branches (§3.3) |
| Speech/datapack tests need native binaries | Tests self-skip, creating false confidence | Provide DataManage binaries + CA in CI; fail if absent in release pipelines |
| Thin starting coverage | Regressions slip through | Execute the §7.2 plan before further feature work |
| Open admin signup | Unauthorized superadmin creation | Gate `admin/auth/signup` and test that it is gated |

---

*End of Testing Specification.*
