---
title: "vLearn2 (VFLS) — Project & Risk Management Plan"
author: "vLearn2 Project Management"
date: "2026-05-22"
---

# Project & Risk Management Plan

**Project:** vLearn2 (VFLS) · **Version:** 1.0 · **Date:** 2026-05-22

---

## 1. Purpose

This plan describes how the vLearn2 project is organized, how work
progresses, and how risks are identified, assessed, and controlled. It
is a living document and should be revised each release.

## 2. Scope

vLearn2 — a cross-platform conversational language-learning product
comprising a Flutter app, a NestJS backend, a Next.js admin panel, the
DataManage packaging tool, and a PostgreSQL database.

## 3. Organization & roles

| Role | Responsibility |
|------|----------------|
| Product owner | Priorities, scope, success metrics |
| Backend engineer | NestJS API, data model, AI integration |
| Frontend engineer (app) | Flutter app, UX, on-device speech |
| Frontend engineer (admin) | Next.js admin panel |
| QA | Test design, execution, coverage tracking |
| Operations | Deployment, monitoring, incident response |

At small team size one person may hold several roles; the
responsibilities still apply.

## 4. Lifecycle & cadence

vLearn2 is developed iteratively. Each change follows: plan → implement
→ review → test (CI) → merge → deploy. The repository carries planning
documents and per-task implementation reports (`todoList/`,
`todoList_report/`) that constitute the working history.

**Branching / CI:** path-filtered GitHub Actions build and test each
subsystem. *Action item:* the workflows trigger on `master`/`dev` while
the main branch is `main` — align them so changes are actually tested.

## 5. Milestones

| Milestone | Definition of done |
|-----------|--------------------|
| M1 — Core platform | Auth, data model, conversation + scoring functioning end to end |
| M2 — Content & gamification | Scenarios, courses, progress, achievements, news |
| M3 — Admin & operations | Admin panel, RBAC, audit, runtime config |
| M4 — Speech & offline | On-device STT/TTS via `.ddp`, offline read cache |
| M5 — Hardening for launch | Security gaps closed (see §7), test coverage targets met, production deployment |

M1–M4 are substantially implemented; M5 is the outstanding work.

## 6. Risk management process

1. **Identify** — risks are raised continuously and recorded in the
   register (§7).
2. **Assess** — each risk is rated Likelihood × Impact (Low / Medium /
   High).
3. **Plan** — a response is chosen: mitigate, accept, transfer, or
   avoid.
4. **Track** — the register is reviewed each release; status and
   residual risk updated.
5. **Escalate** — High exposure risks are escalated to the product
   owner.

## 7. Risk register

| ID | Risk | Likelihood | Impact | Response |
|----|------|-----------|--------|----------|
| R-1 | Open admin signup exploited before launch | Medium | High | **Mitigate** — gate `admin/auth/signup` before public deployment |
| R-2 | Mixed HTTP/HTTPS exposes tokens | Medium | High | **Mitigate** — enforce HTTPS for the whole API |
| R-3 | Admin tokens in `sessionStorage` stolen via XSS | Low | High | **Mitigate/Accept** — httpOnly cookies or strict CSP |
| R-4 | AI provider outage or cost spike | Medium | Medium | **Mitigate** — fallback replies; `MAX_AI_MESSAGES_PER_DAY` cap |
| R-5 | Thin automated test coverage lets regressions ship | High | Medium | **Mitigate** — execute the Testing Spec §7 gap-closure plan |
| R-6 | CI not triggered on `main` | High | Medium | **Mitigate** — align workflow trigger branches |
| R-7 | Android release signed with debug keys | Medium | High | **Mitigate** — configure a production keystore |
| R-8 | Speech models gated; speech unusable without `.ddp` | Medium | Medium | **Accept/Mitigate** — text-only fallback; clear setup flow |
| R-9 | AI session-open path stubbed | Medium | Low | **Mitigate** — complete the AI wiring |
| R-10 | Documentation drift (stale READMEs, port mismatch) | Medium | Low | **Mitigate** — reconcile docs and `cmds/` scripts |
| R-11 | Single CA / secret compromise | Low | High | **Mitigate** — keep secrets off-host where possible; rotation plan |
| R-12 | Single ops person — bus factor | Medium | Medium | **Mitigate** — this documentation set; cross-training |

## 8. Quality management

- **Definition of done** for a change: implemented, reviewed, CI green
  (lint, build, tests), documentation updated where affected.
- **Coverage:** tracked against the Testing Specification targets.
- **Regression:** every defect fix adds a test (fails before, passes
  after).

## 9. Communication & change control

- Scope and requirement changes are assessed against the SRS and the
  Requirements Traceability Matrix before acceptance.
- Interface changes follow the Interface Control Document change-control
  procedure.
- Release decisions are made against the Deployment Runbook
  pre-production checklist.

## 10. Assumptions

- Team size and cadence remain small-scale.
- External AI provider remains available and within budget.
- Target platforms remain Android and Windows for v1.0.

---

*End of Project & Risk Management Plan.*
