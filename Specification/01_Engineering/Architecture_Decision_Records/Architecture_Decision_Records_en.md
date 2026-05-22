---
title: "vLearn2 (VFLS) — Architecture Decision Records"
author: "vLearn2 Engineering"
date: "2026-05-22"
---

# Architecture Decision Records

**Project:** vLearn2 (VFLS) · **Version:** 1.0 · **Date:** 2026-05-22

Each record captures one significant architectural decision: its
context, the decision, and its consequences. Records are
reconstructed from the implemented system and are **Accepted** unless
noted.

---

## ADR-001 — Modular monolith for the backend

**Status:** Accepted

**Context:** The backend serves a single product with a moderately
sized domain (14 feature areas). A microservice split would add
deployment and operational overhead.

**Decision:** Implement the backend as a NestJS modular monolith — one
deployable process composed of independent feature modules.

**Consequences:** Simple deployment and local development; in-process
calls between modules; one database. If a single area later needs
independent scaling it can be extracted, since module boundaries are
already explicit.

---

## ADR-002 — Dual-actor JWT authentication

**Status:** Accepted

**Context:** Two distinct populations — learners and staff — share one
API. Separate auth stacks would duplicate logic.

**Decision:** Use one JWT structure with an `actor` discriminator
(`user` | `admin`) plus `role` and `permissions[]`. Learners and admins
have separate password and refresh-token tables.

**Consequences:** One guard pipeline handles both; the `actor` claim
prevents a learner token from being accepted on admin routes. Slightly
more complex token payload; guards must always check `actor`.

---

## ADR-003 — Auth-by-default with explicit opt-out

**Status:** Accepted

**Context:** Forgetting to protect a new endpoint is a common security
defect.

**Decision:** Register `JwtAuthGuard` globally; routes become public
only by an explicit `@Public()` decorator.

**Consequences:** New endpoints are secure unless deliberately opened.
Public endpoints are easy to enumerate (search for `@Public()`).

---

## ADR-004 — Permission-catalog RBAC for staff

**Status:** Accepted

**Context:** Staff need granular, auditable capabilities; a simple
role flag is too coarse.

**Decision:** Define a catalog of ~40 permission keys with
`grantable_to_subadmin` flags and `implies` chains. Enforce with
`PermissionGuard`; `superadmin` bypasses checks.

**Consequences:** Fine-grained control and a clear privilege model;
privacy-sensitive permissions are non-grantable. The catalog must be
kept in sync across backend, admin UI, and documentation.

---

## ADR-005 — TypeORM with UUID keys and `vl_` prefix

**Status:** Accepted

**Context:** The schema must evolve safely and coexist with other
schemas on shared infrastructure.

**Decision:** Use TypeORM with `gen_random_uuid()` UUID primary keys,
a `vl_` table prefix, and ordered migrations.

**Consequences:** Non-guessable keys; namespace isolation; reproducible
schema evolution. UUIDs are larger than integers — acceptable at this
scale.

---

## ADR-006 — JSONB for localized text

**Status:** Accepted

**Context:** Content (titles, descriptions) must support multiple
languages.

**Decision:** Store localized fields as JSONB `I18nText` objects rather
than separate translation tables.

**Consequences:** Simple reads/writes, no joins for translations.
Querying inside translations is less convenient; acceptable because
content is read whole.

---

## ADR-007 — Reverse-proxy path mapping (`/vfls`, `/vAdmin`)

**Status:** Accepted

**Context:** Backend and admin panel must be served from one public
host without port exposure.

**Decision:** nginx maps `/vfls/*` → backend `/api/*` and serves the
admin panel under `/vAdmin/*`. The backend internally uses the `/api`
prefix; the admin panel uses `basePath: /vAdmin`.

**Consequences:** One TLS endpoint, clean public URLs. Both apps must
be configured for their public path; the rewrite is a fixed contract.

---

## ADR-008 — Pluggable AI provider with graceful degradation

**Status:** Accepted

**Context:** The product depends on an external LLM, which may be
unavailable or change vendor.

**Decision:** Abstract the provider behind `AiProviderFactory`
(Anthropic or OpenAI-compatible, selected by env). On provider error,
return canned fallback replies and fall back to algorithmic grammar
scoring. Prompt content lives in editable database templates.

**Consequences:** Vendor flexibility; conversations stay usable during
outages; prompts tunable without deploys. Fallback output is lower
quality — acceptable as a degraded mode.

---

## ADR-009 — Riverpod + go_router for the Flutter app

**Status:** Accepted

**Context:** The app needs testable state management and declarative,
guard-aware navigation.

**Decision:** Use Riverpod for state and `go_router` for navigation,
with a redirect handler enforcing auth, onboarding, and speech-model
gates.

**Consequences:** Composable, testable providers; centralized routing
rules. Team must follow Riverpod conventions consistently.

---

## ADR-010 — Drift (SQLite) offline read cache

**Status:** Accepted

**Context:** Learners may use the app with poor or no connectivity.

**Decision:** Cache read-only content (users, scenarios, sessions,
messages, progress, settings, layout) in a local Drift SQLite
database.

**Consequences:** Usable offline read experience; resilience to
flaky networks. Cache freshness must be managed; writes still require
connectivity.

---

## ADR-011 — Signed `.ddp` bundles for speech models

**Status:** Accepted

**Context:** Large speech models cannot ship in the app binary and
must not be tampered with.

**Decision:** Package models with the DataManage tool into signed,
optionally encrypted/compressed `.ddp` bundles; the app verifies the
signature against a pinned root CA before install.

**Consequences:** Models are distributed and updated independently and
safely. Adds an offline packaging step and a CA-rotation concern.

---

## ADR-012 — Reconstructed specifications as a baseline

**Status:** Accepted

**Context:** The system was built ahead of formal specifications.

**Decision:** Reconstruct SRS/SDS/Testing and supporting documents from
the implemented system as a maintenance and change-control baseline.

**Consequences:** A documented baseline exists; future changes can be
controlled against it. The documents reflect "as-built", not original
intent.

---

*End of Architecture Decision Records.*
