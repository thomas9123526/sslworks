# gen-pki.sh: random per-cert .p12 password by default

## Task

Replace the convenience default in `gen-pki.sh client` (password = cert
name) with a random 18-byte (base64) password, saved both to stdout
and to a sibling `<name>.password` file with mode 600. Update
`vlearn2-mtls-choice-4-pkcs12-pbe-strategy.md` to match.

Driven by the Choice #4 discussion: the real security knob for .p12
bundles is password discipline, not the PBE algorithm. Once
the password is strong, random, and travels on a separate channel,
sticking with the (universally importable) legacy PBE-SHA1-3DES has
no real downside.

## Conversation

Earlier this session the user picked A (legacy PBE) for Choice #4
explicitly because B (modern AES-256) silently breaks `openssl pkcs12
-in` round-trip inspection on OpenSSL 1.0.2k (RHEL7). I then offered
to tighten the default password handling. User: "ok".

## Changes

### `gen-pki.sh` (`client` subcommand)

Before:
```bash
openssl pkcs12 -export ... -passout "pass:${NAME}" \
  -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1
echo "  $P12   (password: ${NAME})"
```

After:
```bash
PWFILE="${CLIENT_DIR}/${NAME}.password"
PW=$(openssl rand -base64 18)
openssl pkcs12 -export ... -passout "pass:${PW}" \
  -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1
printf '%s\n' "$PW" > "$PWFILE"
chmod 600 "$KEY" "$P12" "$PWFILE"
echo "  $P12       password: ${PW}"
echo "  $PWFILE    (mode 600, holds the same password)"
echo
echo "Send the .p12 and the password on separate channels."
```

Header docstring updated to reflect the new behaviour.

### `vlearn2-mtls-choice-4-pkcs12-pbe-strategy.md`

Rewrote the "Password handling" section: the old text described the
old default (cert name as password) and showed how to upgrade. The new
text describes the new default (random, saved to .password) and shows
how to **override** if a fixed password is needed (e.g. scripted
deployment):

```bash
PW="${CLIENT_PASSWORD:-$(openssl rand -base64 18)}"
# usage: CLIENT_PASSWORD='hunter2' ./gen-pki.sh client admin-john
```

### Verified locally

In `test-pki-pwd/` (throwaway, deleted after):
- New `admin-john.password` file written with mode 600 (Unix; Windows
  Git Bash can only honour the user read/write bit).
- stdout now prints both file paths and the actual password.
- `openssl pkcs12 -in admin-john.p12 -passin file:admin-john.password`
  unlocks the bundle and shows `subject=CN=admin-john, O=vLearn2`
  with `issuer=CN=vLearn2 internal CA, O=vLearn2`. End-to-end ok.

### Not touched

- `test-pki/` from the earlier commit — pre-dates this change. Its
  `.p12` files use the old `password=name` convention. Left as a
  historical snapshot rather than regenerating (would churn cert keys
  unnecessarily). If you regenerate that folder, the new
  `.password` files will appear automatically.
- The other three choice guides (#1–#3) — unaffected.
- Pre-existing markdown-lint warnings (MD036 emphasis-as-heading
  on `**Pros**`/`**Cons**`, MD060 table-pipe spacing) — these apply
  uniformly across all four choice guides. Fixing in only choice #4
  would create stylistic inconsistency; intentionally out of scope.

## Latest prompt

> ok
