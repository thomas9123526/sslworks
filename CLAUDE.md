# tempPrompt — Claude workflow rules

## Commit + conversation log after every small task

A **small task** = a discrete user request that produced real changes (file edits,
installs, fixes, configuration). Pure questions / exploration that touched nothing
do **not** count — skip the workflow.

When a small task is done, do **both** of these in one commit:

### 1. Save the conversation to `story_claude/`

Write a markdown file at `story_claude/<datetime>_<shorttitle>.md`.

- `<datetime>` = local time as `yymmdd_hhmmss` (e.g. `260521_145532`).
- `<shorttitle>` = kebab-case summary of the task, **max 50 characters**.

File contents:

```markdown
# <shorttitle, human-readable>

<full back-and-forth for this task — user messages and assistant replies,
in order. Code blocks, tool results, and decisions included. Keep it
faithful to what actually happened, not a polished summary.>

## Latest prompt

<the user's most recent prompt, verbatim>
```

### 2. Git commit

Stage the task's changes **and** the new `story_claude/*.md` file, then commit
with a message that reports what was done — one short subject line, optional
body for context. One commit per task.

### Skip when

- The task is still in progress (mid-task — wait until done).
- No files changed (pure Q&A, planning discussion, exploration).
- The user explicitly says not to commit.

## Datatool project — use `story_datatool/` instead

If the work is on the **vLearn2 datatool project** (a separate effort
started 2026-05-21 — the data-management tool the user is building for
the vLearn2 stack), save the conversation log to `story_datatool/`
instead of `story_claude/`. Same filename format
(`yymmdd_hhmmss_<shorttitle>.md`, ≤ 50-char title), same content shape,
same "skip when" rules. Only the destination folder changes.

Non-datatool work (general HTTPS / mTLS work, repo plumbing, anything
not about the datatool itself) continues to use `story_claude/`.
