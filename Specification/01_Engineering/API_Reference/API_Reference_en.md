---
title: "vLearn2 (VFLS) — API Reference"
subtitle: "Backend REST API"
author: "vLearn2 Engineering"
date: "2026-05-22"
---

# API Reference

**Project:** vLearn2 (VFLS) · **Version:** 1.0 · **Date:** 2026-05-22
**Source:** Backend NestJS service; authoritative spec at `/api/docs`.

---

## 1. Conventions

- **Base path:** all endpoints are prefixed `/api` except `GET /health`.
  In production nginx maps the public path `/vfls/*` to `/api/*`.
- **Format:** JSON request and response bodies; `Content-Type:
  application/json` unless noted (image uploads use
  `multipart/form-data`).
- **Authentication:** `Authorization: Bearer <access token>` unless an
  endpoint is marked **Public**. Every route is protected by default.
- **Actors:** the JWT carries an `actor` claim (`user` or `admin`).
  Learner endpoints require `actor=user`; admin endpoints require
  `actor=admin` plus the relevant permission.
- **Rate limiting:** default 120 requests / 60 s per client; exceeding
  it returns `429 Too Many Requests`.
- **Errors:** non-2xx responses return a NestJS error body carrying an
  `i18nKey` (for example `auth.invalid_credentials`).

## 2. Standard status codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Resource created |
| 204 | Success, no body |
| 400 | Validation error (bad/unknown fields) |
| 401 | Missing/invalid/expired token |
| 403 | Authenticated but not permitted |
| 404 | Resource not found |
| 409 | Conflict (e.g. deleting a category in use) |
| 429 | Rate limit exceeded |
| 5xx | Server error |

---

## 3. Health

### `GET /health` — **Public**

Liveness probe. No prefix, no auth.

Response `200`: `{ "status": "ok" }`

---

## 4. Learner authentication — `/api/auth`

| Method & path | Auth | Description |
|---------------|------|-------------|
| `POST /auth/signup` | Public | Create a learner account. Body: `cid`, `cidUsername`, `password` (6–128), `displayName`, `uiLanguage`. Returns access + refresh tokens. |
| `POST /auth/signin` | Public | Authenticate; returns access + refresh tokens. |
| `POST /auth/refresh` | Public | Exchange a refresh token for a new access token; the refresh token is rotated (single-use). |
| `POST /auth/signout` | JWT | Invalidate the current refresh token. `204`. |
| `GET /auth/me` | JWT | Return the decoded token payload for the current learner. |

## 5. Learner profile — `/api/users`

| Method & path | Auth | Description |
|---------------|------|-------------|
| `GET /users/profile` | JWT | Current learner's profile (level, XP, streak, preferences). |
| `PATCH /users/profile` | JWT | Update display name, avatar, gender, language, theme, persona, onboarding flag, or password (password change requires the current password). |

## 6. Learning content (learner) 

| Method & path | Auth | Description |
|---------------|------|-------------|
| `GET /personas` | JWT | List active tutor personas. |
| `GET /personas/:id` | JWT | Persona detail. |
| `GET /scenarios` | JWT | List published scenarios. Query: `category`, `difficulty`, `q`. |
| `GET /scenarios/:idOrSlug` | JWT | Scenario detail (objectives, key phrases, roles). |
| `GET /categories` | JWT | List active scenario categories. |
| `GET /courses` | JWT | List published courses. |
| `GET /courses/:idOrSlug` | JWT | Course detail with ordered scenarios. |

## 7. Conversations — `/api/conversations`

| Method & path | Auth | Description |
|---------------|------|-------------|
| `POST /conversations/sessions` | JWT | Start a session. Body: `personaId` (UUID), optional `scenarioId`, `mode` (`chat`\|`face`). |
| `GET /conversations/sessions` | JWT | List the learner's sessions (filterable). |
| `GET /conversations/sessions/:id` | JWT | Session detail including messages. |
| `POST /conversations/sessions/:id/messages` | JWT | Send a learner message (1–5000 chars); returns the tutor reply. |
| `POST /conversations/sessions/:id/end` | JWT | End the session; records duration, turns, words, XP. |
| `DELETE /conversations/sessions/:id` | JWT | Delete a session and its messages. |
| `POST /conversations/sessions/:id/suggest` | JWT | Request an idle-prompt suggestion. |

