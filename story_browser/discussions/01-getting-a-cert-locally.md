# Discussion 01 — Getting a cert running locally (the false start)

**Span:** very first turn through "mkcert -install + localhost cert."

## Goal

Get a working dev cert on Windows so the user could test HTTPS. The
user's first attempt was `choco install mkcert`.

## What happened

`choco` wasn't installed. The user pasted the error:

```
choco : The term 'choco' is not recognized...
```

Inspected the Windows box — `winget` was present
(`C:\Users\aaa\AppData\Local\Microsoft\WindowsApps\winget.exe`), scoop
was not, choco was not. Suggested `winget install FiloSottile.mkcert`.

User said "i already run." Verified — `winget list --id
FiloSottile.mkcert` reported no install. The first `winget install`
attempt failed mid-flight on a msstore cert-validation error
(`0x8a15005e`). Pinned to the winget source explicitly:

```powershell
winget install --id FiloSottile.mkcert --source winget --accept-source-agreements --accept-package-agreements
```

Succeeded. mkcert v1.4.4 landed in PATH. Then:

```powershell
mkcert -install                  # installs local CA in Windows trust store
mkcert localhost 127.0.0.1 ::1   # generates cert in current dir
```

Output went into a new `certs/` folder at the project root:
`localhost+2.pem` + `localhost+2-key.pem`.

## Decisions made

- Use winget, not chocolatey (already available, no install needed).
- Generate cert for `localhost / 127.0.0.1 / ::1` SAN — standard dev
  trio.
- Put output in `certs/` at project root.

## Artifacts

- mkcert binary installed.
- mkcert CA in Windows trust store.
- `certs/localhost+2.pem`, `certs/localhost+2-key.pem`.

## What this turned out not to matter for

Once the user pivoted to RHEL7 + OpenSSL 1.0 in the next phase, the
mkcert work was orphaned. The CA stayed in the trust store (harmless),
the certs/ folder stayed on disk. Both were eventually committed in
phase 02 anyway because the user explicitly asked to keep them as
"test mode" artifacts.

## Where to look for the raw conversation

`story_claude/260521_115839_setup-commit-and-story-rules.md` — covers
this phase plus the CLAUDE.md workflow setup that followed.
