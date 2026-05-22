---
title: "vLearn2 (VFLS) — Detailed Test Cases"
author: "vLearn2 QA"
date: "2026-05-22"
---

# Detailed Test Cases

**Project:** vLearn2 (VFLS) · **Version:** 1.0 · **Date:** 2026-05-22

This document expands the test-case catalog of the Testing
Specification into executable cases — each with preconditions, steps,
and expected results. Cases are grouped by area; IDs match the Testing
Specification and the Requirements Traceability Matrix.

**Template fields:** ID · traces (FR/NFR) · priority · preconditions ·
steps · expected result.

---

## 1. Authentication

### TC-AUTH-1 — Learner signup (happy path)
- **Traces:** FR-AUTH-1 · **Priority:** P1
- **Preconditions:** No account exists for the chosen `cidUsername`.
- **Steps:** 1) `POST /api/auth/signup` with valid `cid`,
  `cidUsername`, `password` (≥6), `displayName`, `uiLanguage`.
- **Expected:** `201`; response contains access + refresh tokens; a
  `users` row and a `vl_user_info` row are created.

### TC-AUTH-2 — Signup rejects short password
- **Traces:** FR-AUTH-1 · **Priority:** P1
- **Steps:** `POST /api/auth/signup` with a 5-character password.
- **Expected:** `400`; validation error; no account created.

### TC-AUTH-3 — Signin (happy path)
- **Traces:** FR-AUTH-2 · **Priority:** P1
- **Preconditions:** A learner account exists.
- **Steps:** `POST /api/auth/signin` with correct credentials.
- **Expected:** `200`; access + refresh tokens returned.

### TC-AUTH-4 — Signin rejects wrong credentials
- **Traces:** FR-AUTH-2 · **Priority:** P1
- **Steps:** `POST /api/auth/signin` with a wrong password.
- **Expected:** `401`; error body carries `i18nKey`
  `auth.invalid_credentials`; no tokens.

### TC-AUTH-5 — Refresh rotates the token
- **Traces:** FR-AUTH-3 · **Priority:** P1
- **Preconditions:** A valid refresh token is held.
- **Steps:** `POST /api/auth/refresh` with the refresh token.
- **Expected:** `200`; a new access token; a new refresh token
  (different from the input).

### TC-AUTH-6 — Used refresh token is rejected
- **Traces:** FR-AUTH-3 · **Priority:** P1
- **Steps:** 1) Refresh once (TC-AUTH-5). 2) Refresh again with the
  *original* token.
- **Expected:** `401`; the consumed token is invalid.

### TC-AUTH-8 — Expired access token rejected
- **Traces:** FR-AUTH-5 · **Priority:** P1
- **Steps:** Call a protected route with an expired access token.
- **Expected:** `401`.

### TC-AUTH-9 — Missing token rejected
- **Traces:** FR-AUTH-5 · **Priority:** P1
- **Steps:** Call a protected route with no `Authorization` header.
- **Expected:** `401`.

### TC-AUTH-10 — Admin password policy
- **Traces:** FR-AUTH-7 · **Priority:** P1
- **Steps:** `POST /api/admin/auth/signup` with an 8-character
  lowercase-only password.
- **Expected:** `400`; rejected for not meeting the 12-char mixed
  policy.

### TC-AUTH-11 — First admin is superadmin
- **Traces:** FR-AUTH-8 · **Priority:** P1
- **Preconditions:** No admin accounts exist.
- **Steps:** Create admin A, then admin B.
- **Expected:** A has role `superadmin`; B has role `admin`.

## 2. Profile

### TC-PROF-3 — Change password with correct current password
- **Traces:** FR-PROF-3 · **Priority:** P1
- **Steps:** `PATCH /api/users/profile` with the correct current
  password and a new valid password.
- **Expected:** `200`; subsequent signin works with the new password
  only.

### TC-PROF-4 — Change password rejects wrong current password
- **Traces:** FR-PROF-3 · **Priority:** P1
- **Steps:** `PATCH /api/users/profile` with an incorrect current
  password.
- **Expected:** `400`/`401`; password unchanged.

## 3. Content browsing

### TC-CONT-2 — Scenario list returns only published
- **Traces:** FR-CONT-2 · **Priority:** P1
- **Preconditions:** Scenarios exist in `draft`, `published`,
  `archived`.
- **Steps:** `GET /api/scenarios`.
- **Expected:** Only `published` scenarios are returned.

### TC-CONT-3 — Scenario filters
- **Traces:** FR-CONT-2 · **Priority:** P2
- **Steps:** `GET /api/scenarios?category=...&difficulty=...&q=...`.
- **Expected:** Results match all supplied filters.

## 4. Conversation & scoring

