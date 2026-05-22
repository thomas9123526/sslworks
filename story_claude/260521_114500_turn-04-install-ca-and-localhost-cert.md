# Turn 04 — install CA and localhost cert

**User prompt:**
> go on automatically until required things installed

**Assistant response:**
Listed the project (only a `prompts/` folder of numbered notes at that
point — no app to infer a domain from). Proceeded with the standard
mkcert setup:

- `mkcert -install` — created a new local CA and installed it into the
  Windows system trust store.
- `mkcert localhost 127.0.0.1 ::1` — generated a dev cert into a new
  `certs/` folder: `localhost+2.pem` + `localhost+2-key.pem`, valid
  until 2028-08-21.

Reported the files and next steps for wiring the cert into a dev
server.

## Latest prompt

> go on automatically until required things installed