## 8. Progress & achievements

| Method & path | Auth | Description |
|---------------|------|-------------|
| `GET /progress` | JWT | Aggregate progress (sessions, minutes, words, streaks). |
| `GET /progress/snapshots` | JWT | Daily per-skill snapshots. |
| `GET /progress/completions` | JWT | Per-scenario completion records. |
| `POST /progress/snapshots` | JWT | Upsert today's snapshot (running-averaged). |
| `GET /achievements` | JWT | Achievement catalog. |
| `GET /achievements/mine` | JWT | Achievements earned by the learner. |

## 9. News & app config

| Method & path | Auth | Description |
|---------------|------|-------------|
| `GET /news` | JWT | Paginated news with per-learner read flags. |
| `GET /news/unread-count` | JWT | Unread post count. |
| `POST /news/read-all` | JWT | Mark all posts read. |
| `POST /news/:id/read` | JWT | Mark one post read. |
| `GET /news/:idOrSlug` | JWT | News post detail. |
| `GET /app-config` | JWT | App-visible configuration flags. |

---

## 10. Admin authentication — `/api/admin/auth`

| Method & path | Auth | Description |
|---------------|------|-------------|
| `POST /admin/auth/signup` | Public* | Create an admin. First signup → `superadmin`, rest → `admin`. *See Security Specification — must be gated before public deployment.* |
| `POST /admin/auth/signin` | Public | Admin sign-in. |
| `POST /admin/auth/refresh` | Public | Rotate admin refresh token. |
| `POST /admin/auth/signout` | JWT | Invalidate admin refresh token. |

## 11. Admin operations

All require `actor=admin` and the named permission (a `superadmin`
bypasses permission checks).

| Area | Endpoints | Permission |
|------|-----------|------------|
| Admins | `GET/POST /admin/admins`, `GET /admin/admins/me/permissions`, `PUT /admin/admins/:id/permissions`, `POST\|DELETE /admin/admins/:id/permissions/:perm`, `POST /admin/admins/:id/suspend\|restore`, `DELETE /admin/admins/:id` | `admins.*` (create is superadmin-only) |
| Stats | `GET /admin/stats` | any admin |
| Users | `GET /admin/users`, `GET /admin/users/:id`, `POST /admin/users/:id/suspend\|restore`, `POST /admin/users/:id/reset-password` | `users.view`, `users.suspend`, `users.reset_password` |
| Scenarios | `GET/POST /admin/scenarios`, `GET/PATCH /admin/scenarios/:id`, `POST /admin/scenarios/:id/publish\|archive`, `DELETE /admin/scenarios/:id`, `POST /admin/scenarios/:id/image` | `scenarios.view\|edit\|delete\|upload_image` |
| Personas | `GET/POST /admin/personas`, `GET/PATCH /admin/personas/:id`, `DELETE`, `POST /admin/personas/:id/restore\|image` | `personas.edit` |
| Categories | `GET/POST /admin/categories`, `GET/PATCH /admin/categories/:id`, `DELETE` | `categories.view\|edit\|delete` |
| Leaderboard | `GET /admin/leaderboard` (metric: `xp_total\|streak_days\|current_level`) | `leaderboard.view` |
| Prompt templates | `GET /admin/prompt-templates`, `GET/PATCH /admin/prompt-templates/:kind` | `prompts.view\|edit` |
| News | `GET/POST /admin/news`, `GET/PATCH /admin/news/:id`, `POST /admin/news/:id/publish\|archive`, `DELETE` | `news.view\|edit\|delete` |
| Audit | `GET /admin/audit` (filter actor/action/target/since/until) | `audit.view` |
| Config | `GET /admin/config`, `GET/PATCH /admin/config/:key`, `POST /admin/config/reset/:key`, `POST /admin/config/reset-all` | `config.view\|edit` (reset-all superadmin-only) |

---

## 12. Image upload

`POST /admin/scenarios/:id/image` and `POST /admin/personas/:id/image`
accept `multipart/form-data`. Constraints: type `jpeg`/`png`/`webp`,
size ≤ 5 MB. Returns the stored file metadata.

## 13. OpenAPI

The complete, always-current specification — including request/response
schemas — is served by Swagger UI at `/api/docs` (spec JSON at
`/vfls/docs-json` behind nginx).

---

*End of API Reference.*
