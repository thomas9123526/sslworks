# vLearn2 — three specification documents (md + docx)

## Task

Produce three formal specification documents for the `C:\project\vLearn2`
project — System Design Specification, Requirements Specification,
Testing Specification — in both Markdown and Microsoft Word (.docx)
formats, saved to a `Specification/` folder.

## Conversation

**User:**
> From "C:\project\vLearn2" project, Can you make me a "System Design
> Specification" "Requirements Specification" "Testing Specification" as
> md format and Microsoft Word format like .docx. Save result to
> Specification folder

**Assistant:**

### 1. Deep inventory of vLearn2

Ran a general-purpose agent for a thorough read-only inventory.
Findings used as the factual basis for all three documents:

- Product: "Virtual Foreign Language" (VFLS); repo name vLearn2 — an
  English conversational-learning platform with AI tutor personas.
- Four subsystems: Flutter app (Android + Windows), NestJS 11 backend,
  Next.js 14 admin panel, DataManage C++ `.ddp` packaging tool;
  PostgreSQL 16.
- Backend: 14 modules, 26 TypeORM entities, dual-actor JWT auth,
  permission-based admin RBAC, AI orchestration (Anthropic /
  OpenAI-compatible), content guard.
- Existing tests: thin — 3 backend, 3 admin, 4 Flutter, 3 DataManage
  smoke files; bulk of business logic untested.
- Known gaps captured: stubbed AI session-open, disabled gzip
  kill-switch, debug-keyed Android release, CI branch mismatch, open
  admin signup, etc.

### 2. Tooling

`pandoc` was not installed; installed Pandoc 3.9.0.2 via winget. Used
it for Markdown -> docx conversion. (python-docx / libreoffice were
absent; pandoc is the cleanest path and handles the YAML title block,
TOC, and numbered sections.)

### 3. Documents written (in `Specification/`)

- **vLearn2_System_Design_Specification.md** — 11 sections:
  introduction, system overview + context diagram, architecture
  (module structure, request pipeline, deployment topology), tech
  stack, data design (26 entities grouped, relationships, enums),
  backend design (API surface, auth/RBAC, AI orchestration, content
  safety, uploads, config), admin panel design, Flutter app design,
  cross-cutting concerns, deployment, and a known-limitations register.
- **vLearn2_Requirements_Specification.md** — SRS with introduction,
  overall description (user classes, environment, constraints,
  assumptions), ~75 numbered functional requirements (`FR-*`) across
  15 areas, external-interface requirements, ~25 non-functional
  requirements (`NFR-*`), and a constraints/open-items section.
- **vLearn2_Testing_Specification.md** — test strategy (levels,
  per-subsystem approach, entry/exit criteria), test environment + CI,
  current-coverage baseline, ~90 functional + non-functional test
  cases (`TC-*`) each traced to an `FR-*`/`NFR-*`, coverage targets,
  a prioritized gap-closure plan, defect management, and risks.

The three documents cross-reference each other (SDS -> design, SRS ->
requirements with IDs, Testing -> traces every `FR`/`NFR` to a `TC`).

### 4. Conversion

`pandoc <name>.md -o <name>.docx --toc --toc-depth=2
--number-sections` for all three. All succeeded; six files now in
`Specification/` (three `.md`, three `.docx`).

### Notes

- The specs were reconstructed from the implemented code, not from a
  pre-existing requirements source; the SRS is explicitly framed as a
  reconstructed baseline for maintenance and regression.
- vLearn2 itself was not modified — read-only inspection only.
- Saved to `story_claude/` (general vLearn2 work, not the datatool).

## Latest prompt

> From "C:\project\vLearn2" project, Can you make me a "System Design
> Specification"
>
> "Requirements Specification"
>
> "Testing Specification" as md format and Microsoft Word format like
> .docx.
> Save result to Specification folder
