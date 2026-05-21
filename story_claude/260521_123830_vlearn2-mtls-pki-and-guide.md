# Add mTLS support: gen-pki.sh + vlearn2-mtls-guide.md

## Task

User asked for mTLS on top of the existing vLearn2 HTTPS setup. Built a
CA-aware PKI generator and a guide describing the deltas vs. the plain
TLS setup. Also tested the script locally with both a positive and a
negative live handshake.

## Conversation

**User:**
> I want mTls

**Assistant:**
Two-part deliverable.

### Part 1 — `gen-pki.sh`

Subcommand-style script for OpenSSL 1.0.x:
- `ca` — one-time, refuses to overwrite an existing CA. RSA-2048,
  SHA-256, 10-year, `CA:TRUE`, `keyCertSign,cRLSign`.
- `server <hostname> [ip ...]` — leaf cert signed by the CA, SAN with
  DNS + IPs, EKU=`serverAuth`. 825-day.
- `client <name>` — leaf cert signed by the CA, EKU=`clientAuth`,
  plus a `.p12` bundle for browser/Windows-store import. PKCS#12 uses
  `PBE-SHA1-3DES` + SHA1 MAC explicitly so the bundle imports cleanly
  into Windows store, Firefox, Android KeyChain, and OpenSSL 1.0.x.
  (OpenSSL 3.x defaults to AES PBE which breaks importers on older
  platforms — flagging explicitly avoids a real-world foot-gun.)

Uses `openssl x509 -req -CA … -CAcreateserial` rather than
`openssl ca` to avoid needing an index/serial DB.

### Live test (Git Bash + OpenSSL 3.5.6, in `test-pki/`)

1. Built CA + server cert + 2 client certs (`flutter-app`,
   `admin-john`). All files materialise correctly. Server cert has
   correct SAN + EKU; client certs have EKU=clientAuth.
2. Started `openssl s_server -Verify 1 -CAfile ca.crt -cert server.crt
   -key server.key` on port 18444.
3. **Positive case:** `s_client` with `flutter-app` cert/key →
   `TLSv1.2 ECDHE-RSA-AES256-GCM-SHA384`, `Verify return code: 0 (ok)`.
4. **Negative case:** `s_client` without `--cert` → server sends
   `SSL alert number 40` (handshake_failure). Exactly the rejection
   behaviour mTLS is supposed to produce.

Killed the test server after.

### Part 2 — `vlearn2-mtls-guide.md`

10-section guide written as a delta to the basic HTTPS guide (not a
replacement). Sections:

1. **What changes vs. plain HTTPS** — table comparing both modes.
   Explicitly notes mTLS does not replace JWT login — it's a network
   filter, not user auth.
2. **PKI architecture** — ASCII diagram showing the single internal
   CA signing one server cert and N client certs.
3. **Build the PKI on the RHEL host** — `gen-pki.sh` invocations + the
   output tree + install paths (`/etc/pki/nginx/*`, mode 600/644).
   Includes the recommendation to move `ca.key` off-host after issuing.
4. **nginx — switch to mTLS** — three-line addition
   (`ssl_client_certificate`, `ssl_verify_client on`, `ssl_verify_depth`)
   plus `X-Client-CN` / `X-Client-Verify` upstream headers so NestJS
   can see the verified identity. Also documented `optional` mode +
   per-location gating for split public/private routes.
5. **Server-side verification** — `curl --cert/--key/--cacert` for
   the success path and bare `curl --cacert` to confirm rejection.
6. **Flutter** — bundle `ca.crt` + `flutter-app.crt` + `flutter-app.key`
   as assets, build `SecurityContext` with all three, wire into Dio's
   `IOHttpClientAdapter`. Called out the shared-key threat model
   explicitly (same key in every APK is fine for "network filter"
   purpose; JWT still distinguishes users).
7. **Browser admin** — `Import-PfxCertificate` + `Import-Certificate`
   PowerShell for Windows/Edge/Chrome; manual settings path for Firefox.
8. **End-to-end verification table** — expected outcome for each
   client posture. Plus an nginx `log_format` snippet to surface the
   client CN in access.log.
9. **Rotation & revocation** — leaf rotation (re-issue, reload/rebuild),
   compromised-client strategy (rebuild PKI is the honest pragmatic
   answer at this scale; CRL/OCSP intentionally not recommended),
   compromised-CA recovery.
10. **Troubleshooting** — 7 common symptoms covering both server
    side (nginx error log strings) and client side (Flutter
    HandshakeException, Chrome cert picker, .p12 import errors).

## Latest prompt

> I want mTls
