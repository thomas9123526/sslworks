# Discussion 02 — Pivot to RHEL7 / OpenSSL 1.0 cert script

**Span:** "let's restart again..." through committing the OpenSSL-1.0
test certs.

## Goal

The user's real target was a RHEL7 HTTPS server constrained to
OpenSSL 1.0. mkcert's localhost cert was for dev only; needed a
strategy that produced certs compatible with OpenSSL 1.0.x on
RHEL7's nginx.

## Key insight

> "the existing mkcert certs (RSA-3072, SHA-256) are technically
> already OpenSSL-1.0 compatible — the real OpenSSL-1.0 gotcha is on
> the **generation** side"

Specifically: `openssl req -addext` (the convenient flag for adding
SAN inline) was added in OpenSSL 1.1.1. On 1.0.x, SAN has to go
through a config file with `[v3_req] subjectAltName = @alt_names`,
and `openssl req -x509` needs `x509_extensions = v3_req` or the SAN
stays in the CSR but never makes it into the signed cert.

## What we built

`gen-cert.sh` at the project root — a self-contained shell script
that runs on RHEL7. Takes a hostname plus optional IPs, produces
RSA-2048 + SHA-256 + SAN cert with explicit OpenSSL-1.0-safe
options. Validity 825 days (Apple/Safari ceiling).

Usage:
```bash
./gen-cert.sh app.internal.example.com 10.0.0.42
```

## Local testing on Windows

Found Git for Windows ships `openssl 3.5.6` at
`C:\Program Files\Git\usr\bin\openssl.exe` and a bash shell. The
script's compatibility surface is OpenSSL-1.0-safe, so running it on
newer OpenSSL is a valid local test — what works here works on
RHEL7/8.

Ran the full verification chain in `test-certs/`:
1. Generated cert+key for `localhost 127.0.0.1 ::1`.
2. `openssl x509 -modulus | md5` matched `openssl rsa -modulus | md5`
   → cert and key are a valid pair.
3. Extensions: SAN, EKU=serverAuth, KU=digitalSignature+keyEncipherment,
   CA:FALSE — all present.
4. Live TLS handshake via `openssl s_server` (port 18443) +
   `openssl s_client -tls1_2`: cipher
   `ECDHE-RSA-AES256-GCM-SHA384`, `Verify return code: 0 (ok)`. This
   was the important one — TLS 1.2 is the relevant test because
   RHEL7's OpenSSL 1.0.2 can't speak 1.3.
5. TLS 1.3 also worked on Windows OpenSSL 3.5 (confirmed nothing in
   the cert blocks newer protocols).

## Commit / no-commit decision

Initial position: don't commit `test-certs/` because it contains a
private key.

User overrode:
> "no I want commit this also with all cert files. because this is for
> test mode and i will change cert in the future on a real RHEL7"

Reversed: staged everything, including `certs/` (mkcert) and
`test-certs/` (openssl). The threat model the user articulated:
production RHEL7 will use freshly-generated certs; these are test
artifacts only.

## Decisions made

- Cert generation happens **on RHEL7** with its native `openssl 1.0.x`
  (avoids version drift, key never leaves the host) — but tested
  locally first on Windows Git Bash + OpenSSL 3.5.
- `gen-cert.sh` lives at project root, parameterised by hostname.
- Test artifacts (private keys included) get committed — user opted in
  explicitly for the test-mode workflow.

## Artifacts

- `gen-cert.sh` (project root).
- `test-certs/localhost.crt` + `.key`.
- `certs/localhost+2.crt` + `-key.pem` (from phase 01).

## Where to look for the raw conversation

- `story_claude/260521_120632_rhel7-openssl1-cert-script.md`
- `story_claude/260521_121458_local-test-and-commit-test-certs.md`
