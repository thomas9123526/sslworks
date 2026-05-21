# Browse — Choice 4, Option B: Modern AES-256 PBE

## The case for it

Swap the legacy PBE flags for modern AES-based ones:

```bash
openssl pkcs12 -export ... \
  -keypbe AES-256-CBC \
  -certpbe AES-256-CBC \
  -macalg sha256
```

Same cert inside the bundle. Same RSA key. The change is purely in
the password-based encryption wrapping the key for transit.

The upgrade buys:

- Modern primitives end-to-end. SHA-256 MAC + AES-256-CBC PBE pass
  any reasonable cryptographic-hygiene checklist.
- Higher cost-per-attempt for password brute force — meaningful if
  password discipline is weak.
- Aligns with the OpenSSL 3.x default, so generating without
  explicit flags on a 3.x host gives you this.

## Concrete setup

Edit the `client)` subcommand in `gen-pki.sh`:

```bash
# Before
openssl pkcs12 -export -out "$P12" \
  -inkey "$KEY" -in "$CRT" -certfile "$CA_CRT" \
  -name "${NAME}" -passout "pass:${PW}" \
  -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1

# After
openssl pkcs12 -export -out "$P12" \
  -inkey "$KEY" -in "$CRT" -certfile "$CA_CRT" \
  -name "${NAME}" -passout "pass:${PW}" \
  -keypbe AES-256-CBC -certpbe AES-256-CBC -macalg sha256
```

Or, if running on OpenSSL 3.x and you accept defaults, just drop all
three `-keypbe / -certpbe / -macalg` flags.

Re-issue each existing client cert. Old .p12 files keep working until
their holders re-import.

## Trade-offs that surface

**Import compatibility is uneven.** Below is what actually works in
practice today:

| Importer | AES-256 PBE? |
|---|---|
| Windows 10 1809+ | ✅ |
| Windows 7 / 8 / Server 2012 | ❌ (KB updates required, often unavailable) |
| macOS 10.13+ | ✅ |
| Firefox 78+ | ✅ |
| Older Firefox | ❌ |
| Android 9+ | ✅ mostly (depends on KeyChain provider version) |
| Older Android | ❌ |
| iOS 12+ | ✅ |
| OpenSSL 1.1.1+ | ✅ |
| OpenSSL 1.1.0 | ⚠️ partial — reads if compiled with the right options |
| OpenSSL 1.0.x | ❌ — cannot read AES-256-CBC PBE |

**Concrete consequences for vLearn2:**

- The RHEL7 host runs OpenSSL 1.0.2k. The host **can write** the .p12
  using `-keypbe AES-256-CBC` (because OpenSSL 1.0 knows the AES name
  even if it doesn't know how to *read* it in PKCS#12 context).
  Actually no — older OpenSSL 1.0 versions reject the flag with
  "unknown algorithm." Test before committing to this. RHEL7's
  shipped 1.0.2k may or may not accept it.
- Once generated, `openssl pkcs12 -in <file>.p12` on the RHEL7 host
  fails. You lose round-trip inspection on the server.
- Admins on Windows 10+ and modern browsers import fine. Older
  Windows / older Android — you'll learn about the failure when they
  call you.

## When it's actually right

- Your audience is all on modern systems and you can guarantee it
  (e.g. company laptops on Windows 11, no BYOD).
- Your password policy can't be made strong enough (e.g. you have to
  accept human-chosen passwords).
- You have a compliance regime that explicitly demands AES-only
  PBE in transit (rare; usually compliance is satisfied by
  password-strength documentation).

## What "compromise" looks like

| Compromise | Recovery |
|---|---|
| .p12 captured, password unknown | Brute force is harder than under Option A (modern AES PBE) — but with the same random 18-byte password from `gen-pki.sh`, both options are already infeasible to brute. The win is theoretical. |
| .p12 + password captured | Re-issue. PBE choice irrelevant. |
| Issued .p12 fails to import on admin's machine | Admin can't access /vAdmin. Generate a legacy fallback or upgrade their OS. |

## Verdict

For vLearn2 specifically: the cost of "test on every admin's machine
to make sure the .p12 still imports" outweighs the benefit ("modern
PBE looks better on paper, slightly stronger against weak-password
brute force"). And you lose round-trip inspection on the server.

Pick this only if you've explicitly verified every importer in your
audience accepts it, *and* you have a real reason to upgrade (audit
checkbox, compliance constraint, or you've decided to allow weak
passwords).

Otherwise: stick with A. Or use the hybrid in `C-hybrid-emit-both.md`
if you want modern as the default but a legacy fallback ready.
