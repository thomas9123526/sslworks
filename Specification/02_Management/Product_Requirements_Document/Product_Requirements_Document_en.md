---
title: "vLearn2 (VFLS) — Product Requirements Document"
author: "vLearn2 Product"
date: "2026-05-22"
---

# Product Requirements Document

**Project:** vLearn2 (VFLS) · **Version:** 1.0 · **Date:** 2026-05-22

A business- and product-facing companion to the technical Requirements
Specification (SRS). Where the SRS enumerates `FR/NFR` requirements,
this PRD states the *why*: goals, users, priorities, and success
measures.

---

## 1. Product summary

vLearn2 — marketed as *Virtual Foreign Language* (VFLS) — is a mobile
and desktop application for practising spoken and written English
through conversation with AI tutor personas. Learners practise freely
or through structured role-play scenarios, receive automated
multi-skill feedback, and stay motivated through progress tracking,
streaks, and achievements.

## 2. Problem statement

Conventional language learning offers limited low-pressure speaking
practice. Learners lack a patient, always-available conversation
partner and rarely receive specific, multi-dimensional feedback on
pronunciation, fluency, grammar, and vocabulary. vLearn2 addresses this
with on-demand AI conversation and automated scoring.

## 3. Goals and non-goals

### 3.1 Goals

- Provide unlimited, low-pressure conversational practice with varied
  AI tutor personas.
- Give learners structured scenarios graded by difficulty and grouped
  into courses.
- Deliver actionable, multi-skill feedback after each session.
- Sustain motivation via XP, levels, streaks, and achievements.
- Work cross-platform (Android, Windows) from one codebase.
- Allow staff to manage content and users without engineering
  involvement.

### 3.2 Non-goals (current release)

- Languages other than English.
- Live human tutoring.
- Social/peer features beyond a leaderboard.
- Payments / subscription billing.

## 4. Target users

| Segment | Description | Primary need |
|---------|-------------|--------------|
| Self-study learner | Practising English independently | Confidence, speaking practice, feedback |
| Guided learner | Following a structured path | Scenarios and courses with clear progression |
| Content staff | Authoring scenarios, personas, news | Efficient content tools |
| Operations staff | Managing users, config, governance | Control, auditability |

## 5. Feature priorities

| Priority | Feature area |
|----------|--------------|
| P0 (must) | Account/auth, AI conversation (chat + face mode), scenarios, scoring & session report, progress tracking |
| P1 (should) | Courses, achievements, news, on-device speech (STT/TTS), offline read cache, admin content management |
| P2 (could) | Leaderboard, themes/fonts, multi-UI-language, runtime feature flags |

## 6. Key user journeys

1. **Onboard & first conversation** — sign up → onboarding → pick a
   persona → free-talk or scenario → receive a session report.
2. **Structured practice** — browse courses → open a scenario brief →
   complete the role-play → see score and XP → progress updates.
3. **Stay motivated** — daily practice extends the streak → XP raises
   level → achievements unlock.
4. **Staff content cycle** — author a scenario → upload artwork →
   publish → monitor via stats and audit log.

## 7. Success metrics (suggested)

| Metric | Intent |
|--------|--------|
| Activation | % of new users completing a first conversation |
| Engagement | Sessions per active user per week; median streak length |
| Learning | Trend of per-skill snapshot scores over time |
| Retention | 7-day and 30-day return rate |
| Content health | Published scenarios; scenario completion rate |
| Reliability | Conversation success rate including AI-fallback path |

Targets should be set per release once a measurement baseline exists.

## 8. Constraints and dependencies

- Requires an external AI provider (Anthropic or OpenAI-compatible);
  degrades gracefully when unavailable.
- On-device speech requires an installed, signed `.ddp` model bundle.
- Android minimum SDK 24; Windows desktop.
- Backend deployable on Linux (RHEL-class) or Windows behind nginx.

## 9. Release scope — v1.0

In scope: all P0 and P1 features for Android and Windows; the admin
panel; the supporting backend.

Known limitations carried into v1.0 (see System Design Specification
§11): the AI session-open message is a placeholder; on-device speech
is gated on a model bundle; the admin signup route is open for
bootstrap and must be gated before public launch.

## 10. Open questions

- Monetization model and timing.
- Additional target languages and prioritization.
- Per-device enrollment vs. the current shared-client model for
  stronger device identity.
- Localization scope beyond English and Chinese UI.

---

*End of Product Requirements Document.*
