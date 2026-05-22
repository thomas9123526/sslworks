---
title: "vLearn2 (VFLS) — User Acceptance Test Plan"
author: "vLearn2 QA"
date: "2026-05-22"
---

# User Acceptance Test Plan

**Project:** vLearn2 (VFLS) · **Version:** 1.0 · **Date:** 2026-05-22

---

## 1. Purpose

This plan defines how vLearn2 is validated against user expectations
before release. Where the Testing Specification verifies the system
*technically*, User Acceptance Testing (UAT) confirms the system is
*fit for use* by real learners and staff.

## 2. Scope

UAT covers end-to-end journeys on real devices for both audiences:

- **Learner UAT** — the Flutter app on Android and Windows.
- **Staff UAT** — the admin panel in a browser.

Out of scope: code-level testing (covered by the Testing
Specification) and the DataManage tool's internal mechanics.

## 3. Participants & environment

| Role | Responsibility |
|------|----------------|
| UAT coordinator | Schedules sessions, records outcomes, decides sign-off |
| Learner testers (2+) | Exercise the app as real learners |
| Staff testers (1+) | Exercise the admin panel |
| Engineering support | Triages issues found during UAT |

**Environment:** a staging deployment representative of production
(nginx, real backend, seeded content, a stubbed or budgeted AI
provider). At least one Android device (older + current SDK) and one
Windows PC.

## 4. Entry criteria

- All P1 cases in the Testing Specification pass.
- No open S1/S2 defects.
- Staging is deployed and reachable; seed content is loaded.
- Test accounts exist (learner, sub-admin, superadmin).

## 5. Exit / sign-off criteria

- All UAT scenarios below have an outcome of **Pass** (or **Pass with
  noted minor issues** accepted by the coordinator).
- No open S1/S2 defect remains.
- The UAT coordinator records formal sign-off.

## 6. Learner acceptance scenarios

| ID | Scenario | Expected outcome |
|----|----------|------------------|
| UAT-L1 | Install, sign up, complete onboarding | Account created; onboarding shown once |
| UAT-L2 | Sign in; "remember me" then reopen the app | Returns signed in without re-entering credentials |
| UAT-L3 | Start a free conversation in chat mode, exchange several turns | Tutor replies are coherent; messages persist |
| UAT-L4 | Complete a scenario role-play and end the session | Session report shows scores, strengths, XP |
| UAT-L5 | Use face mode | Animated tutor responds; conversation works |
| UAT-L6 | Speak using the microphone (model installed) | Speech recognised; spoken reply plays |
| UAT-L7 | Start a speaking conversation with no model installed | App guides to setup; text-only continues cleanly |
| UAT-L8 | Browse scenarios and a course; open a scenario brief | Catalog and brief display correctly |
| UAT-L9 | View Progress after several sessions | XP, level, streak, skills, achievements reflect activity |
| UAT-L10 | Read and dismiss News | Unread count updates; posts mark as read |
| UAT-L11 | Edit profile; change theme and language | Changes apply and persist |
| UAT-L12 | Change password, then sign in again | Old password rejected; new password works |
| UAT-L13 | Use the app offline (airplane mode) | Cached content shown; clear offline messaging, no raw errors |
| UAT-L14 | Run on both Android and Windows | Equivalent behaviour on both platforms |

## 7. Staff acceptance scenarios

| ID | Scenario | Expected outcome |
|----|----------|------------------|
| UAT-S1 | Sign in to the admin panel | Dashboard with summary stats |
| UAT-S2 | Create, edit, publish, then archive a scenario | Status transitions correctly; visible to learners when published |
| UAT-S3 | Upload a scenario image | Valid image accepted; oversized/invalid rejected |
| UAT-S4 | Create and edit a persona | Persona appears for learners |
| UAT-S5 | Attempt to delete a category in use | Deletion refused with a clear message |
| UAT-S6 | Create and publish a news post | Post visible to learners |
| UAT-S7 | Edit an AI prompt template | Change takes effect in new conversations |
| UAT-S8 | Find a learner; suspend then restore | Suspended learner is blocked; restore re-enables |
| UAT-S9 | (Superadmin) Create a sub-admin and grant permissions | Sub-admin sees only permitted actions |
| UAT-S10 | Sub-admin attempts an action without permission | Action unavailable / refused |
| UAT-S11 | Review the audit log after the above | Every change is recorded with actor and details |
| UAT-S12 | Change a runtime config flag | Flag change reflected in the learner app |

## 8. Defect handling during UAT

- Issues are logged with severity (S1–S4), the scenario ID, steps, and
  environment.
- S1/S2 issues block sign-off and are fixed and retested.
- S3/S4 issues may be accepted by the coordinator with a follow-up
  ticket.

## 9. Schedule (template)

| Phase | Duration | Activity |
|-------|----------|----------|
| Preparation | — | Provision staging, accounts, devices |
| Learner UAT | — | Execute UAT-L1…L14 |
| Staff UAT | — | Execute UAT-S1…S12 |
| Defect fix & retest | — | Resolve S1/S2, retest |
| Sign-off | — | Coordinator records decision |

Durations are set per release by the UAT coordinator.

## 10. Sign-off record

| Field | Value |
|-------|-------|
| Release / version | _____________ |
| UAT period | _____________ |
| Scenarios passed | ____ / 26 |
| Open S1/S2 defects | _____________ |
| Decision (Accept / Reject) | _____________ |
| Coordinator & date | _____________ |

---

*End of User Acceptance Test Plan.*
