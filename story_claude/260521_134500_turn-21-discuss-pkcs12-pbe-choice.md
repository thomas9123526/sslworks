# Turn 21 — discuss PKCS#12 PBE (choice #4)

**User prompt:**
> ok

**Assistant response:**
Moved to Choice #4 (`.p12` encryption). Recommended **A. Legacy
PBE-SHA1-3DES** — the audience is 3 admins on modern Windows so modern
AES PBE (B) would import fine, but A has no downside given proper
password handling, and B silently breaks `openssl pkcs12 -in`
round-trip inspection on the RHEL7 host (OpenSSL 1.0.2k can't read AES
PBE). Pointed out the real security knob is password discipline, not
the PBE algorithm — offered to update `gen-pki.sh` to default to a
random 18-byte password instead of the cert name.

## Latest prompt

> ok
