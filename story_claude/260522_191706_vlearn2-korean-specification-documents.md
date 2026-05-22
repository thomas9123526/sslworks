# vLearn2 — Korean specification documents (md + docx)

## Task

Produce Korean-language versions of the three vLearn2 specification
documents — System Design, Requirements, Testing — in both Markdown and
Microsoft Word (.docx) formats, saved to the `Specification/` folder.

## Conversation

**User:**
> From "C:\project\vLearn2" project, Can you make me a "System Design
> Specification" "Requirements Specification" "Testing Specification" as
> md format and Microsoft Word format like .docx. in Korean Language.
> Save result to Specification folder

**Assistant:**
No re-exploration was needed — the full vLearn2 inventory and the
English specs (committed in `1c5d011`) were already available. Wrote
Korean versions of all three documents and converted them.

### Files written (in `Specification/`, `_ko` suffix)

- **vLearn2_System_Design_Specification_ko.md** — 시스템 설계 명세서.
  11 sections: 개요, 시스템 개관(컨텍스트 다이어그램), 아키텍처, 기술
  스택, 데이터 설계(26개 엔티티), 백엔드/관리자/Flutter 설계, 공통
  관심사, 배포 아키텍처, 알려진 제약사항.
- **vLearn2_Requirements_Specification_ko.md** — 요구사항 명세서.
  ~75 functional requirements (`FR-*`) + ~25 non-functional (`NFR-*`),
  using Korean spec convention "~해야 한다" for *shall*.
- **vLearn2_Testing_Specification_ko.md** — 테스트 명세서. Test
  strategy, coverage baseline, ~90 test cases (`TC-*`) traced to
  `FR`/`NFR`, gap-closure plan, risks.

### Translation approach

- Full professional Korean technical translation of the English
  documents, same structure and section numbering.
- Requirement / test-case identifiers (`FR-*`, `NFR-*`, `TC-*`),
  code symbols, entity names, enum values, and file paths kept verbatim
  in English — standard practice for Korean technical specs.
- "shall" rendered as "~해야 한다"; ASCII context diagrams relabelled
  in Korean.

### Conversion

`pandoc <name>.md -o <name>.docx --toc --toc-depth=2 --number-sections`
for all three. All succeeded. Word handles Hangul via CJK font
fallback; pandoc's default styling is used.

### Notes

- `_ko` filename suffix keeps the Korean docs clearly paired with the
  English originals and avoids non-ASCII filenames in git on Windows.
- The `Specification/` folder now holds 12 files: English + Korean,
  each as `.md` + `.docx`.
- vLearn2 itself was not modified. Saved to `story_claude/` (general
  vLearn2 work, not the datatool).

## Latest prompt

> From "C:\project\vLearn2" project, Can you make me a "System Design
> Specification"
>
> "Requirements Specification"
>
> "Testing Specification" as md format and Microsoft Word format like
> .docx. in Korean Language.
> Save result to Specification folder