### TC-CONV-1 — Start free-talk session
- **Traces:** FR-CONV-1 · **Priority:** P1
- **Steps:** `POST /api/conversations/sessions` with `personaId` and
  `mode`, no `scenarioId`.
- **Expected:** `201`; session created with `scenario_id` null.

### TC-CONV-3 — Send message returns tutor reply
- **Traces:** FR-CONV-3 · **Priority:** P1
- **Preconditions:** An active session exists; AI provider stubbed to
  succeed.
- **Steps:** `POST /api/conversations/sessions/:id/messages` with
  content.
- **Expected:** `200/201`; a tutor reply returned; both user and
  assistant messages persisted with correct `role` and `sequence`.

### TC-CONV-4 — Over-length message rejected
- **Traces:** FR-CONV-3 · **Priority:** P2
- **Steps:** Send a message of 5001 characters.
- **Expected:** `400` validation error.

### TC-CONV-7 — End session records metrics
- **Traces:** FR-CONV-6 · **Priority:** P1
- **Steps:** `POST /api/conversations/sessions/:id/end`.
- **Expected:** Session `status=completed`; `duration_seconds`,
  `turn_count`, `word_count`, `xp_earned` populated.

### TC-CONV-10 — AI fallback on provider failure
- **Traces:** FR-CONV-8, NFR-REL-2 · **Priority:** P1
- **Preconditions:** AI provider stubbed to throw.
- **Steps:** Send a message in an active session.
- **Expected:** `200`; a canned fallback reply returned; no error
  surfaced to the client.

### TC-SCORE-1 — Multi-skill score produced
- **Traces:** FR-SCORE-1 · **Priority:** P1
- **Steps:** Complete a session and read its score.
- **Expected:** A `vl_session_scores` row with `overall_score` and
  applicable per-skill scores.

## 5. Admin & RBAC

### TC-ADM-3 — Delete category in use is refused
- **Traces:** FR-ADM-3 · **Priority:** P2
- **Preconditions:** A category referenced by ≥1 scenario.
- **Steps:** `DELETE /api/admin/categories/:id`.
- **Expected:** `409`; category not deleted.

### TC-ADM-11 — Sensitive permission not grantable
- **Traces:** FR-ADM-12 · **Priority:** P1
- **Steps:** As superadmin, attempt to grant a non-grantable
  permission to a sub-admin.
- **Expected:** Rejected; permission not granted.

### TC-ADM-12 — Sub-admin without permission is refused
- **Traces:** FR-ADM-16 · **Priority:** P1
- **Preconditions:** A sub-admin lacking `scenarios.edit`.
- **Steps:** `POST /api/admin/scenarios` as that sub-admin.
- **Expected:** `403`.

### TC-ADM-14 — Admin mutation writes an audit entry
- **Traces:** FR-ADM-14 · **Priority:** P1
- **Steps:** Perform any admin mutation (e.g. publish a scenario).
- **Expected:** A `vl_admin_audit_log` row with actor, action, target,
  and before/after values.

### TC-ADM-15 — Failed mutation rolls back without audit entry
- **Traces:** FR-ADM-14, NFR-REL-3 · **Priority:** P1
- **Steps:** Trigger an admin mutation that fails mid-transaction.
- **Expected:** No data change and no audit entry — both rolled back.

## 6. Speech & DataManage

### TC-SPCH-3 — Invalid `.ddp` signature rejected
- **Traces:** FR-SPCH-3, NFR-SEC-7 · **Priority:** P1
- **Steps:** Attempt to install a `.ddp` bundle with a tampered
  signature.
- **Expected:** Installation rejected; model not registered.

### TC-PKG-2 — `.ddp` round-trip
- **Traces:** FR-PKG-2 · **Priority:** P1
- **Steps:** Pack a directory, then unpack it.
- **Expected:** Unpacked content is byte-identical to the source.

## 7. Non-functional

### TC-NFR-SEC-3 — Protected routes reject anonymous access
- **Traces:** NFR-SEC-3 · **Priority:** P1
- **Steps:** Call one representative protected route per module without
  a token.
- **Expected:** Every call returns `401`.

### TC-NFR-REL-1 — Health endpoint
- **Traces:** NFR-REL-1 · **Priority:** P1
- **Steps:** `GET /health`.
- **Expected:** `200`; body `{ "status": "ok" }`.

### TC-NFR-SEC-4 — Rate limit
- **Traces:** NFR-SEC-5 · **Priority:** P2
- **Steps:** Exceed the configured request limit within the window.
- **Expected:** `429` once the limit is crossed.

---

## 8. Notes

- Cases not listed individually here (the full catalog is in the
  Testing Specification §5–6) follow the same template; expand them as
  they are automated.
- AI-dependent cases must stub the provider for determinism.
- Speech/`.ddp` cases require the DataManage binaries and CA files;
  otherwise they self-skip.

---

*End of Detailed Test Cases.*
