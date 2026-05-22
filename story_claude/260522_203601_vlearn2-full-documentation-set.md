# vLearn2 — full 19-document bilingual documentation set

## Task

Produce every document type previously offered for vLearn2 — 16 new
documents plus the 3 existing core specs — in English and Korean,
Markdown and Microsoft Word, organized into a category folder structure
inside `Specification/`.

## Conversation

**User:**
> Can you produce all of them in English and Korean with the folder
> structure inside Specification?

(Following an earlier turn where the assistant listed 16 additional
document types beyond the existing Requirements / System Design /
Testing specs.)

**Assistant:**
Executed in five committed batches.

### Folder structure

Reorganized `Specification/` into category folders; the 3 existing
specs were `git mv`-d into `00_Core/` with a consistent
`<Name>_en/_ko.md/.docx` naming scheme. Added `Specification/README.md`
as an index.

```
Specification/
├── 00_Core/            Requirements, System Design, Testing
├── 01_Engineering/     API Reference, Database Design, Security,
│                       ADR, Deployment Runbook, Interface Control
├── 02_Management/      PRD, Traceability Matrix, Project/Risk Plan
├── 03_User_Documentation/  User Manual, Admin Guide, Developer Setup,
│                           Release Notes
└── 04_Quality_Assurance/   Detailed Test Cases, Test Summary Report,
                            UAT Plan
```

19 documents total, each leaf folder holding 4 files (EN/KO ×
md/docx) — 76 document files plus two README/index files.

### Commits (5 checkpoints)

1. `Restructure Specification/ into category folders` — move existing
   3 specs, add empty folders + README.
2. `Add Engineering documents` — 6 docs.
3. `Add Management documents` — 3 docs.
4. `Add User Documentation` — 4 docs.
5. `Add QA documents` — 3 docs (this commit, with this story file).

### New documents written (16)

- **Engineering:** API Reference (endpoint catalog), Database Design
  Document (26-entity data dictionary + ERD), Security Specification &
  Threat Model (STRIDE analysis, 7 weaknesses + remediation),
  Architecture Decision Records (12 ADRs), Deployment & Operations
  Runbook, Interface Control Document (8 interfaces).
- **Management:** Product Requirements Document, Requirements
  Traceability Matrix (every FR/NFR → SDS section → TC), Project & Risk
  Management Plan (12-entry risk register).
- **User Documentation:** End-User Manual, Administrator Guide,
  Developer Setup Guide, Release Notes (v1.0.0).
- **QA:** Detailed Test Cases (executable case template), Test Summary
  Report (point-in-time baseline), UAT Plan (26 acceptance scenarios).

### Tooling

All Markdown converted to docx via pandoc 3.9.0.2 with `--toc
--toc-depth=2 --number-sections`. 32 docx conversions, all succeeded.

### Honest framing carried into the documents

- **Test Summary Report** is explicitly a point-in-time baseline — it
  records the test assets that exist, not an executed campaign; §4 is
  a results template to fill after each cycle.
- **Release Notes** is a v1.0.0 document built from the current
  feature set.
- The specs remain reconstructed-from-code, framed as a maintenance
  baseline.
- Known gaps (stubbed AI session-open, disabled gzip kill-switch,
  debug-keyed Android release, open admin signup, CI branch mismatch)
  are carried consistently across SDS §11, the Security Spec, the risk
  register, the Test Summary Report, and the Release Notes.

### Notes

- vLearn2 itself was not modified — all documents derive from the
  earlier read-only inventory.
- Saved to `story_claude/` (general vLearn2 work, not the datatool).

## Latest prompt

> Can you produce all of them in English and Korean with the folder
> structure inside Specification?
