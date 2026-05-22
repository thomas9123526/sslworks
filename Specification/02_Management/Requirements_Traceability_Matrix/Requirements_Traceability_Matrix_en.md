---
title: "vLearn2 (VFLS) — Requirements Traceability Matrix"
author: "vLearn2 Engineering"
date: "2026-05-22"
---

# Requirements Traceability Matrix

**Project:** vLearn2 (VFLS) · **Version:** 1.0 · **Date:** 2026-05-22

This matrix links every requirement in the Requirements Specification
(SRS) to the System Design Specification (SDS) section that realizes it
and the Testing Specification test case(s) that verify it. It is the
control artifact for coverage and impact analysis.

**Legend** — SDS references are section numbers of the System Design
Specification; TC references are test-case IDs in the Testing
Specification.

---

## 1. Functional requirements

| Requirement | Description (short) | SDS section | Test case(s) |
|-------------|---------------------|-------------|--------------|
| FR-AUTH-1 | Learner signup | 6.2 | TC-AUTH-1, TC-AUTH-2 |
| FR-AUTH-2 | Learner signin | 6.2 | TC-AUTH-3, TC-AUTH-4 |
| FR-AUTH-3 | Token refresh / rotation | 6.2 | TC-AUTH-5, TC-AUTH-6 |
| FR-AUTH-4 | Signout | 6.2 | TC-AUTH-7 |
| FR-AUTH-5 | Reject invalid tokens | 3.3, 6.2 | TC-AUTH-8, TC-AUTH-9 |
| FR-AUTH-6 | Remember credentials | 8.5 | TC-AUTH-12 |
| FR-AUTH-7 | Admin account creation | 6.2 | TC-AUTH-10 |
| FR-AUTH-8 | First admin = superadmin | 6.2 | TC-AUTH-11 |
| FR-PROF-1 | View profile | 6.1 | TC-PROF-1 |
| FR-PROF-2 | Update profile | 6.1 | TC-PROF-2 |
| FR-PROF-3 | Change password | 6.1, 6.2 | TC-PROF-3, TC-PROF-4 |
| FR-PROF-4 | Onboarding tracking | 8.3 | TC-PROF-5 |
| FR-CONT-1 | Persona catalog | 6.1 | TC-CONT-1 |
| FR-CONT-2 | Scenario catalog + filters | 6.1 | TC-CONT-2, TC-CONT-3 |
| FR-CONT-3 | Scenario detail | 6.1 | TC-CONT-4 |
| FR-CONT-4 | Category list | 6.1 | TC-CONT-1 |
| FR-CONT-5 | Courses | 6.1 | TC-CONT-5 |
| FR-CONT-6 | Localized content | 9.3 | TC-CONT-6 |
| FR-CONV-1 | Start session | 6.1, 6.3 | TC-CONV-1, TC-CONV-2 |
| FR-CONV-2 | Chat / face modes | 8.3 | TC-CONV-1 |
| FR-CONV-3 | Send message + reply | 6.3 | TC-CONV-3, TC-CONV-4 |
| FR-CONV-4 | Persist messages | 5.2 | TC-CONV-5 |
| FR-CONV-5 | Idle suggestion | 6.3 | TC-CONV-6 |
| FR-CONV-6 | End session | 6.1 | TC-CONV-7 |
| FR-CONV-7 | List / delete sessions | 6.1 | TC-CONV-8, TC-CONV-9 |
| FR-CONV-8 | AI-fallback reply | 6.3 | TC-CONV-10 |
| FR-CONV-9 | Daily AI message cap | 6.3, 6.6 | TC-CONV-11 |
| FR-SCORE-1 | Multi-skill score | 5.2, 6.3 | TC-SCORE-1 |
| FR-SCORE-2 | Strengths / improvements | 5.2 | TC-SCORE-2 |
| FR-SCORE-3 | Algorithmic scoring fallback | 6.3 | TC-SCORE-3 |
| FR-SCORE-4 | Session report | 8.3 | TC-SCORE-4 |
| FR-PROG-1 | Aggregate progress | 5.2 | TC-PROG-1 |
| FR-PROG-2 | Daily skill snapshots | 5.2 | TC-PROG-2 |
| FR-PROG-3 | Scenario completions | 5.2 | TC-PROG-3 |
| FR-PROG-4 | XP and levels | 5.2 | TC-PROG-4 |
| FR-PROG-5 | Achievement awards | 5.2 | TC-PROG-5 |
| FR-PROG-6 | View achievements | 6.1 | TC-PROG-6 |
| FR-NEWS-1 | News list | 6.1 | TC-NEWS-1 |
| FR-NEWS-2 | Read status / unread count | 5.2 | TC-NEWS-2 |
| FR-NEWS-3 | Mark read | 6.1 | TC-NEWS-3 |
| FR-CFG-1 | App-visible config flags | 6.6 | TC-ADM-16 |
| FR-OFF-1 | Local cache | 8.5 | TC-OFF-1 |
| FR-OFF-2 | Offline read mode | 8.5, 9.2 | TC-OFF-2 |
| FR-OFF-3 | Secure token storage | 8.5 | TC-OFF-3 |
| FR-SPCH-1 | STT/TTS | 8.6 | TC-SPCH-4 |
| FR-SPCH-2 | Speech-model gate | 8.3, 8.6 | TC-SPCH-1, TC-SPCH-2 |
| FR-SPCH-3 | `.ddp` signature verify | 8.6, 2.5 | TC-SPCH-3, TC-SPCH-4 |
| FR-ADM-1 | Scenario management | 6.1 | TC-ADM-1 |
| FR-ADM-2 | Persona management | 6.1 | TC-ADM-2 |
| FR-ADM-3 | Category management | 6.1 | TC-ADM-3 |
| FR-ADM-4 | Image upload | 6.5 | TC-ADM-4 |
| FR-ADM-5 | News management | 6.1 | TC-ADM-5 |
| FR-ADM-6 | Prompt templates | 6.3 | TC-ADM-6 |
| FR-ADM-7 | View users | 6.1 | TC-ADM-7 |
| FR-ADM-8 | Suspend / reset users | 6.1 | TC-ADM-7 |
| FR-ADM-9 | Summary stats | 6.1 | TC-ADM-8 |
| FR-ADM-10 | Leaderboard | 6.1 | TC-ADM-9 |
| FR-ADM-11 | Sub-admin & permissions | 6.2 | TC-ADM-10 |
| FR-ADM-12 | Non-grantable permissions | 6.2 | TC-ADM-11 |
| FR-ADM-13 | Admin lifecycle | 6.2 | TC-ADM-10 |
| FR-ADM-14 | Audit log | 6.2, 9.2 | TC-ADM-14, TC-ADM-15 |
| FR-ADM-15 | Runtime config | 6.6 | TC-ADM-16 |
| FR-ADM-16 | RBAC enforcement | 6.2, 7.3 | TC-ADM-12, TC-ADM-13 |
| FR-SAFE-1 | Server content guard | 6.4 | TC-SAFE-1 |
| FR-SAFE-2 | Client content guard | 8.1 | TC-SAFE-2 |
| FR-PKG-1 | `.ddp` packaging | 4.4 | TC-PKG-1 |
| FR-PKG-2 | Sign / encrypt / compress | 2.5, 4.4 | TC-PKG-2, TC-PKG-3 |
| FR-PKG-3 | GUI / CLI modes | 4.4 | TC-PKG-1 |

