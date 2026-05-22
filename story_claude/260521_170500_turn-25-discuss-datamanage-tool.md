# Turn 25 — discuss datamanage tool

**User prompt:**
> ok let's talk about new project with the vLearn2 project. I need to
> make a datamanage tool.

**Assistant response:**
Treated as an exploratory opener (no implementation). Pointed out that
"datamanage tool" is ambiguous and could land in very different
places:

- a **CLI** for the ops person (migrations, seeding, backups);
- a **feature inside the existing admin panel** (bulk edits,
  import/export, audit);
- a **standalone app** (a pgAdmin-style UI specific to the domain).

Each has very different architecture, auth, and placement in the
vLearn2 stack. Asked what the actual job is — who uses it and what
data operations they need.

## Latest prompt

> ok let's talk about new project with the vLearn2 project. I need to
> make a datamanage tool.
