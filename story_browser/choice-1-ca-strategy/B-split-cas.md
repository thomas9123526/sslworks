# Browse — Choice 1, Option B: Split server/client CAs

## The case for it

Two distinct CAs, each owning one half of the mTLS trust relationship:

- **Server CA** — signs the server cert. Its `ca.crt` is shipped to
  clients (Flutter, browsers) so they can verify the server's identity.
- **Client CA** — signs client certs. Its `ca.crt` is loaded by nginx
  (`ssl_client_certificate`) so the server can verify clients.

The two CAs don't trust each other. Compromising the server CA
doesn't let an attacker mint client certs that nginx will accept;
compromising the client CA doesn't let them impersonate the server.

## Concrete setup

`gen-pki.sh` doesn't have a `--ca-name` flag, so the cleanest way is
to run it in two parallel directories:

```bash
mkdir -p pki-server pki-client

(cd pki-server && ../gen-pki.sh ca)
(cd pki-server && ../gen-pki.sh server vlearn2.example.com 172.86.121.43)

(cd pki-client && ../gen-pki.sh ca)
(cd pki-client && ../gen-pki.sh client flutter-app)
(cd pki-client && ../gen-pki.sh client admin-john)
(cd pki-client && ../gen-pki.sh client admin-mary)
(cd pki-client && ../gen-pki.sh client admin-bob)
```

Optional: edit the CA `[req_dn].CN` in `gen-pki.sh` to distinguish
the two ("vLearn2 server CA" / "vLearn2 client CA") so they're
self-documenting in cert subjects.

## Install on the host

```bash
# server identity
sudo install -m 644 pki-server/pki/server/vlearn2.example.com.crt /etc/pki/nginx/
sudo install -m 600 pki-server/pki/server/vlearn2.example.com.key /etc/pki/nginx/private/

# CA used to verify clients — different file, different CA
sudo install -m 644 pki-client/pki/ca/ca.crt                       /etc/pki/nginx/client-ca.crt
```

nginx delta:

```nginx
    ssl_certificate        /etc/pki/nginx/vlearn2.example.com.crt;
    ssl_certificate_key    /etc/pki/nginx/private/vlearn2.example.com.key;
    ssl_client_certificate /etc/pki/nginx/client-ca.crt;
    ssl_verify_client      on;
```

## Distribution

Two trust roots to manage:

| Artifact | Where it goes |
|---|---|
| `pki-server/pki/ca/ca.crt` | **clients** — Flutter asset, browser trust store. Validates the server cert. |
| `pki-client/pki/ca/ca.crt` | **nginx only** — `ssl_client_certificate`. Validates incoming clients. |
| `pki-server/pki/ca/ca.key` | offline backup, controlled by whoever owns "server identity." |
| `pki-client/pki/ca/ca.key` | offline backup, controlled by whoever owns "client identity." |

The `.p12` bundles already include the issuing CA in their certificate
chain, so admin browsers automatically pick up the client CA when they
import the `.p12` — no separate distribution needed for that.

Flutter Dio code is unchanged; just bundle `pki-server/pki/ca/ca.crt`
as the trusted root in `SecurityContext.setTrustedCertificatesBytes`.

## Trade-offs that surface

- **Two keys to lose.** Doubled the "did I back this up?" surface.
- **Subtle bug class:** mixing up which CA goes where. If you
  accidentally point `ssl_client_certificate` at the server CA, every
  client gets rejected with "unable to get local issuer certificate"
  during handshake.
- **Cert subjects look identical** unless you edit the CA CN before
  generating. Easy to confuse on inspection.
- **Two rotation schedules** if you want them separate. A real benefit
  if you're rotating client trust frequently (e.g. quarterly hygiene)
  but not the server cert.

## What "compromise" looks like

| Compromise | Recovery |
|---|---|
| `pki-client/ca/ca.key` stolen | Rebuild the client CA, re-issue every `.p12`, redistribute. Server cert and Flutter trust root unchanged — JWT still works for users mid-rebuild. |
| `pki-server/ca/ca.key` stolen | Rebuild server CA, re-issue server cert, redistribute `server-ca.crt` to clients (Flutter rebuild + browser trust store update). Client certs unchanged. |
| Both keys stolen | You're back to the full PKI rebuild Option A also requires. No worse, no better. |

The asymmetry is the win: a single compromise affects only half the
system.

## Migration from Option A baseline

1. Generate the second CA (as above).
2. Re-issue all client certs against the client CA: `(cd pki-client &&
   ../gen-pki.sh client <name>)` for each existing client.
3. Re-issue server cert against the server CA: `(cd pki-server &&
   ../gen-pki.sh server <host> <ip>)`.
4. Replace files in `/etc/pki/nginx/`. Reload nginx.
5. Rebuild Flutter app with the new `server-ca.crt` bundled.
6. Redistribute new `.p12` bundles to admins (they'll need to re-import,
   removing the old cert + CA from their browsers first).

Window of TLS downtime during the swap: ~seconds (nginx reload), but
existing client cert sessions break — admins have to re-import.

## Verdict

Right call when:
- Different humans / teams own server vs. client cert lifecycle.
- Audit requires distinct trust roots for distinct purposes.
- Client CA needs to rotate on a different cadence than server cert.

Overkill for vLearn2 today (one operator, small scale). Could become
worthwhile if you grow into a security-engineering function with
its own owner; revisit then.