## 2. Non-functional requirements

| Requirement | Description (short) | SDS section | Test case(s) |
|-------------|---------------------|-------------|--------------|
| NFR-SEC-1 | bcrypt password hashing | 6.2, 9.4 | TC-NFR-SEC-1 |
| NFR-SEC-2 | Hashed single-use refresh tokens | 6.2 | TC-NFR-SEC-2 |
| NFR-SEC-3 | Auth required by default | 3.3 | TC-NFR-SEC-3 |
| NFR-SEC-4 | Server-side authorization | 6.2, 7.3 | TC-ADM-12 |
| NFR-SEC-5 | Rate limiting | 3.3 | TC-NFR-SEC-4 |
| NFR-SEC-6 | Secrets via env | 6.6, 9.4 | TC-NFR-SEC-5 |
| NFR-SEC-7 | Signed model bundles | 2.5, 8.6 | TC-SPCH-3 |
| NFR-SEC-8 | Tokens over TLS only | 9.4 | TC-NFR-SEC-3 |
| NFR-PERF-1 | gzip compression | 3.3 | TC-NFR-PERF-1 |
| NFR-PERF-2 | Cached read screens | 8.5, 9.2 | TC-OFF-2 |
| NFR-PERF-3 | Off-thread `.ddp` unpack | 8.6 | TC-NFR-PERF-2 |
| NFR-REL-1 | Health endpoint | 10.2 | TC-NFR-REL-1 |
| NFR-REL-2 | Graceful AI degradation | 6.3 | TC-NFR-REL-2 |
| NFR-REL-3 | Atomic audit writes | 9.2 | TC-NFR-REL-3 |
| NFR-USE-1 | User-safe errors | 9.2 | TC-NFR-USE-1 |
| NFR-USE-2 | Localized display | 9.3 | TC-CONT-6 |
| NFR-USE-3 | Onboarding | 8.3 | TC-PROF-5 |
| NFR-PORT-1 | Android + Windows | 8.7 | TC-NFR-PORT-1 |
| NFR-PORT-2 | Linux + Windows backend | 10 | — (deployment verification) |
| NFR-MAINT-1 | Modular backend | 3.2 | — (design review) |
| NFR-MAINT-2 | Versioned migrations | 5.1 | — (design review) |
| NFR-MAINT-3 | Editable prompt templates | 6.3 | TC-ADM-6 |
| NFR-AUD-1 | Audit completeness | 6.2 | TC-ADM-14 |

## 3. Coverage notes

- Every `FR-*` maps to at least one test case.
- `NFR-PORT-2`, `NFR-MAINT-1`, `NFR-MAINT-2` are verified by deployment
  checks and design review rather than an automated test case; this is
  recorded deliberately.
- The matrix must be updated whenever a requirement, design section, or
  test case is added or changed. Treat an unmatched requirement as a
  release blocker.

---

*End of Requirements Traceability Matrix.*
