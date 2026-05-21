# Choice 4 — `.p12` encryption: legacy (PBE-SHA1-3DES) vs. modern (AES-256)

What you're picking: which password-based encryption protects the
private key inside the `.p12` bundle that you hand to humans for
browser / OS-store import.

This affects only the **transit format**. The cert itself, the RSA key
inside it, and the trust model are identical between A and B.

The main [mTLS guide](vlearn2-mtls-guide.md) uses **A. Legacy** by
default for max import compatibility.

---

## A. Legacy: PBE-SHA1-3DES + SHA1 MAC (default)

What `gen-pki.sh client` currently emits:

```bash
openssl pkcs12 -export ... \
  -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1
```

**Pros — universal import**
- Windows Cert Store, all supported versions back to Windows 7
- macOS Keychain
- Firefox (NSS)
- Android KeyChain (every version)
- iOS Keychain
- OpenSSL 1.0.x, 1.1.x, 3.x

Same `.p12` file works for every admin regardless of OS version.

**Cons**
- 3DES + SHA-1 PBE is cryptographically weak by modern standards.
  Someone with the `.p12` file can brute-force a weak password and
  recover the private key.
- Mitigation: use strong, unique passwords (not the cert name as the
  script defaults to), and treat `.p12` transport as sensitive
  (encrypted channel — not email).

**Use when:** distribution audience includes any older OS or older
browser, or you can't enumerate everyone's environment.

---

## B. Modern: AES-256-CBC + SHA-256 MAC

Updated `gen-pki.sh client` section:

```bash
openssl pkcs12 -export ... \
  -keypbe AES-256-CBC -certpbe AES-256-CBC -macalg sha256
```

(On OpenSSL 3.x this is also the default — you can drop all three
flags entirely.)

**Pros**
- Strong key encryption. Brute-forcing the password is much more
  expensive.
- Modern primitives end-to-end.

**Cons — import compatibility is uneven**

| Importer | AES-256 PBE? |
|---|---|
| Windows 10 1809+ | ✅ |
| Windows 7 / 8 / Server 2012 | ❌ (needs KB updates) |
| macOS 10.13+ | ✅ |
| Firefox 78+ | ✅ |
| Firefox older | ❌ |
| Android 9+ | ✅ (mostly) |
| Android older | ❌ |
| iOS 12+ | ✅ |
| OpenSSL 1.1.1+ | ✅ |
| OpenSSL 1.1.0 | ⚠️ partial |
| OpenSSL 1.0.x | ❌ |

If the RHEL host is RHEL7 (OpenSSL 1.0.2k), `openssl pkcs12 -export`
still **writes** the file, but `openssl pkcs12 -in` can't **read** it
back on the same host. You lose round-trip inspection.

**Use when:** you control the audience (all admins on Windows 10+
modern browsers), and `.p12` password strength is a real concern.

### How to switch from A to B

Edit `gen-pki.sh`, find the `openssl pkcs12 -export` call inside the
`client)` subcommand, replace the three options:

```bash
# Before (legacy)
-keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1

# After (modern)
-keypbe AES-256-CBC -certpbe AES-256-CBC -macalg sha256
```

Or, if running on OpenSSL 3.x and you accept its defaults, just remove
all three flags.

Re-issue every client cert with the new format. Old `.p12` files keep
working until their holders re-import.

---

## C. Hybrid — ship modern, keep legacy as fallback

Emit both formats from the `client)` subcommand:

```bash
openssl pkcs12 -export -out "$P12" \
  -inkey "$KEY" -in "$CRT" -certfile "$CA_CRT" \
  -name "${NAME}" -passout "pass:${NAME}" \
  -keypbe AES-256-CBC -certpbe AES-256-CBC -macalg sha256

openssl pkcs12 -export -out "${P12%.p12}-legacy.p12" \
  -inkey "$KEY" -in "$CRT" -certfile "$CA_CRT" \
  -name "${NAME}" -passout "pass:${NAME}" \
  -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1
```

Give people the legacy file only if the modern one fails to import on
their system.

---

## Password handling (independent of PBE choice)

`gen-pki.sh client <name>` now generates a random 18-byte (base64)
password per cert and writes it to two places:

- stdout (visible immediately after issuing)
- `pki/client/<name>.password` (mode 600, in case stdout scrolls)

Workflow for handing a cert to an admin:

1. `./gen-pki.sh client admin-john`
2. Send `admin-john.p12` over one channel (email, shared drive — the
   bundle is encrypted, so the channel doesn't need to be).
3. Send the password from `admin-john.password` over a **different**
   channel (Signal, password manager share, in person).
4. Delete `admin-john.password` from the host once the admin confirms
   import.

Storing the password in 1Password / Vaultwarden scoped to the issuing
admin is the practical long-term pattern.

The strength of the PBE matters most when the `.p12` and the password
travel on the same channel or end up archived together. If you keep
them strictly separated, A vs. B is a much smaller difference.

### Override the random default

If you need a fixed password (e.g. scripted deployment, automated
re-import), edit the `client)` subcommand and replace the
`PW=$(openssl rand …)` line with a literal:

```bash
PW="${CLIENT_PASSWORD:-$(openssl rand -base64 18)}"
```

Then: `CLIENT_PASSWORD='hunter2' ./gen-pki.sh client admin-john`.
