# Add four "design choice" guides for vLearn2 mTLS decisions

## Task

After the main mTLS guide called out 4 design decisions that were "made
for you," user asked for a guide per choice covering the alternative.
Wrote four standalone files, each comparing the default (used in the
main guide) against the alternative(s), with switch instructions and
"when to pick which" guidance.

## Conversation

**User:**
> I want you make all 4 choice guides for me.

**Assistant:**
Wrote four short files (≈150 lines each), one per design decision.
Each follows the same shape: pros/cons of A (the default), pros/cons of
B (the alternative), occasionally C (a hybrid or third path), how to
switch, and a "when to pick" line.

### Files

1. **`vlearn2-mtls-choice-1-ca-strategy.md`** — single CA vs split
   server/client CAs.
   - A (default): one CA signs server + clients; one `ca.crt` to
     distribute everywhere.
   - B: two CAs (`server-ca`, `client-ca`); nginx
     `ssl_client_certificate` points at the client CA; clients only
     ever see the server CA. Switch by running `gen-pki.sh` in two
     directories.

2. **`vlearn2-mtls-choice-2-flutter-cert-strategy.md`** — shared
   Flutter cert vs per-device enrollment.
   - A (default): one cert bundled in every APK. mTLS as network
     filter, JWT for identity.
   - B: per-device enrollment endpoint in NestJS, Flutter generates
     CSR on first launch, server signs against client CA, device
     stores via `flutter_secure_storage`. Sketched both server and
     Flutter sides + library stack (pointycastle, basic_utils).
   - C: hybrid — bootstrap cert in APK with scoped access to
     `/enroll/` only, then enroll a broader-access per-device cert.

3. **`vlearn2-mtls-choice-3-admin-cert-strategy.md`** — per-admin /
   shared / no admin cert.
   - A (default): one .p12 per human, CN=admin-name, audit-friendly.
   - B: shared admin.p12, simpler distribution, no audit at TLS layer.
   - C: skip mTLS on `/vAdmin/` entirely; only protect `/vfls/`.
     Admin server still talks to the API with its own client cert via
     `BACKEND_BASE_URL`. Includes Node.js undici Agent snippet.
   - Picking table at the end (admin team size → option).

4. **`vlearn2-mtls-choice-4-pkcs12-pbe-strategy.md`** — legacy vs
   modern .p12 PBE.
   - A (default): PBE-SHA1-3DES + SHA1 MAC. Universal import (Win7+,
     Firefox/NSS, Android KeyChain, OpenSSL 1.0+).
   - B: AES-256-CBC + SHA256 MAC. Stronger but breaks on Win7/8, older
     Android, OpenSSL 1.0.x. Compat matrix table included.
   - C: hybrid — emit both formats; hand over legacy only on failure.
   - Final section on password handling (independent of PBE choice):
     don't ship cert+password on the same channel; default `-passout
     pass:$NAME` is for iteration, not production.

### Why this shape

Each guide is self-contained — a reader can pick one design dimension
to revisit without re-reading the main guide. All four cross-link back
to `vlearn2-mtls-guide.md` so the defaults stay traceable.

Did not modify `gen-pki.sh` or the main mTLS guide — those still
implement defaults A across all four dimensions. The choice guides
document the path to switch.

## Latest prompt

> I want you make all 4 choice guides for me.
