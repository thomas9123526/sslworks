# story_browser/discussions/ — session timeline

Topical groupings of the whole session, in arrival order. Each file is
a narrative recap of one phase — goal, what happened, decisions made,
artifacts produced, and a back-pointer to the raw conversation log
in `story_claude/`.

This sits alongside the per-option walkthroughs at
`story_browser/choice-*/` and the conversation transcripts at
`story_claude/`. Three views of the same work:

- `story_claude/` — what was actually said, turn by turn.
- `story_browser/choice-*/` — every mTLS option, deeply.
- `story_browser/discussions/` — the session arc, summarized.

## Index

| # | Phase | File |
|---|---|---|
| 01 | Getting a cert running locally (mkcert via winget) | [01-getting-a-cert-locally.md](01-getting-a-cert-locally.md) |
| 02 | Pivot to RHEL7 / OpenSSL 1.0 — `gen-cert.sh` | [02-pivot-to-rhel7-and-gen-cert.md](02-pivot-to-rhel7-and-gen-cert.md) |
| 03 | vLearn2 inspection + `vlearn2-https-guide.md` | [03-vlearn2-https-guide.md](03-vlearn2-https-guide.md) |
| 04 | mTLS: `gen-pki.sh` + `vlearn2-mtls-guide.md` | [04-mtls-pki-and-guide.md](04-mtls-pki-and-guide.md) |
| 05 | Four design-choice reference guides | [05-four-choice-reference-guides.md](05-four-choice-reference-guides.md) |
| 06 | Walking each choice, picking A/A/A/A, random-password upgrade | [06-walking-through-each-choice.md](06-walking-through-each-choice.md) |
| 07 | Auto-browse every option into `story_browser/` | [07-browsing-all-options-into-folders.md](07-browsing-all-options-into-folders.md) |

## The story in one paragraph

Started with a `choco` typo trying to install mkcert; pivoted to
`winget`. Got a local mkcert dev cert working, then immediately
restarted when the user clarified the real target was RHEL7 with
OpenSSL 1.0 — built `gen-cert.sh`, tested with a live TLS 1.2
handshake on Windows Git Bash. The user pointed at vLearn2 (Flutter +
NestJS + Next.js); inspected it read-only and wrote a 13-section
HTTPS deployment guide referencing the actual code paths. User asked
for mTLS; built `gen-pki.sh` (CA + server + client subcommands) and
a delta guide layered on top of the HTTPS one; verified with positive
and negative live handshakes. User asked for individual guides per
design choice (CA strategy, Flutter cert, admin cert, PBE format) —
wrote four reference docs. Walked each choice conversationally, user
picked A across all four; upgraded `gen-pki.sh` to default to a
random per-cert .p12 password (the actual security knob, not the
PBE algorithm). User asked to browse every option in depth — built
`story_browser/choice-*/` with 11 per-option walkthroughs. User then
asked for this — the timeline grouping of the whole session.
