# Browse — Choice 4, Option C: Hybrid (emit both legacy and modern .p12)

## The case for it

You don't actually have to pick. `openssl pkcs12 -export` is fast and
deterministic given the same inputs. Run it twice — once with legacy
flags, once with modern — and ship the legacy file only when the
modern one fails to import on a given admin's machine.

You get:
- Modern PBE as the default delivery.
- Legacy PBE as a guaranteed fallback for older systems.
- One re-issue command, two files.

The cost is one extra file per cert in the `pki/client/` tree.

## Concrete setup

Edit the `client)` subcommand in `gen-pki.sh` to emit both:

```bash
# Modern .p12 — default delivery
openssl pkcs12 -export -out "$P12" \
  -inkey "$KEY" -in "$CRT" -certfile "$CA_CRT" \
  -name "${NAME}" -passout "pass:${PW}" \
  -keypbe AES-256-CBC -certpbe AES-256-CBC -macalg sha256

# Legacy .p12 — fallback for older importers
P12_LEGACY="${CLIENT_DIR}/${NAME}-legacy.p12"
openssl pkcs12 -export -out "$P12_LEGACY" \
  -inkey "$KEY" -in "$CRT" -certfile "$CA_CRT" \
  -name "${NAME}" -passout "pass:${PW}" \
  -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1

chmod 600 "$KEY" "$P12" "$P12_LEGACY" "$PWFILE"

echo "  $P12             modern PBE — try this first"
echo "  $P12_LEGACY      legacy PBE — fallback if modern fails to import"
echo "  $PWFILE          same password for both"
```

Both files use the same RSA key and the same password — only the
encryption wrapping differs. An admin who imports either ends up with
the same client identity in their cert store.

## Distribution workflow

For each admin:

1. Send the modern `<name>.p12` and the password (separate channels,
   as in Option A).
2. Admin tries to import.
3. If it succeeds: done.
4. If it fails (older Windows, old Firefox, unusual Android): send the
   `<name>-legacy.p12` over the same channel the modern one went on.
5. Admin imports the legacy version. Same cert, same password.

Most admins will only ever see step 1–3. The legacy file is insurance
that's almost never used.

## Trade-offs that surface

- **Two files per cert in `pki/client/`.** Visually busier directory
  listing. Mitigate with naming convention: `<name>.p12` is "modern
  default," `<name>-legacy.p12` is "fallback."
- **Forgetting to ship the legacy one when needed.** If you stop
  thinking about this and the admin only ever gets the modern file,
  you might burn a few minutes when an older system fails to import.
  Document the fallback procedure once.
- **OpenSSL 1.0.x can still inspect the legacy file** on the RHEL7
  host, but not the modern one. So `openssl pkcs12 -in <modern>.p12`
  on the host fails — debugging requires the legacy companion. Net
  positive vs pure Option B because the legacy version exists.
- **Re-issue produces both files** every time. If you're scripting
  rotation, both need to land where you expect.

## When the hybrid is right

- Your audience mostly uses modern systems but you have one or two
  outliers (older Windows, an Android tablet you can't update).
- You want "modern PBE looks good on a security review" without
  paying the "what if it doesn't import" risk.
- You don't mind one extra file per cert.

## What "compromise" looks like

| Compromise | Recovery |
|---|---|
| .p12 (either flavour) captured, password unknown | Brute force infeasible with strong password regardless of PBE. |
| .p12 (either flavour) + password captured | Re-issue. The fact that two bundles existed doesn't change the recovery. |
| The legacy .p12 leaks years later | Same as modern .p12 leaking — the cert it wraps is the issue, not the wrapping. Revoke the cert (re-issue CA or live with it until expiry). |

## Verdict

For vLearn2: same answer as pure A — not enough payoff for the extra
file. With 3 admins on modern Windows, the modern file alone would
work, and the legacy companion is mostly dead weight. Pure A is
simpler still (one file, universally accepted, no fallback ceremony).

The hybrid earns its keep when:
- Audience is mixed-modern (some Win10+, some Win7/8 or older
  Android) and you want a clean default-with-fallback story.
- You're producing certs for an external audience whose systems you
  don't control.

For an internal team of 3 you can quickly poll: pure A wins on
simplicity.
