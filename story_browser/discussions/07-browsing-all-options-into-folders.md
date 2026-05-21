# Discussion 07 — Auto-browse every option into `story_browser/`

**Span:** "i want browser all cases..." through commit of
`story_browser/choice-*` tree.

## Goal

User wanted a "browse" of every option — not just the picked ones —
saved in a structured folder layout. The reference guides from phase
05 are concise comparisons; this asked for a deeper, per-option
walkthrough.

> "i want browser all cases, please auto browse all cases and save
> each conversation with the structed folders to story_browser"

## Interpretation

- "browser" → browse (verb).
- "all cases" → every option of every choice (11 total: 2 + 3 + 3 +
  3), not just the alternatives we didn't pick.
- "structed folders" → one folder per choice; one file per option
  inside.
- "save each conversation" → a per-option walkthrough, written as a
  self-contained exploration.

## Structure

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

## Walkthrough template

Every option file follows the same shape so readers can compare
options at-a-glance:

1. **The case for it** — the honest pitch for picking this option.
2. **Concrete setup** — commands to run, file trees produced.
3. **Distribution / wiring** — where the artifacts go.
4. **Trade-offs that surface** — what actually bites in practice.
5. **What "compromise" looks like** — failure modes and recovery.
6. **Migration from / to other options** (where relevant).
7. **Verdict** — would-I-pick-this for vLearn2 specifically.

## Notable opinions in the walkthroughs

- **2C (hybrid bootstrap)** — "probably not worth it as a starting
  point — wait until pure A's limitations actually bite."
- **3B (shared admin cert)** — "Hard to recommend. It's only simpler
  at the moment of first distribution."
- **4B (modern AES PBE)** — flagged an unsolved compat question:
  RHEL7's shipped OpenSSL 1.0.2k may or may not accept
  `-keypbe AES-256-CBC` (it can name the algorithm but might reject
  it for PKCS#12 use); needs testing on the actual host.

## Decisions made

- A new folder tree at `story_browser/` — sibling to the existing
  `story_claude/` (real conversations) and `prompts/` (user's notes).
- Per-choice subfolder, per-option file. Lets the user revisit a
  single option without scanning siblings.
- Wrote in narrative ("if you picked this, here's the story") rather
  than dialogue format. The user said "save each conversation" but
  the walkthroughs are exploratory single-author rather than
  back-and-forth; treating them as conversations would have been
  contrived.
- Baselines (what `gen-pki.sh` actually implements) flagged in the
  README status table and in each file header.

## Artifacts

- `story_browser/README.md`
- 11 walkthrough files across 4 subfolders.
- Total ~1500 lines.

## Where to look for the raw conversation

`story_claude/260521_160147_browse-all-mtls-options-story-browser.md`.
