# Browse — Choice 3, Option A: Per-admin client cert (baseline)

## The case for it

One `.p12` per human admin. CN = the admin's identifier
(`admin-john`, `admin-mary`, `admin-bob`). nginx `ssl_verify_client
on` requires every TLS connection to `/vAdmin/` to present a CA-signed
cert.

For 3 admins with annual turnover, distribution is trivial and you get
two real benefits at near-zero cost:
1. **TLS-layer audit.** nginx logs show `$ssl_client_s_dn_cn` so you
   can see who connected from which IP at what time.
2. **Individual revocation.** Whoever leaves: stop re-issuing their
   cert at renewal. Their existing one stays valid until expiry, but
   you can mint a fresh CA if you want immediate cutoff.

## Concrete setup

```bash
./gen-pki.sh client admin-john
./gen-pki.sh client admin-mary
./gen-pki.sh client admin-bob
```

Each produces four files:

```
pki/client/admin-john.crt
pki/client/admin-john.key
pki/client/admin-john.p12         # this is what the admin imports
pki/client/admin-john.password    # random 18-byte base64; mode 600
```

## Distribution per admin

For each admin (e.g. John):

1. Send `admin-john.p12` over one channel — email is fine; the
   bundle is password-protected.
2. Send the contents of `admin-john.password` over a **different**
   channel — Signal, in-person, password-manager share.
3. John imports on his Windows box:
   ```powershell
   Import-PfxCertificate -FilePath .\admin-john.p12 `
       -CertStoreLocation Cert:\CurrentUser\My `
       -Password (Read-Host -AsSecureString)
   Import-Certificate -FilePath .\ca.crt `
       -CertStoreLocation Cert:\CurrentUser\Root
   ```
4. Browser prompts "Select a certificate" on first visit to
   `https://vlearn2.example.com/vAdmin/`. John picks his cert. Done.
5. Delete `admin-john.password` from the host after John confirms
   import.

## nginx config

Already in the main mTLS guide:

```nginx
    ssl_client_certificate /etc/pki/nginx/ca.crt;
    ssl_verify_client      on;
    ssl_verify_depth       2;
```

Optional — surface the verified CN in access logs:

```nginx
log_format mtls '$remote_addr - $ssl_client_s_dn_cn [$time_local] '
                '"$request" $status $body_bytes_sent';
access_log /var/log/nginx/access.log mtls;
```

Sample line:

```
10.0.0.42 - admin-john [21/May/2026:14:03:11 +0000] "GET /vAdmin/users HTTP/2" 200 5410
```

## Trade-offs that surface

- **Onboarding ritual.** Each new admin needs cert issuance + .p12
  delivery + password delivery + browser import + first-visit cert
  pick. ~15 minutes including the awkward "where do I import this"
  walkthrough. Once.
- **Two-channel password rule.** Admins who paste both cert + password
  into the same Slack DM defeat the point. Document it; check it.
- **Re-import after machine reset.** When an admin gets a new laptop,
  reinstall the cert. Keep the .p12 they originally received (in
  their password manager) so reinstall doesn't require a re-issue.
- **Expiry handling.** 825-day certs need re-issue ~28 months out.
  Calendar event the day you issue.

## When an admin leaves

Simplest: don't re-issue at next renewal. Their existing cert keeps
working until expiry (potentially years). Acceptable if:
- The admin left amicably and you don't need immediate cutoff.
- JWT auth still requires login; without their JWT credentials, the
  cert alone is useless.

Faster cutoff: rebuild the CA + re-issue every cert for the remaining
admins. Brutal but consistent. Worth it for involuntary departures.

## What "compromise" looks like

| Compromise | Recovery |
|---|---|
| One admin's `.p12` stolen, password unknown | Brute-force on the .p12 is slow with random 18-byte password — practically infeasible without targeted compute. Re-issue at next renewal. |
| One admin's `.p12` + password stolen | Re-issue that admin's cert immediately. Their old cert still validates at nginx — accept the window, or rebuild CA. |
| `ca.key` stolen | Full PKI rebuild — all admins re-import. Same as Choice 1A. |

## Verdict

Right call for vLearn2:
- 3 admins → 3 .p12 files to distribute. Trivial.
- 1 turnover/year → 1 re-issue per year.
- Audit logging at the nginx layer is genuinely useful even just for
  "who triggered this admin action."

The "right call" stops being right around 15+ admins or when admins
rotate quarterly. At that point Option C (no mTLS on /vAdmin/) starts
to look attractive.
