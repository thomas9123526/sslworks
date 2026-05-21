# Browse — Choice 1, Option A: Single CA (baseline)

## The case for it

One internal CA signs the server cert and every client cert. The same
`ca.crt` file serves as the trust root for everyone:

- nginx loads it as `ssl_client_certificate` to verify clients.
- Flutter bundles it as a trusted root to verify the server cert.
- Browser admins import it into the Windows trust store.

For a single-operator deployment, the operational cost of two CAs has
no payoff — you'd be backing up two keys, distributing two trust
roots, and rotating two PKIs to gain a separation that doesn't matter
because the same person owns both ends.

## Concrete setup

Already implemented in `gen-pki.sh`. Nothing to change.

```bash
ssh deploy@rhel7
./gen-pki.sh ca
./gen-pki.sh server vlearn2.example.com 172.86.121.43
./gen-pki.sh client flutter-app
./gen-pki.sh client admin-john
./gen-pki.sh client admin-mary
./gen-pki.sh client admin-bob
```

Resulting tree:

```
pki/
├── ca/
│   ├── ca.crt       # single file distributed everywhere
│   ├── ca.key       # single key to guard (offline if possible)
│   └── ca.srl
├── server/
│   └── vlearn2.example.com.{crt,key}
└── client/
    ├── flutter-app.{crt,key,p12,password}
    ├── admin-john.{crt,key,p12,password}
    ├── admin-mary.{crt,key,p12,password}
    └── admin-bob.{crt,key,p12,password}
```

## Distribution

| Artifact | Where it goes |
|---|---|
| `ca/ca.crt` | nginx (`ssl_client_certificate`), Flutter asset, admin browsers, internal docs |
| `ca/ca.key` | offline backup, ideally not on the host after issuing |
| `server/<host>.{crt,key}` | nginx (`ssl_certificate`, `ssl_certificate_key`) |
| `client/<name>.p12` + `.password` | per-admin via separate channels |
| `client/flutter-app.{crt,key}` + `ca.crt` | bundled into the Flutter build as assets |

## Trade-offs that surface

- **Single point of failure.** If `ca.key` leaks, attacker can mint
  both server certs (impersonate the API) and client certs
  (authenticate as anyone). Mitigation: move `ca.key` off the host
  once initial issuance is done. Re-mount only when issuing more.
- **No role separation.** Whoever runs `gen-pki.sh client X` could
  also run `gen-pki.sh server evil.example.com`. Not a real risk at
  vLearn2's scale; would be at any team boundary.
- **Coarse blast radius on rotation.** If you want to rotate the CA
  (e.g. annual hygiene), you re-issue *everything* — server cert and
  every client cert — in one go. The flip side: it's a single
  coordinated event, not two staggered ones.

## What "compromise" looks like

| Compromise | Recovery |
|---|---|
| One client `.p12` stolen | Don't re-issue that client. Optionally rebuild CA + everything. |
| `ca.key` stolen | Full PKI rebuild. New `ca.crt` to distribute to every client and the server. JWT auth still buys you time while the rebuild lands. |
| `ca.key` lost (not stolen) | Can't issue any more leaf certs. Existing leaves keep working until expiry. Plan a rebuild before the first one expires. |

## Verdict

Best fit for vLearn2:
- One ops person.
- 3 admins.
- One Flutter app.
- All trust roots converge on one human and one host.

Don't change this unless the team or the threat model changes.
