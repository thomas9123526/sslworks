# Setup: per-task commit and story_claude rules

## Task

Configure Claude to, after each small task:

1. Run `git commit` with a report of what was done.
2. Save the conversation transcript as `story_claude/<datetime>_<shorttitle>.md`.
   - `<datetime>` = `yymmdd_hhmmss` (user revised from initial `hhss`).
   - `<shorttitle>` = abstraction of the conversation, ≤ 50 chars.
   - Append the user's latest prompt at the bottom.

## Conversation

**User:**
> configure claude that it should commit changes with report that what you
> have done after every small task done.
>
> I want you to configure claude that save our conversation as md file to
> story_claude when you do git commit for each task. Also append my prompt
> at the end.
> Md filename can be datetime_shorttitle.md.
> datetime means current time as yymmdd_hhss. shorttitle means abstraction
> title for our conversation. shorttitle length should not more than 50
> letters.

**Assistant:**
Inspected the project — no existing `CLAUDE.md`, existing `story/` folder
but the user asked for `story_claude/`. Created the directory and wrote
`CLAUDE.md` with workflow rules. Flagged that `hhss` was likely a typo and
interpreted it as `hhmm` (hour+minute), asking for confirmation.

Files created:
- `CLAUDE.md` — project-level workflow rules (auto-loaded each session)
- `story_claude/` — destination folder for conversation logs

**User:**
> hhmmss

**Assistant:**
Updated `CLAUDE.md` to use `yymmdd_hhmmss` (e.g. `260521_145532`) and
removed the explanatory note. Asked to proceed with the first logged
commit.

**User:**
> ok

**Assistant:**
Checked `git status` (untracked: `CLAUDE.md`, `certs/`), got current
timestamp `260521_115839`, wrote this story file, and prepared to stage +
commit only `CLAUDE.md` and the story file. Did **not** stage `certs/`
because it contains a private key (`localhost+2-key.pem`) that should not
be checked into the repo — flagging separately so the user can decide
whether to add a `.gitignore` rule.

## Latest prompt

> ok
