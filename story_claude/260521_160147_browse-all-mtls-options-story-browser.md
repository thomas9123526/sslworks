# Auto-browse all mTLS options into story_browser/

## Task

User asked to "auto browse all cases" of the four mTLS design choices
and save each as a structured walkthrough under `story_browser/`.
Produced 11 walkthrough files (one per option across all four choices)
plus an index README, organised into four per-choice folders.

This is the second story-tree in the repo:
- `story_claude/` — real conversation logs per CLAUDE.md.
- `story_browser/` — structured per-option walkthroughs of the four
  mTLS design dimensions.

## Conversation

**User:**
> i want browser all cases, please auto browse all cases and save each
> conversation with the structed folders to story_browser

**Assistant:**
Interpreted "browser" as "browse", "all cases" as every option across
the four design choices (not just the picked ones), "structed folders"
as one folder per choice with one file per option, "save each
conversation" as a structured per-option walkthrough.

### Files produced (12)

```
story_browser/
├── README.md                                   index + status table
├── choice-1-ca-strategy/
│   ├── A-single-ca.md                          [baseline]
│   └── B-split-cas.md
├── choice-2-flutter-cert/
│   ├── A-shared-bundled.md                     [baseline]
│   ├── B-per-device-enrollment.md
│   └── C-hybrid-bootstrap.md
├── choice-3-admin-cert/
│   ├── A-per-admin.md                          [baseline]
│   ├── B-shared-admin.md
│   └── C-no-mtls-on-vAdmin.md
└── choice-4-pkcs12-pbe/
    ├── A-legacy-3des.md                        [baseline]
    ├── B-modern-aes256.md
    └── C-hybrid-emit-both.md
```

### Walkthrough shape

Each option file follows the same structure so a reader can compare
options at-a-glance:

1. **The case for it** — the honest pitch for picking this option.
2. **Concrete setup** — commands to run, file trees produced.
3. **Distribution / wiring** — where the artifacts go.
4. **Trade-offs that surface** — what actually bites in practice, not
   what theory says.
5. **What "compromise" looks like** — failure modes and recovery cost.
6. **Migration from / to other options** (where relevant).
7. **Verdict** — would-I-pick-this for vLearn2's specific shape (3
   admins, single ops person, OpenSSL 1.0.2k host, Flutter on
   Android + Windows, NestJS + Next.js stack).

### Tone

Walkthroughs are written as if a reader picked that option and wanted
the realistic story — not the marketing pitch. Notable spots where
the walkthrough pushes back on the option:

- **2C (hybrid bootstrap)** — explicitly notes "probably not worth it
  as a starting point — wait until pure A's limitations actually bite."
- **3B (shared admin cert)** — "Hard to recommend. It's only simpler
  at the moment of first distribution."
- **4B (modern AES PBE)** — flags the unsolved test question:
  RHEL7's shipped OpenSSL 1.0.2k may or may not accept the
  `-keypbe AES-256-CBC` flag, and you lose round-trip inspection
  on the host regardless.

### Cross-references

Each walkthrough links to its sibling options when discussing
migration. The README has the canonical status table marking the
four baselines.

### Not touched

- `gen-pki.sh` — unchanged.
- The four `vlearn2-mtls-choice-*.md` documentation files — unchanged
  (they cover the same ground but as concise reference docs rather
  than first-person walkthroughs).
- `test-pki/` — unchanged.

## Latest prompt

> i want browser all cases, please auto browse all cases and save each
> conversation with the structed folders to story_browser
