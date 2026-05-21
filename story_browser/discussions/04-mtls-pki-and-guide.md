# Discussion 04 — mTLS: PKI generator + delta guide

**Span:** "I want mTls" through commit of `gen-pki.sh` +
`vlearn2-mtls-guide.md` + `test-pki/`.

## Goal

Layer mutual TLS on top of the existing HTTPS setup. The server
rejects the TLS handshake itself if the client doesn't present a
CA-signed cert.

## What changed conceptually vs. plain HTTPS

| Layer | TLS only | mTLS |
|---|---|---|
| Server cert | self-signed by `gen-cert.sh` | issued by an **internal CA** from `gen-pki.sh` |
| Client cert | none | one per identity (Flutter + each admin) |
| Trust root | server cert itself | the internal CA |
| nginx | `ssl_certificate` + `ssl_certificate_key` | + `ssl_client_certificate` + `ssl_verify_client on` |
| Flutter | Dio sees server's cert | Dio also **presents** its own cert |
| Browser admin | no client cert needed | user imports `.p12` into Windows / Firefox |
| Failure mode | bad-cert dialog (TLS still completes) | TCP closes during handshake |

## What we built

### `gen-pki.sh`

Subcommand-style PKI generator for OpenSSL 1.0.x:

```bash
./gen-pki.sh ca                                  # one-time, refuses overwrite
./gen-pki.sh server <hostname> [ip ...]          # leaf, EKU=serverAuth
./gen-pki.sh client <name>                       # leaf, EKU=clientAuth, + .p12
```

Design notes baked into the script:

- RSA-2048 + SHA-256 throughout — universal on OpenSSL 1.0.
- Uses `openssl x509 -req -CA … -CAcreateserial` rather than
  `openssl ca`, so no `index.txt` / serial DB to maintain.
- `.p12` bundle uses **PBE-SHA1-3DES + SHA1 MAC** explicitly so it
  imports cleanly into Windows store / Firefox / Android KeyChain /
  OpenSSL 1.0.x. (OpenSSL 3.x default is AES PBE which breaks older
  importers — caught as a real foot-gun.)

### `vlearn2-mtls-guide.md`

Written as a **delta on top of** the basic HTTPS guide (not a
replacement). 10 sections:

1. What changes vs. plain HTTPS (table).
2. PKI architecture (ASCII diagram — one CA, three leaf types).
3. Build the PKI on RHEL7 + install paths.
4. nginx — three-line mTLS addition + `X-Client-CN` upstream header.
   Also documented `ssl_verify_client optional` + per-location
   gating.
5. Server-side verification.
6. Flutter — `SecurityContext` with bundled CA + client cert + key.
7. Browser admin — `Import-PfxCertificate` PowerShell + Firefox path.
8. End-to-end verification table.
9. Rotation & revocation.
10. Troubleshooting (7 common symptoms).

## Live verification

Built a full PKI in `test-pki/`:
- `pki/ca/ca.{crt,key}` — vLearn2 internal CA.
- `pki/server/vlearn2.example.com.{crt,key}` — server cert, SAN
  with hostname + IP.
- `pki/client/flutter-app.{crt,key,p12}` + `admin-john.{crt,key,p12}`.

Then a real handshake test:

| Test | Result |
|---|---|
| `openssl s_server -Verify 1` + `s_client --cert flutter-app...` | ✅ TLSv1.2, `ECDHE-RSA-AES256-GCM-SHA384`, `Verify return code: 0 (ok)` |
| `s_client` without `--cert` | ✅ server rejects with `SSL alert number 40` (handshake_failure) |

Both behaviours match expectations: mTLS lets in CA-signed clients,
drops everyone else at the handshake.

## Decisions made

- **Single CA** signs both server and client certs (simplest for
  vLearn2's single-operator scale; one `ca.crt` to ship everywhere).
- **Shared `flutter-app` cert** for every device (mTLS as network
  filter, JWT still handles user identity).
- **Per-admin client cert** for browsers (one `.p12` per human,
  password = cert name as default).
- **Legacy PBE-SHA1-3DES** for `.p12` bundles (universal import).

These four became the "Key design choices made for you" list at the
end of this phase's wrap-up — which directly seeded the next four
phases (the choice guides and the conversational walk-through).

## Artifacts

- `gen-pki.sh` (project root).
- `vlearn2-mtls-guide.md` (project root).
- `test-pki/` (CA + server cert + 2 client certs).

## Where to look for the raw conversation

`story_claude/260521_123830_vlearn2-mtls-pki-and-guide.md`.
