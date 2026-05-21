# Setup story_datatool workflow

## Task

Open the vLearn2 datatool project. Configure the story-logging workflow
so datatool-related conversations land in `story_datatool/` instead of
`story_claude/`, keeping the existing rules in CLAUDE.md intact for
non-datatool work.

## Conversation

**User:**
> ok let's talk about new project with the vLearn2 project. I need to
> make a datamanage tool.

**Assistant:**
"Datamanage tool" is ambiguous — could be a CLI for the ops person
(migrations / seeding / backups), a feature inside the existing admin
panel (bulk edits, import/export, audit), or a standalone app
(pgAdmin-style UI specific to the domain). Each has very different
architecture, auth, and where it lives in vLearn2. Asked what the job
actually is and who uses it.

**User:**
> I want you to configure claude that save our conversation as md file
> to story_datatool when you do git commit for each task. Also append
> my prompt at the end.
> Md filename can be datetime_shorttitle.md.
> datetime means current time as yymmdd_hhss. shorttitle means
> abstraction title for our conversation. shorttitle length should not
> more than 50 letters.

**Assistant:**
Interpreted as: separate story folder for the datatool project, same
rules as the existing story_claude flow. Treated `hhss` as `hhmmss`
again (same correction we made earlier for story_claude — kept
consistent so both folders use the same timestamp format).

Changes:

1. Created folder `story_datatool/` at the project root.
2. Added a new section to `CLAUDE.md` — "Datatool project — use
   story_datatool/ instead" — that routes datatool conversations to
   the new folder while leaving the existing rule for non-datatool
   work in place.
3. Wrote this story file as the first entry in `story_datatool/`.

The actual scope of "the datatool" is still TBD — answer to the
clarifying question is pending. Once it's defined, future tasks (build
the CLI, add the admin-panel feature, scaffold the UI, etc.) get
their own story files here.

## Latest prompt

> I want you to configure claude that save our conversation as md file
> to story_datatool when you do git commit for each task. Also append
> my prompt at the end.
> Md filename can be datetime_shorttitle.md.
> datetime means current time as yymmdd_hhss. shorttitle means
> abstraction title for our conversation. shorttitle length should not
> more than 50 letters.
