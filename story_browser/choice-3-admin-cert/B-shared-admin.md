# Browse — Choice 3, Option B: Shared admin client cert

## The case for it

One `.p12` (e.g. `admin.p12`), installed on every admin's browser.
nginx still does `ssl_verify_client on`, but all admins present the
same CA-signed identity.

The pitch: simpler distribution. One file, one password, one document.
You don't have to track who has which cert.

## Concrete setup

```bash
./gen-pki.sh client admin
```

Produces:

```
pki/client/admin.crt
pki/client/admin.key
pki/client/admin.p12
pki/client/admin.password
```

Distribute the same `admin.p12` + password to every admin. Optionally,
ship the .p12 in your internal documentation (encrypted, in a
password manager vault that all admins have access to).

## nginx config

No change from Option A. nginx still verifies any cert signed by the
CA, doesn't care that the CN is the same across all connections.

## Trade-offs that surface

- **No audit at the TLS layer.** `$ssl_client_s_dn_cn` is `"admin"`
  for every connection. Useless for "who did what." You're entirely
  reliant on JWT-layer logging.
- **Revocation is all-or-nothing.** Admin leaves? You re-issue the
  shared cert, distribute the new .p12 to remaining admins, all on
  the same day. Every admin has to re-import. Friction-heavy event.
- **Anyone with the .p12 is "an admin."** If the shared .p12 leaks
  (e.g. an admin emails it to themselves, then their personal email
  is breached), every admin is compromised at the TLS layer
  simultaneously. JWT still saves you, but the mTLS layer has
  effectively no value.
- **No "did Alice or Bob trigger this" reconstruction.** Important
  later if you're investigating an incident. nginx logs all look the
  same.
- **Distribution is simpler exactly once.** After that, every change
  is harder than Option A — adding an admin means giving them the
  shared bundle (no easier than issuing them their own); removing
  one means re-issuing for everyone.

## What "compromise" looks like

| Compromise | Recovery |
|---|---|
| `admin.p12` + password leaked | Re-issue, redistribute to all remaining admins, all re-import. Coordinated outage. |
| `ca.key` stolen | Full PKI rebuild — same as everywhere else. |
| Admin goes rogue | They have the bundle. Same path as "leaked" — re-issue. They can also extract the key + cert from their Windows store before being kicked. |

## Verdict

Hard to recommend.

It's only simpler at the moment of *first* distribution. Every
subsequent operation (admin add, admin leave, leak response, audit
investigation) is harder than Option A. And the savings at first
distribution are small — 3 .p12 files vs 1 .p12 file is not a real
difference at this scale.

Use it only if:
- You explicitly do not need TLS-layer audit (the JWT layer covers
  what you need).
- Your admin set is genuinely fluid and named per-admin certs would
  be churn.
- You accept that admin churn forces a coordinated re-import event.

For vLearn2 (3 admins, 1 churn/year), Option A is strictly better.
