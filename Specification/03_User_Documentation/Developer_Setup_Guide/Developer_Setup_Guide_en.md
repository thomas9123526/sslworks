---
title: "vLearn2 (VFLS) — Developer Setup Guide"
author: "vLearn2 Engineering"
date: "2026-05-22"
---

# Developer Setup Guide

**Project:** vLearn2 (VFLS) · **Version:** 1.0 · **Date:** 2026-05-22
**Audience:** Developers setting up a local environment.

---

## 1. Overview

vLearn2 has four subsystems in one repository:

```
vLearn2/
├── backend/        NestJS API
├── admin_panel/    Next.js admin console
├── flutter_app/    Flutter app (Android + Windows)
├── datamanage/     Win32 C++ packaging tool
└── docker-compose.yml   PostgreSQL for local dev
```

You can work on one subsystem without setting up the others.

## 2. Prerequisites

| Tool | Version | For |
|------|---------|-----|
| Node.js | 22+ | backend, admin panel |
| npm | bundled with Node | package management |
| Docker | recent | local PostgreSQL |
| PostgreSQL | 16 | (if not using Docker) |
| Flutter SDK | 3.41+ (Dart 3.11) | Flutter app |
| Android SDK | API 24+ | Android builds |
| Visual Studio + "Desktop development with C++" | 2022 | Windows Flutter builds |
| JDK | 17 | Android Gradle |

## 3. Database

```bash
# from the repo root
docker compose up -d postgres
```

This starts PostgreSQL 16 (`vlearn2-postgres`, port 5432, database
`vlearn2`). If you run PostgreSQL yourself, create a `vlearn2` database
and set the `DB_*` variables accordingly.

## 4. Backend

```bash
cd backend
npm install
cp .env.example .env          # then edit values (see below)
npm run db:migrate            # apply schema
npm run db:seed               # load reference content
npm run start:dev             # watch mode
```

Minimum `.env` values to set: `DB_*`, `JWT_ACCESS_SECRET`,
`JWT_REFRESH_SECRET`, and an AI provider key (`ANTHROPIC_API_KEY` or
the `OPENAI_*` group). The API serves on `PORT` (default 3000); Swagger
UI is at `/api/docs`.

Useful scripts: `npm run start` (no watch), `npm run build`,
`npm test`, `npm run test:e2e`, `npm run db:migrate:generate`.

## 5. Admin panel

```bash
cd admin_panel
npm install
cp .env.example .env          # set NEXT_PUBLIC_API_BASE_URL, BACKEND_BASE_URL
npm run dev                   # http://localhost:4100/vAdmin/
```

`NEXT_PUBLIC_API_BASE_URL` should point at the backend (for local dev,
`http://localhost:3000/api`). Remember `NEXT_PUBLIC_*` values are
inlined at build time. Other scripts: `npm run build`, `npm run start`,
`npm run typecheck`, `npm test`.

## 6. Flutter app

```bash
cd flutter_app
flutter pub get
dart run build_runner build   # generate Riverpod / freezed / drift code
flutter run -d windows        # or: flutter run -d <android-device>
```

The API base URL is read at runtime from an on-device
`app_config.json`, or can be overridden at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/vfls
```

Builds: `flutter build apk --release`,
`flutter build windows --release`. Tests: `flutter test`.

> On-device speech features need a `.ddp` model bundle; without one the
> app runs speech in placeholder mode. This is normal for development.

## 7. DataManage tool (optional)

The `datamanage/` Win32 C++ tool builds `.ddp` model bundles. Build it
only if you are working on model packaging; see `datamanage/README.md`.

## 8. Running everything together

For an integrated local stack:

1. Start PostgreSQL (`docker compose up -d postgres`).
2. Start the backend (`npm run start:dev`).
3. Start the admin panel (`npm run dev`).
4. Run the Flutter app pointing at the local backend.

Alternatively, the `cmds/` scripts launch the backend and admin panel
together.

## 9. Code generation note

The Flutter app uses code generation (Riverpod, freezed,
json_serializable, drift). After changing annotated files, re-run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 10. Tests and CI

- Backend / admin: `npm test` (Jest).
- Flutter: `flutter test`.
- CI (GitHub Actions) builds and tests each subsystem on push. Note the
  workflows currently trigger on `master`/`dev`; confirm your branch is
  covered.

## 11. Common issues

| Symptom | Fix |
|---------|-----|
| Backend cannot connect to DB | Check `DB_*` and that PostgreSQL is up |
| Flutter build errors after pulling | Re-run `build_runner build` |
| Admin panel shows wrong API target | Rebuild after changing `NEXT_PUBLIC_*` |
| Windows Flutter build fails | Install the Visual Studio C++ workload |
| `flutter pub get` fails offline | Populate the pub cache while online first |

---

*End of Developer Setup Guide.*
