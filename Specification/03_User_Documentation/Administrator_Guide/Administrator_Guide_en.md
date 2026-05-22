---
title: "vLearn2 (VFLS) — Administrator Guide"
author: "vLearn2"
date: "2026-05-22"
---

# Administrator Guide

**Product:** vLearn2 (VFLS) admin panel · **Version:** 1.0
**Audience:** Staff managing content, users, and configuration.

---

## 1. Overview

The admin panel is a web console for managing the vLearn2 platform. It
is served at `/vAdmin/` on the deployment host. Through it, staff
manage learning content, learner accounts, AI prompt templates,
runtime configuration, and other administrators.

## 2. Roles and permissions

| Role | Capability |
|------|-----------|
| **Sub-admin** | A specific subset of permissions granted by a superadmin |
| **Admin** | Broad content and user management |
| **Superadmin** | Unrestricted; manages other admins and permissions |

Each capability maps to a named permission. The panel hides actions you
do not have permission for; the server independently enforces every
action.

## 3. Signing in

Open `/vAdmin/` and sign in with your admin credentials. Admin
passwords must be at least 12 characters with mixed case and a digit.
Your session is held in the browser; sign out when finished, especially
on shared computers.

> **First-time setup.** The first admin account created becomes a
> superadmin. This bootstrap signup route must be closed before the
> system is exposed publicly — see your operations team.

## 4. Dashboard

The dashboard shows summary statistics: total users, users active in
the last 30 days, total conversation sessions, and published
scenarios.

## 5. Managing content

### 5.1 Scenarios

Create, edit, publish, archive, and delete role-play scenarios. A
scenario has a category, difficulty, localized text (scene, roles,
objectives, key phrases), an estimated time, and an XP reward. You can
upload a scenario image (`jpeg`/`png`/`webp`, up to 5 MB). Scenarios
move through `draft` → `published` → `archived`.

### 5.2 Personas

Create and edit AI tutor personas — name, accent, style, specialties,
colors, avatar image, and voice. Personas can be deactivated
(soft-deleted) and restored.

### 5.3 Categories

Create, edit, and delete scenario categories. A category that is in use
by a scenario cannot be deleted — reassign or remove those scenarios
first.

### 5.4 Courses

Courses group scenarios into ordered learning paths.

### 5.5 News

Create, edit, publish, archive, and delete news posts. Posts can be
pinned to appear first for learners.

### 5.6 Prompt templates

Edit the AI prompt templates (tutor-system, grammar, feedback) that
shape tutor behaviour and scoring. Changes take effect without a
software deployment — review edits carefully.

## 6. Managing users

- **View** learner accounts and details.
- **Suspend / restore** a learner account.
- **Reset password** for a learner.
- **Leaderboard** — view top learners by XP, streak, or level.

## 7. Administering staff (superadmin)

- Create sub-admin accounts.
- Grant or revoke individual permissions. Privacy-sensitive
  permissions cannot be granted to sub-admins.
- Suspend, restore, or remove admin accounts.

## 8. Audit log

Every administrative change is recorded in the audit log with the
actor, action, target, and before/after values. Use the filters
(actor, action, target, date range) to investigate changes. The audit
log is the record of accountability — review it regularly.

## 9. Runtime configuration

The Config page exposes runtime feature flags grouped by app area. You
can change a flag, reset a flag to its default, or (superadmin only)
reset all flags. Flags marked visible to the app control feature
visibility in the learner app.

## 10. Good practice

- Use the least privilege necessary; grant sub-admins only what they
  need.
- Treat prompt-template and config changes as production changes —
  they affect learners immediately.
- Sign out of shared machines.
- Review the audit log after sensitive operations.
- Coordinate with operations before bulk changes.

## 11. Getting help

For deployment, access, or incident issues, contact your operations
team and refer to the Deployment & Operations Runbook.

---

*End of Administrator Guide.*
