# Pivot to RHEL7 / OpenSSL 1.0 self-signed cert script

## Task

Replace the local mkcert workflow (targeted `localhost`) with a
cert-generation script that runs on RHEL7 using its native OpenSSL 1.0.x.
Output a key+cert pair whose algorithms and extensions are guaranteed to
work on OpenSSL 1.0.

## Conversation

**User:**
> btw, let's restart again. Because I have to implement https on RHEL7 and
> i can use only openssl 1.0 version.
> So all certificate should work well with openssl 1.0 version.

**Assistant:**
Clarified that the existing mkcert certs (RSA-3072, SHA-256) are
technically already OpenSSL-1.0 compatible — the real OpenSSL-1.0 gotcha
is on the **generation** side: `openssl req -addext` was added in 1.1.1,
so SAN must go through a config file on 1.0.x.

Created `gen-cert.sh` at the project root: a self-contained, parameterised
shell script that runs on RHEL7.

Design choices and why each is OpenSSL-1.0-safe:

- **RSA-2048 + SHA-256** — universally supported by 1.0.x. Ed25519 would
  need 1.1.1+; ECDSA P-256 works on 1.0 but RSA is safer for older
  client interop.
- **SAN via `.cnf` file, not `-addext`** — `-addext` is 1.1.1+ only.
- **`x509_extensions = v3_req`** — without this, `openssl req -x509`
  on 1.0.x would leave the SAN inside the CSR but never copy it to the
  signed cert. Common foot-gun.
- **825-day validity** — Apple/Safari rejects new certs longer than this.
- **Single-shot `req -x509`** — no separate CSR/CA dance, since the user
  asked for a simple HTTPS setup, not a CA hierarchy.

Script usage:
```
./gen-cert.sh <hostname-or-domain> [ip ...]
```
e.g. `./gen-cert.sh app.internal.example.com 10.0.0.42`.

Left in place (not cleaned up — flagged to user):
- `certs/` folder with the earlier mkcert output (localhost cert + key).
- mkcert binary and its CA in the Windows trust store.

These are now orphaned by the pivot but cleanup is destructive, so left
for the user to decide.

## Latest prompt

> btw, let's restart again. Because I have to implement https on RHEL7 and
> i can use only openssl 1.0 version.
> So all certificate should work well with openssl 1.0 version.
