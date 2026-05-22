# Turn 03 — run winget install mkcert

**User prompt:**
> yes

**Assistant response:**
Ran `winget install --id FiloSottile.mkcert`. The first attempt failed
with `0x8a15005e` — "The server certificate did not match any of the
expected values" — from the `msstore` source. Re-ran pinned to the
winget source:

```
winget install --id FiloSottile.mkcert --source winget --accept-source-agreements --accept-package-agreements
```

Succeeded — mkcert v1.4.4 downloaded from the GitHub release, hash
verified, command alias added. Refreshed PATH in-session and confirmed
`mkcert -version` → `v1.4.4`.

## Latest prompt

> yes
