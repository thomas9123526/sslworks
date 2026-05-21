# Browse — Choice 4, Option A: Legacy PBE-SHA1-3DES (baseline)

## The case for it

`gen-pki.sh client` emits `.p12` bundles using the old PBE family:

```bash
openssl pkcs12 -export ... \
  -keypbe PBE-SHA1-3DES \
  -certpbe PBE-SHA1-3DES \
  -macalg sha1
```

The cryptographic primitives are old (3DES + SHA-1), but they're
universal. Every PKCS#12 importer ever built understands them:

- Windows Cert Store, all supported versions back to Windows 7.
- macOS Keychain.
- Firefox (NSS).
- Android KeyChain — every Android version.
- iOS Keychain.
- OpenSSL 1.0.x, 1.1.x, 3.x.

You can hand a .p12 to anyone, on any OS, and it just imports.

## Why this isn't a security problem in practice

The .p12 password is *not* the trust anchor. The cert itself is.

If an attacker captures a .p12 in transit, what they need is the
password. The password protects against:

1. Casual eavesdropping (someone with a copy of the file but no
   password).
2. Bulk leak (e.g. backup tape) where the password is held separately.

If the password is random and not stored alongside the .p12, brute
force is the only attack. PBE-SHA1-3DES with 2048 iterations is
weak against modern hardware *for short passwords*. With an 18-byte
base64 password (≈ 108 bits of entropy), brute force is infeasible
even on big GPU rigs.

So: PBE strength matters for short passwords. We don't have short
passwords. The legacy PBE is fine.

## Concrete setup

Nothing to do — this is what `gen-pki.sh client` does today.

Quick verification on any platform:

```bash
# Inspect the .p12 without unpacking
openssl pkcs12 -in admin-john.p12 -passin file:admin-john.password \
  -info -nokeys -nodes 2>&1 | head -10
```

You'll see something like:

```
MAC: sha1, Iteration 2048
MAC length: 20, salt length: 8
PKCS7 Encrypted data: pbeWithSHA1And3-KeyTripleDES-CBC, Iteration 2048
Certificate bag
PKCS7 Encrypted data: pbeWithSHA1And3-KeyTripleDES-CBC, Iteration 2048
Bag Attributes
    friendlyName: admin-john
```

Both lines confirm legacy PBE; `Iteration 2048` is the default.

## Trade-offs that surface

- **Looks bad on a security audit checklist.** "Why are you using
  SHA-1 PBE?" is a fair question that needs an answer (universal
  import, strong password compensates). Have the answer ready.
- **Doesn't future-proof.** If someone five years from now decides
  to upgrade Windows policy to reject 3DES PBE for .p12 imports (it
  could happen), every admin has to re-import a re-issued bundle.
- **Inspectable on RHEL7.** `openssl pkcs12 -in` round-trip works on
  OpenSSL 1.0.2k. Option B silently breaks this.

## When this becomes wrong

- Your password policy degrades to short / dictionary-derived
  passwords (e.g. someone hard-codes `-passout pass:hunter2`). Then
  PBE strength matters and you should switch to B.
- Compliance regime explicitly bans SHA-1 in any context — some
  FIPS-mode deployments do this.
- You're shipping .p12 files to clients that explicitly reject
  legacy PBE (rare; would be Windows 12+ with a hypothetical
  hardening policy).

## What "compromise" looks like

| Compromise | Recovery |
|---|---|
| .p12 captured in transit, password unknown | Brute force is infeasible with random 18-byte base64. Re-issue at next renewal as hygiene. |
| .p12 + password captured | Re-issue immediately. PBE choice irrelevant — the password is the lock. |
| Old leaked .p12 from past employee, password long since rotated in 1Password | If the .p12's cert is still in nginx's trust path, attacker can use it. Re-issue the CA to invalidate all old leafs, or accept the window until natural expiry. |

## Verdict

For vLearn2 (3 admins, random per-cert passwords sent on separate
channels, OpenSSL 1.0.2k on the host) this is straightforwardly
correct. Universal import, no real security loss given the password
discipline.

Stop worrying about the "1990s PBE" optics and document the threat
model: cert is the trust anchor, password protects in-transit
discovery, PBE is the wrapping. Audit-friendly write-up of these
three sentences kills the SHA-1 question on every review.
