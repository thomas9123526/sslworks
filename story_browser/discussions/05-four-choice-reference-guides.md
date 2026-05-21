# Discussion 05 — Four choice reference guides

**Span:** "I want you make all 4 choice guides for me" through commit
of `vlearn2-mtls-choice-1..4-*.md`.

## Goal

The end of phase 04 listed four design choices made by default in
`gen-pki.sh` + the main mTLS guide. User wanted each of those choices
written up as its own reference document so they could see the
alternatives and switch with informed consent.

## What we built

Four standalone `.md` files at project root. Each compares the default
(used in the main guide) against the alternative(s) with switch
instructions:

### `vlearn2-mtls-choice-1-ca-strategy.md`
- A (default): single CA signs server + clients; one `ca.crt` to
  distribute everywhere.
- B: two CAs (`server-ca`, `client-ca`); nginx
  `ssl_client_certificate` points at the client CA; clients only
  see the server CA. Switch by running `gen-pki.sh` in two
  directories.

### `vlearn2-mtls-choice-2-flutter-cert-strategy.md`
- A (default): one cert bundled in every APK. mTLS as network filter,
  JWT for identity.
- B: per-device enrollment endpoint in NestJS; Flutter generates CSR
  on first launch; server signs against client CA; device stores via
  `flutter_secure_storage`. Sketched both server and Flutter sides +
  library stack (pointycastle, basic_utils).
- C: hybrid — bootstrap cert in APK with scoped access to `/enroll/`
  only, then enroll a broader-access per-device cert.

### `vlearn2-mtls-choice-3-admin-cert-strategy.md`
- A (default): one .p12 per human, CN=admin-name, audit-friendly.
- B: shared admin.p12 — simpler distribution, no audit at TLS layer.
- C: skip mTLS on `/vAdmin/` entirely; only protect `/vfls/`. Admin
  server still talks to the API with its own client cert via
  `BACKEND_BASE_URL`. Includes Node.js undici Agent snippet.
- Picking table at the end (admin team size → option).

### `vlearn2-mtls-choice-4-pkcs12-pbe-strategy.md`
- A (default): PBE-SHA1-3DES + SHA1 MAC. Universal import.
- B: AES-256-CBC + SHA256 MAC. Stronger but breaks on Win7/8, older
  Android, OpenSSL 1.0.x. Compat matrix table.
- C: hybrid — emit both formats.
- Final section on password handling (independent of PBE choice).

## Shape consistency

Every guide follows the same template so a reader can scan-compare:
- A overview + pros/cons
- B (and C) overview + pros/cons
- How to switch (concrete edit)
- When to pick what (verdict)

All four cross-link back to `vlearn2-mtls-guide.md` so the defaults
stay traceable.

## Decisions made

- Each choice gets its own file (vs one big "all choices" document).
  Rationale: easier to revisit a single dimension without re-reading
  the whole thing.
- Defaults in `gen-pki.sh` and the main guide are **unchanged** in
  this phase — the guides document the switch path.

## Artifacts

- `vlearn2-mtls-choice-1-ca-strategy.md`
- `vlearn2-mtls-choice-2-flutter-cert-strategy.md`
- `vlearn2-mtls-choice-3-admin-cert-strategy.md`
- `vlearn2-mtls-choice-4-pkcs12-pbe-strategy.md`

## Where to look for the raw conversation

`story_claude/260521_124627_mtls-four-design-choice-guides.md`.
